# Matched-workload probe, separate from the ten-fold accuracy benchmark.
source('scripts/paths.R')
method<-commandArgs(TRUE)[1];stopifnot(length(method)==1L)
root<-output_dir();rows<-list()
for(case in c('cattle','maize')) {
 fits<-lapply(c(1L,4L),function(workers) {
  path<-file.path(root,paste0('20261122-thread-probe-',workers,'t'),method,case)
  resource<-jsonlite::fromJSON(file.path(path,'process-resources.json'))
  stopifnot(resource$exit_code==0)
  fit<-readRDS(file.path(path,'fold1-fit.rds'))
  score<-read.csv(file.path(path,'fold-results.csv'))
  stopifnot(nrow(score)==1L,score$fold==1L,score$actual_workers==workers,
   fit$input$execution$nchains==4L,fit$input$execution$nit==200L,
   fit$input$execution$nburn==100L)
  list(fit=fit,score=score,resource=resource)
 })
 a<-fits[[1]];b<-fits[[2]]
 stopifnot(identical(a$fit$data,b$fit$data),identical(a$fit$input$prior,b$fit$input$prior),
  identical(a$fit$input$learning,b$fit$input$learning),
  identical(a$fit$input$execution$seeds,b$fit$input$execution$seeds),
  identical(a$fit$posterior$effects,b$fit$posterior$effects),
  identical(a$fit$draws$parameters,b$fit$draws$parameters))
 comparable<-identical(a$score$cache_status,b$score$cache_status)
 params<-a$fit$posterior$parameterSummary
 params<-params[params$estimated&is.finite(params$rhat)&is.finite(params$ess_bulk),,drop=FALSE]
 min_ess<-if(nrow(params))min(params$ess_bulk)else NA_real_
 max_rhat<-if(nrow(params))max(params$rhat)else NA_real_
 rows[[case]]<-data.frame(dataset=case,method,fold=1L,chains=4L,burnin=100L,postburn=200L,
  blas_threads=1L,one_worker_fit_seconds=a$score$fit_seconds,
  four_worker_fit_seconds=b$score$fit_seconds,
  one_worker_sampler_seconds=a$score$native_sampler_seconds,
  four_worker_sampler_seconds=b$score$native_sampler_seconds,
  minimum_parameter_bulk_ess=min_ess,maximum_parameter_rhat=max_rhat,
  one_worker_min_ess_per_fit_second=min_ess/a$score$fit_seconds,
  four_worker_min_ess_per_fit_second=min_ess/b$score$fit_seconds,
  fitting_speedup=if(comparable)a$score$fit_seconds/b$score$fit_seconds else NA_real_,
  sampler_speedup=if(comparable)a$score$native_sampler_seconds/b$score$native_sampler_seconds else NA_real_,
  one_worker_peak_mib=a$resource$peak_working_set_bytes/1024^2,
  four_worker_peak_mib=b$resource$peak_working_set_bytes/1024^2,
  one_worker_affinity_mask=a$resource$affinity_mask,four_worker_affinity_mask=b$resource$affinity_mask,
  identical_seeded_outputs=TRUE,comparable_cache_state=comparable,
  scope='Short fold-1 threading probe; not a convergence or accuracy comparison')
}
dest<-file.path(root,'20261122-thread-probe-summary');dir.create(dest,recursive=TRUE,showWarnings=FALSE)
write.csv(do.call(rbind,rows),file.path(dest,paste0(method,'.csv')),row.names=FALSE)
print(do.call(rbind,rows)[,c('dataset','method','fitting_speedup','sampler_speedup','identical_seeded_outputs')])
