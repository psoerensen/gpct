# Practical efficiency: more independent chains at unchanged length per chain.
source('scripts/paths.R')
method<-commandArgs(TRUE)[1];root<-output_dir();rows<-list()
for(case in c('cattle','maize')) {
 reference<-jsonlite::fromJSON(file.path(root,'20261122-chain-comparison-summary/references',paste0(method,'-',case,'.json')))
 stopifnot(reference$ready)
 paths<-c(reference$path,file.path(root,'20261122-gbayes-glist-4t',method,case))
 fits<-lapply(paths,function(path)readRDS(file.path(path,'fold1-fit.rds')))
 scores<-lapply(paths,function(path)read.csv(file.path(path,'fold-results.csv')))
 a<-fits[[1]];b<-fits[[2]]
 stopifnot(identical(a$data,b$data),identical(a$input$prior,b$input$prior),
  identical(a$input$learning,b$input$learning),
  a$input$execution$nchains==2L,b$input$execution$nchains==4L,
  a$input$execution$ncores==1L,b$input$execution$ncores==4L)
 for(key in c('nit','nburn','nthin'))stopifnot(identical(a$input$execution[[key]],b$input$execution[[key]]))
 first_two<-b$draws$parameters[,1:2,,drop=FALSE]
 stopifnot(isTRUE(all.equal(a$draws$parameters,first_two,tolerance=1e-12)))
 comparable_cache<-identical(a$diagnostics$genotypeCache$status,b$diagnostics$genotypeCache$status)&&
  identical(a$diagnostics$genotypeCache$allocated_bytes,b$diagnostics$genotypeCache$allocated_bytes)
 efficiency<-lapply(seq_along(fits),function(i) {
  p<-fits[[i]]$posterior$parameterSummary
  p<-p[p$estimated&is.finite(p$rhat)&is.finite(p$ess_bulk),,drop=FALSE]
  stopifnot(nrow(p)>0)
  data.frame(parameter=p$parameter,mean=p$mean,rhat=p$rhat,bulk_ess=p$ess_bulk,
   fit_seconds=scores[[i]]$fit_seconds[1],bulk_ess_per_fit_second=if(comparable_cache)p$ess_bulk/scores[[i]]$fit_seconds[1]else NA_real_,
   chains=if(i==1)2L else 4L,workers=if(i==1)1L else 4L)
 })
 z<-do.call(rbind,efficiency);z$dataset<-case;z$method<-method
 z$burnin_per_chain<-a$input$execution$nburn;z$postburn_per_chain<-a$input$execution$nit
 z$first_two_chain_trajectories_match<-TRUE
 z$binary_sha256<-reference$binary_sha256
 z$comparable_cache_state<-comparable_cache
 z$reference_run<-basename(dirname(dirname(reference$path)))
 z$diagnostic_caution<-ifelse(z$rhat>1.05|z$bulk_ess<100,'Weak mixing; ESS estimates are provisional','Parameter check passed; not an all-marker convergence claim')
 rows[[case]]<-z
}
dest<-file.path(root,'20261122-chain-comparison-summary');dir.create(dest,recursive=TRUE,showWarnings=FALSE)
write.csv(do.call(rbind,rows),file.path(dest,paste0(method,'.csv')),row.names=FALSE)
print(do.call(rbind,rows)[,c('dataset','method','parameter','chains','workers','rhat','bulk_ess','bulk_ess_per_fit_second')],row.names=FALSE)
