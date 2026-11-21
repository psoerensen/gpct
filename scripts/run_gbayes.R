# Orchestration only: existing gbayes native fitting and prediction APIs.
source('scripts/paths.R');source('scripts/evaluate.R');source('benchmarks/methods.R')
library(gbase);library(gbayes)
arguments<-commandArgs(TRUE)
stopifnot(length(arguments)==2L,arguments[1]%in%benchmark_methods$id,arguments[2]%in%c('cattle','maize'))
method_id<-arguments[1];case<-arguments[2]
stopifnot(all(Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))=='1'))
batch<-Sys.getenv('GPCT_RUN_ID','20261121-gbayes-glist-1t')
stopifnot(grepl('^[A-Za-z0-9_-]+$',batch))
root<-file.path(output_dir(),batch);destination<-file.path(root,method_id,case)
dir.create(destination,recursive=TRUE,showWarnings=FALSE)
write_status<-function(status,message='')write.csv(data.frame(status,message,timestamp_utc=format(Sys.time(),tz='UTC')),
 file.path(destination,'status.csv'),row.names=FALSE)
write_status('running')
checkpoint<-new.env(parent=emptyenv());checkpoint$fold<-NA_integer_
checkpoint$stage<-'input preparation';checkpoint$started<-proc.time()[['elapsed']]
run<-function() {
 panel_path<-file.path(data_dir(),'glist/20261121-maf001-miss005',case,'qc-Glist.rds')
 panel<-readRDS(panel_path);gbase::validate_Glist(panel)
 phenotype_path<-file.path(data_dir(),'glist/20261121-maf001-miss005',case,'phenotype-only.rds')
 if(!file.exists(phenotype_path)) {
  original<-readRDS(file.path(data_dir(),'prepared',paste0(case,'-gpbench.rds')))
  saveRDS(original[c('Y','ids','metadata')],phenotype_path);rm(original);gc()
 }
 input<-readRDS(phenotype_path)
 stopifnot(identical(input$ids,panel$ids),isTRUE(panel$provenance$synthetic_annotations))
 trait<-if(case=='cattle')'mkg'else'DTT'
 response<-gpbench_response(input$Y[,trait]);y<-response$y
 folds<-saved_folds(input$ids,file.path(data_dir(),'folds',paste0(case,'-gpbench-10fold-seed42.csv')))
 spec<-benchmark_methods[match(method_id,benchmark_methods$id),]
 write.csv(spec,file.path(destination,'method-settings.csv'),row.names=FALSE)
 saveRDS(list(case=case,trait=trait,method=spec,folds=folds,
  panel_md5=tools::md5sum(panel_path),source_pins=read.csv('environment/sources.csv'),
  scripts_md5=tools::md5sum(c('scripts/run_gbayes.R','benchmarks/methods.R','scripts/evaluate.R')),
  threads=Sys.getenv(c('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS'))),file.path(destination,'provenance.rds'))
 write.csv(data.frame(package=c('gbase','gbayes'),version=vapply(c('gbase','gbayes'),
  function(p)as.character(packageVersion(p)),character(1))),file.path(destination,'package-versions.csv'),row.names=FALSE)
 performance<-if(file.exists(file.path(destination,'fold-results.csv')))
  read.csv(file.path(destination,'fold-results.csv'),stringsAsFactors=FALSE) else NULL
 max_folds<-as.integer(Sys.getenv('GPCT_MAX_FOLDS','10'))
 for(fold in seq_len(max_folds)) {
  if(!is.null(performance)&&fold%in%performance$fold[performance$status=='completed'])next
  checkpoint$fold<-fold;checkpoint$stage<-'Glist preparation';checkpoint$started<-proc.time()[['elapsed']]
  train<-which(folds$fold!=fold);test<-which(folds$fold==fold)
  cache<-file.path(root,'glist-cache',case);dir.create(cache,recursive=TRUE,showWarnings=FALSE)
  cache_path<-file.path(cache,paste0('fold',fold,'.rds'));started<-proc.time()[['elapsed']]
  if(file.exists(cache_path)) {
   cached<-readRDS(cache_path);training<-cached$Glist;shared_preparation_seconds<-cached$seconds
  }else {
   training<-gbase::gprep(bedfiles=panel$bedfiles,ids=input$ids[train],nthreads=1L,companion=NULL)
   keep<-unlist(training$rsids,use.names=FALSE)[unlist(training$maf,use.names=FALSE)>0]
   if(length(keep)!=sum(lengths(training$rsids)))training<-gbase::gprep(
    bedfiles=panel$bedfiles,ids=input$ids[train],rsids=keep,nthreads=1L,companion=NULL)
   shared_preparation_seconds<-proc.time()[['elapsed']]-started
   saveRDS(list(Glist=training,seconds=shared_preparation_seconds),cache_path)
  }
  preparation_seconds<-proc.time()[['elapsed']]-started
  stopifnot(identical(training$ids[training$sample_source_indices_0based+1L],input$ids[train]),
   identical(training$bedfiles,panel$bedfiles))
  args<-gbayes_arguments(method_id,training,y[train],trait,fold)
  outcomes<-data.frame(id=input$ids[train],value=y[train]);names(outcomes)[2]<-trait;args$data<-outcomes
  saveRDS(args[setdiff(names(args),c('Glist','data'))],file.path(destination,paste0('fold',fold,'-settings.rds')))
  warnings<-character();cat('FIT',case,method_id,'fold',fold,'one worker\n');flush.console()
  started<-proc.time()[['elapsed']]
  checkpoint$stage<-'native fitting';checkpoint$started<-started
  fit<-withCallingHandlers(do.call(gbayes::bayes,args),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
  fit_seconds<-proc.time()[['elapsed']]-started;diagnostic<-gbayes::diagnostics(fit)
  saveRDS(diagnostic,file.path(destination,paste0('fold',fold,'-diagnostics.rds')))
  saveRDS(fit,file.path(destination,paste0('fold',fold,'-fit.rds')))
  workers<-diagnostic$execution$actualWorkers
  if(is.null(workers)&&spec$algorithm=='mcmc') {
   # Scalar MCMC does not return the team counter through the R result.
   # Its native control is a positive upper bound on concurrent chains.
   stopifnot(fit$input$nativeControl$threads==1L,fit$input$execution$ncores==1L)
   workers<-1L
  }
  stopifnot(length(workers)==1L,workers==1L,fit$input$method==spec$method,
   fit$input$algorithm==spec$algorithm,identical(fit$data$samples,input$ids[train]))
  convergence<-diagnostic$convergence$status
  if(length(convergence)!=1L)convergence<-'not reported'
  if(!spec$algorithm%in%'mcmc' && convergence!='converged')stop('Native fit did not converge: ',convergence)
  started<-proc.time()[['elapsed']]
  checkpoint$stage<-'held-out prediction';checkpoint$started<-started
  predicted<-predict(fit,newdata=list(Glist=panel,ids=input$ids[test]),type='phenotype')
  prediction_seconds<-proc.time()[['elapsed']]-started
  stopifnot(identical(rownames(predicted),input$ids[test]),ncol(predicted)==1L)
  predicted<-as.numeric(predicted[,1]);measured<-metrics(y[test],predicted)
  row<-data.frame(dataset=paste0('gpbench_',case),trait,method=method_id,fold,
   n_train=length(train),n_test=length(test),available_markers=if(case=='cattle')42551L else 75304L,
   markers_used=length(fit$data$markers),status='completed',convergence,
   actual_workers=workers,preparation_seconds,shared_preparation_seconds,
   fit_seconds,prediction_seconds,elapsed_seconds=preparation_seconds+fit_seconds+prediction_seconds,
   warning_count=length(warnings),warnings=paste(warnings,collapse=' | '),as.list(measured))
  performance<-rbind(performance,row)
  write.csv(performance,file.path(destination,'fold-results.csv'),row.names=FALSE)
  write.csv(data.frame(id=input$ids[test],fold,observed=y[test],predicted,
   imputed=response$imputed[test],training_mean=mean(y[train])),
   file.path(destination,paste0('fold',fold,'-predictions-local.csv')),row.names=FALSE)
  cat('DONE',case,method_id,'fold',fold,'fit seconds',round(fit_seconds,3),
   'correlation',round(measured[['predictive_ability']],4),'\n');flush.console()
  rm(fit,args);gc()
 }
 if(nrow(performance)==10L && !anyDuplicated(performance$fold))write_status('completed')else write_status('partial','First-fold check; ten-fold run pending.')
}
tryCatch(run(),error=function(e){
 write.csv(data.frame(dataset=case,method=method_id,fold=checkpoint$fold,stage=checkpoint$stage,
  elapsed_seconds=proc.time()[['elapsed']]-checkpoint$started,message=conditionMessage(e)),
  file.path(destination,'failed-attempt.csv'),row.names=FALSE)
 write_status('failed',conditionMessage(e));stop(e)
})
