source('scripts/report_prediction.R')
root <- tempfile('gpct-report-test-');dir.create(root)
e <- new.env();sys.source('benchmarks/cattle_prediction/config.R',e);config <- e$config;config$n<-60L
saveRDS(config,file.path(root,'settings.rds'))
folds <- data.frame(id=paste0('synthetic-',1:60),source_row=1:60,fold=rep(1:10,each=6))
saveRDS(folds,file.path(root,'folds.rds'))
p <- do.call(rbind,lapply(config$methods,function(method) data.frame(id=folds$id,fold=folds$fold,method,
  observed=seq_len(60)/10,predicted=seq_len(60)/10*.8+rep(1:10,each=6)/20,
  phenotype_was_imputed=FALSE,
  training_mean=vapply(folds$fold,function(k)mean((seq_len(60)/10)[folds$fold!=k]),numeric(1)))))
write.csv(p,file.path(root,'predictions.csv'),row.names=FALSE)
perf <- expand.grid(method=config$methods,fold=1:10,stringsAsFactors=FALSE)
perf$markers<-config$p;perf$status<-'completed';perf$convergence<-'converged';perf$warning_count<-0L
perf$fit_seconds<-1;perf$prediction_seconds<-.1;perf$method_elapsed_seconds<-1.2
for(field in report_metrics) perf[[field]]<-NA_real_
write.csv(perf,file.path(root,'performance.csv'),row.names=FALSE)
write.csv(data.frame(package='gsuite',version='0.43.0'),
  file.path(root,'package_versions.csv'),row.names=FALSE)
saveRDS(list(source=list(source_revision='synthetic'),input_md5='synthetic',response_imputed_n=0L,
  scripts_md5=c('synthetic.R'='synthetic')),file.path(root,'provenance.rds'))
write.csv(data.frame(case_elapsed_seconds=30,shared_kernel_seconds=2,blas_implementation='synthetic'),
  file.path(root,'execution.csv'),row.names=FALSE)
write.csv(data.frame(fold=1:10,status='converged',max_prediction_difference=0,
  prediction_correlation=1,elapsed_seconds=.1),file.path(root,'solver_checks.csv'),row.names=FALSE)
t <- summarize_prediction_run(root)
stopifnot(all(t$benchmark_results$completed_folds==10L),
  all(abs(t$benchmark_results$predictive_ability-1)<1e-12),
  abs(t$pooled_results$predictive_r_squared[1]-t$benchmark_results$predictive_r_squared[1])>1e-3,
  all(t$benchmark_results$workflow_seconds==13),all(t$benchmark_results$relative_rmse_reduction>0))
write_prediction_report(t,file.path(root,'report'))
stopifnot(!any(grepl('predictions|folds[.]',list.files(file.path(root,'report')))))
perf$status[perf$method=='gblup_reml'&perf$fold==10]<-'failed'
write.csv(perf,file.path(root,'performance.csv'),row.names=FALSE)
failed <- summarize_prediction_run(root)$benchmark_results
stopifnot(failed$status[1]=='incomplete',is.na(failed$predictive_ability[1]))
p$id[2]<-p$id[1];write.csv(p,file.path(root,'predictions.csv'),row.names=FALSE)
stopifnot(inherits(try(summarize_prediction_run(root),silent=TRUE),'try-error'))
unlink(root,recursive=TRUE)
cat('Ten-fold summaries, pooled distinction, workflow costs, failures and identity checks passed; synthetic outputs removed.\n')
