# Repeat fold one after the benchmark, tracing the Rcpp .Call boundary.
# Does not alter numerical code or contribute to the benchmark timing totals.
source('scripts/paths.R');source('scripts/fit_glma.R')
library(gbase);library(glma)
trace('cpp_glma_prediction_full',where=asNamespace('glma'),print=FALSE,
  tracer=quote(assign('.gpct_native_call_start',proc.time()[['elapsed']],envir=.GlobalEnv)),
  exit=quote(assign('.gpct_native_call_elapsed',
    proc.time()[['elapsed']]-get('.gpct_native_call_start',envir=.GlobalEnv),envir=.GlobalEnv)))
rows<-list()
for(case in c('cattle','maize')) {
  run<-file.path(output_dir(),case,'20261121-glma-mkl')
  stopifnot(read.csv(file.path(run,'run_status.csv'))$status=='completed')
  folds<-readRDS(file.path(run,'folds.rds'))
  baseline<-read.csv(file.path(output_dir(),case,'20261121-gsuite-final','predictions.csv'))
  y<-baseline$observed[match(folds$id,baseline$id)]
  train<-which(folds$fold!=1L)
  p<-if(case=='cattle')42551L else 75304L
  for(method in c('glma_infinitesimal','glma_prior_selected')) {
    elapsed<-system.time(fit<-fit_glma(y[train],file.path(run,'anonymous-dosages.bed'),
      nrow(folds),p,train,method,threads=4L))[['elapsed']]
    native_call<-get('.gpct_native_call_elapsed',envir=.GlobalEnv)
    original<-readRDS(file.path(run,paste0(method,'-fold1-diagnostics.rds')))
    stopifnot(identical(original$selected_prior,fit$selected_prior),
      isTRUE(all.equal(original$genetic_variance,fit$genetic_variance,tolerance=1e-6)),
      isTRUE(all.equal(original$residual_variance,fit$residual_variance,tolerance=1e-6)))
    rows[[paste(case,method)]]<-data.frame(dataset=paste0('gpbench_',case),method,
      fold=1L,scope='Separate repeat; Rcpp boundary tracing; excluded from benchmark totals',
      r_fit_call_seconds=elapsed,native_call_seconds=native_call,
      native_inner_fit_seconds=fit$native_seconds,
      outside_native_call_seconds=round(elapsed-native_call,3),
      native_preparation_and_conversion_seconds=native_call-fit$native_seconds)
  }
}
untrace('cpp_glma_prediction_full',where=asNamespace('glma'))
out<-file.path(Sys.getenv('GPCT_ENV_DIR'),'qualification/glma-mkl/interface-cost.csv')
write.csv(do.call(rbind,rows),out,row.names=FALSE)
print(do.call(rbind,rows),row.names=FALSE)
