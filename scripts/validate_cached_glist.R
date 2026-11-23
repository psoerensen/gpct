# Compare the original installation and the local cache variant in separate R processes.
args <- commandArgs(TRUE);stopifnot(length(args)==1L)
mode <- args[[1]];stopifnot(mode %in% c('reference','candidate','compare','normal'))
env_root <- Sys.getenv('GPCT_ENV_DIR');stopifnot(nzchar(env_root))
directory <- file.path(env_root,'qualification/cache-integration/validation')
dir.create(directory,recursive=TRUE,showWarnings=FALSE)
if(mode=='candidate') .libPaths(c(file.path(env_root,'cache-library'),.libPaths()))
if(mode=='reference') .libPaths(.libPaths()[normalizePath(.libPaths(),mustWork=FALSE)!=
  normalizePath(file.path(env_root,'cache-library'),mustWork=FALSE)])
if(mode=='reference' && dir.exists(file.path(env_root,'reference-library/gbayes')))
  .libPaths(c(file.path(env_root,'reference-library'),.libPaths()))
if(mode=='normal') .libPaths(c(file.path(env_root,'library'),.libPaths()))
library(gbase);library(gbayes)
if(mode=='candidate') stopifnot(normalizePath(find.package('gbayes'))==
  normalizePath(file.path(env_root,'cache-library/gbayes')))
if(mode=='normal') stopifnot(normalizePath(find.package('gbayes'))==
  normalizePath(file.path(env_root,'library/gbayes')))
if(mode=='compare') {
  rows <- list()
  for(method in c('bayesC','bayesR')) {
    reference <- readRDS(file.path(directory,paste0('reference-',method,'.rds')))
    variants <- c('disabled','fallback','enabled','default')
    if(file.exists(file.path(directory,paste0('normal-default-',method,'.rds'))))variants<-c(variants,'normal-default')
    for(variant in variants) {
      candidate <- readRDS(file.path(directory,paste0(variant,'-',method,'.rds')))
      for(field in c('prior','initialization','learning'))
        stopifnot(identical(reference$fit$input[[field]],candidate$fit$input[[field]]))
      for(field in c('samples','markers','coding'))
        stopifnot(identical(reference$fit$data[[field]],candidate$fit$data[[field]]))
      a <- reference$fit;b <- candidate$fit
      effect_error <- max(abs(a$posterior$effects-b$posterior$effects))
      trace_error <- max(abs(a$draws$parameters-b$draws$parameters))
      prediction_error <- max(abs(reference$prediction-candidate$prediction))
      if(!variant%in%c('enabled','default','normal-default')) stopifnot(effect_error==0,trace_error==0,prediction_error==0)
      else stopifnot(effect_error<1e-8,trace_error<1e-7,prediction_error<1e-8)
      if(variant%in%c('default','normal-default')) {
        explicit <- readRDS(file.path(directory,paste0('enabled-',method,'.rds')))
        stopifnot(identical(b$posterior$effects,explicit$fit$posterior$effects),
          identical(b$draws$parameters,explicit$fit$draws$parameters))
      }
      cache <- b$diagnostics$genotypeCache
      stopifnot(cache$status==switch(variant,disabled='disabled',fallback='budget_exceeded',enabled='enabled',default='enabled','normal-default'='enabled'))
      stopifnot(cache$allocated_bytes==if(variant%in%c('enabled','default','normal-default'))
        length(b$data$samples)*length(b$data$markers)*8 else 0)
      stopifnot(identical(a$final$states[[1]]$marker_order,b$final$states[[1]]$marker_order))
      rows[[length(rows)+1L]] <- data.frame(method,variant,effect_error,trace_error,prediction_error,
        cache_status=cache$status,allocated_bytes=cache$allocated_bytes)
    }
  }
  write.csv(do.call(rbind,rows),file.path(directory,'validation-summary.csv'),row.names=FALSE)
  print(do.call(rbind,rows),row.names=FALSE)
  quit(status=0)
}
fixture_path <- file.path(directory,'fixture.rds')
if(!file.exists(fixture_path)) {
  n <- 19L;p <- 9L
  genotype <- matrix(rep(0:2,length.out=n*p),n,p)
  genotype[cbind(c(2,7,18),c(2,4,8))] <- NA
  files <- character()
  for(chromosome in 1:2) {
    markers <- if(chromosome==1) 1:5 else 6:9
    prefix <- file.path(directory,paste0('fixture',chromosome))
    bytes <- as.raw(c(108,27,1))
    for(j in markers) for(first in seq(1,n,by=4)) {
      index <- first:min(first+3,n)
      code <- c(3L,2L,0L)[genotype[index,j]+1L];code[is.na(code)] <- 1L
      bytes <- c(bytes,as.raw(sum(code*4^(seq_along(code)-1L))))
    }
    writeBin(bytes,paste0(prefix,'.bed'))
    write.table(data.frame(chromosome,paste0('m',markers),0,markers,'A','C'),
      paste0(prefix,'.bim'),row.names=FALSE,col.names=FALSE,quote=FALSE)
    write.table(data.frame('fixture',sprintf('s%03d',1:n),0,0,0,-9),
      paste0(prefix,'.fam'),row.names=FALSE,col.names=FALSE,quote=FALSE)
    files <- c(files,paste0(prefix,'.bed'))
  }
  panel <- gbase::gprep(bedfiles=files,nthreads=1L,companion=NULL)
  rows <- c(19,1,17,3,15,5,13,7,11,9,2,4,6,8,10,12,18)
  ids <- panel$ids[rows]
  training <- gbase::gprep(bedfiles=files,ids=ids,
    rsids=paste0('m',c(5,2,1,4,3,9,6,8,7)),nthreads=1L,companion=NULL)
  saveRDS(list(panel=panel,training=training,ids=ids,test=setdiff(panel$ids,ids),
    data=data.frame(id=ids,y=sin(rows)+cos(rows*.31))),fixture_path)
}
fixture <- readRDS(fixture_path)
variants <- if(mode=='reference') 'reference' else if(mode=='normal') 'normal-default' else c('disabled','fallback','enabled','default')
for(method in c('bayesC','bayesR')) for(variant in variants) {
  settings <- list(Glist=fixture$training,data=fixture$data,trait='y',method=method,
    algorithm='mcmc',ncores=1L,nchains=2L,nburn=20L,nit=80L,nthin=1L,
    updateB=TRUE,updateE=TRUE,seed=42002L)
  settings$pi <- if(method=='bayesC') .3 else c(.6,.2,.1,.1)
  if(!variant%in%c('reference','default','normal-default')) settings$control <- list(decodedMemoryLimit=
    switch(variant,disabled=0,fallback=1,enabled=2*1024^3))
  fit <- do.call(gbayes::bayes,settings)
  prediction <- predict(fit,newdata=list(Glist=fixture$panel,ids=fixture$test),type='phenotype')
  saveRDS(list(fit=fit,prediction=prediction),file.path(directory,paste0(variant,'-',method,'.rds')))
}
cat('Finished Glist validation mode:',mode,'\n')
