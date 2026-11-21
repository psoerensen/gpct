# Aggregate-only reporting for the GPBench-matched ten-fold benchmarks.
source('scripts/evaluate.R')
source('scripts/plot_prediction.R')
report_metrics <- c('predictive_ability','rmse','mae','mse','predictive_r_squared','calibration_intercept','calibration_slope')
report_labels <- c(gblup_reml='Genomic BLUP')
report_colors <- c(gblup_reml='#168575')
software_source_table <- function(sources) {
  sources<-unique(sources)
  markdown_table(data.frame(Software=sources$repository,Version=sources$version,
    Private_source_commit=paste0('[',substr(sources$revision,1,12),'](',
      sub('[.]git$','',sources$url),'/tree/',sources$revision,')')))
}

calibration_bins <- function(p,dataset,trait,method) {
  breaks <- unique(as.numeric(quantile(p$predicted,seq(0,1,length.out=11))))
  groups <- if(length(breaks)<2L) rep(1L,nrow(p)) else cut(p$predicted,breaks,include.lowest=TRUE,labels=FALSE)
  do.call(rbind,lapply(sort(unique(groups)),function(bin){
    q <- p[groups==bin,,drop=FALSE]
    if(nrow(q)<5L) return(NULL)
    data.frame(dataset,trait,method,bin,n=nrow(q),mean_prediction=mean(q$predicted),mean_observed=mean(q$observed))
  }))
}
summarize_prediction_run <- function(run_dir) {
  config <- readRDS(file.path(run_dir,'settings.rds'))
  folds <- readRDS(file.path(run_dir,'folds.rds'))
  perf <- read.csv(file.path(run_dir,'performance.csv'))
  p <- read.csv(file.path(run_dir,'predictions.csv'))
  versions <- read.csv(file.path(run_dir,'package_versions.csv'))
  provenance <- readRDS(file.path(run_dir,'provenance.rds'))
  execution <- read.csv(file.path(run_dir,'execution.csv'))
  stopifnot(config$folds==10L,config$fold_seed==42L,config$marker_count==config$p,
    nrow(folds)==config$n,identical(sort(unique(folds$fold)),1:10),!anyDuplicated(folds$id),
    all(perf$method%in%config$methods),all(p$method%in%config$methods),
    !anyDuplicated(paste(perf$method,perf$fold)),!anyDuplicated(paste(p$method,p$id)),
    all(p$fold==folds$fold[match(p$id,folds$id)]),
    all(is.finite(p$observed)),all(is.finite(p$predicted)),all(is.finite(p$training_mean)))
  for(id in unique(p$id)) stopifnot(length(unique(p$observed[p$id==id]))==1L,
    length(unique(p$phenotype_was_imputed[p$id==id]))==1L)
  perf$dataset <- config$dataset_id; perf$trait <- config$trait
  perf$mean_predictor_rmse <- perf$relative_rmse_reduction <- NA_real_
  for(i in seq_len(nrow(perf))) {
    q <- p[p$method==perf$method[i]&p$fold==perf$fold[i],]
    if(perf$status[i]=='completed') {
      stopifnot(setequal(q$id,folds$id[folds$fold==perf$fold[i]]))
      perf[i,report_metrics] <- as.list(metrics(q$observed,q$predicted))
      stopifnot(length(unique(q$training_mean))==1L)
      perf$mean_predictor_rmse[i] <- sqrt(mean((q$observed-q$training_mean)^2))
      perf$relative_rmse_reduction[i] <- 1-perf$rmse[i]/perf$mean_predictor_rmse[i]
    } else perf[i,report_metrics] <- NA_real_
  }
  summaries <- pooled <- observed <- bins <- list()
  for(method in config$methods) {
    a <- perf[perf$method==method,]; q <- p[p$method==method,]
    full <- nrow(a)==10L&&all(a$status=='completed')&&setequal(q$id,folds$id)
    row <- data.frame(dataset=config$dataset_id,trait=config$trait,method,
      summary_type='mean_of_10_fold_metrics',predictive_ability=NA_real_,rmse=NA_real_,mae=NA_real_,mse=NA_real_,
      predictive_r_squared=NA_real_,calibration_intercept=NA_real_,calibration_slope=NA_real_,
      predictive_ability_fold_sd=NA_real_,fit_seconds=NA_real_,prediction_seconds=NA_real_,
      method_elapsed_seconds=NA_real_,kernel_seconds=execution$shared_kernel_seconds,
      workflow_seconds=NA_real_,case_elapsed_seconds=execution$case_elapsed_seconds,
      peak_ram_mb=NA_real_,ram_status='not measured',available_markers=config$p,
      markers_used_min=min(a$markers),markers_used_max=max(a$markers),
      completed_folds=sum(a$status=='completed'),failed_folds=sum(a$status=='failed'),
      warning_count=sum(a$warning_count),convergence=paste(unique(a$convergence),collapse='; '),
      status=if(full) 'completed' else 'incomplete',mean_predictor_rmse=NA_real_,relative_rmse_reduction=NA_real_,
      recipe_url=paste0('https://github.com/psoerensen/gpct/tree/main/benchmarks/',config$case,'_prediction'),
      report_url=paste0('https://psoerensen.github.io/gpct/reports/',config$case,'.html'))
    if(full) {
      stopifnot(sum(q$phenotype_was_imputed)==provenance$response_imputed_n)
      row[report_metrics] <- as.list(colMeans(a[,report_metrics]))
      row$predictive_ability_fold_sd <- sd(a$predictive_ability)*sqrt(9/10) # numpy.std(ddof=0), descriptive
      row$mean_predictor_rmse <- mean(a$mean_predictor_rmse)
      row$relative_rmse_reduction <- mean(a$relative_rmse_reduction)
      for(field in c('fit_seconds','prediction_seconds','method_elapsed_seconds')) row[[field]] <- sum(a[[field]])
      row$workflow_seconds <- row$kernel_seconds+row$fit_seconds+row$prediction_seconds
      pooled[[method]] <- data.frame(dataset=config$dataset_id,trait=config$trait,method,
        summary_type='pooled_oof',as.list(metrics(q$observed,q$predicted)))
      observed_folds <- lapply(1:10,function(k){r<-q[q$fold==k&!q$phenotype_was_imputed,];metrics(r$observed,r$predicted)})
      observed[[method]] <- data.frame(dataset=config$dataset_id,trait=config$trait,method,
        summary_type='mean_of_10_fold_metrics_observed_targets_only',n=sum(!q$phenotype_was_imputed),
        as.list(rowMeans(do.call(cbind,observed_folds))))
      bins[[method]] <- calibration_bins(q,config$dataset_id,config$trait,method)
    }
    summaries[[method]] <- row
  }
  summary <- do.call(rbind,summaries)
  registry <- read.csv('datasets/registry.csv'); d <- registry[registry$dataset_id==config$dataset_id,]
  settings <- data.frame(dataset=config$dataset_id,trait=config$trait,method=config$methods,
    package='gsuite',package_version=versions$version[match('gsuite',versions$package)],
    native_engines='greml 0.92.0; gsolve 0.28.0',
    model='Raw-marker Gaussian ridge model with intercept; variances estimated by REML',
    computation='greml component REML; gsolve CHOLMOD/MKL and exact selected inversion; K=ZZt/p; certified input metadata',
    tuning='No test-fold tuning',convergence=paste('Score tolerance',config$tolerance,
      '; hybrid EM-AI; requested direct threads 4; returned backend settings in fold CSV; cap 100'))
  metadata <- data.frame(dataset=config$dataset_id,trait=config$trait,run_id=basename(run_dir),
    gpbench_revision=config$gpbench_revision,source_revision=provenance$source$source_revision,
    prepared_input_md5=provenance$input_md5,fold_seed=42L,folds=10L,score_tolerance=config$tolerance,
    validation='sklearn 1.6.1 KFold(10,shuffle=True,random_state=42); NumPy 1.26.4',
    phenotype_imputation='whole-dataset mean before splitting, matching GPBench; imputed targets flagged',
    imputed_targets=provenance$response_imputed_n,
    execution[,setdiff(names(execution),c('case_elapsed_seconds','shared_kernel_seconds','peak_ram_mb','ram_status')),drop=FALSE])
  aggregate_bins <- do.call(rbind,bins)
  if(is.null(aggregate_bins)) aggregate_bins <- data.frame(dataset=character(),trait=character(),
    method=character(),bin=integer(),n=integer(),mean_prediction=double(),mean_observed=double())
  solver_checks <- read.csv(file.path(run_dir,'solver_checks.csv'))
  solver_checks$message <- NULL
  source_pins<-read.csv('environment/sources.csv',stringsAsFactors=FALSE)
  source_pins<-source_pins[match(c('gsuite','greml','gsolve'),source_pins$repository),]
  source_pins$version<-c('0.43.0','0.92.0','0.28.0')
  source_pins$access<-'Private implementation repository; authorized access required'
  tables<-list(dataset_catalogue=data.frame(dataset=config$dataset_id,species=d$species,trait=config$trait,
      phenotype_definition=d$preprocessing_history,individuals_available=config$n,individuals_evaluated=nrow(folds),
      observed_targets=config$n-provenance$response_imputed_n,imputed_targets=provenance$response_imputed_n,
      available_markers=config$p,markers_used=config$p,source=d$source_url),
    method_settings=settings,software_sources=source_pins,benchmark_results=summary,fold_results=perf[,setdiff(names(perf),'message')],
    pooled_results=do.call(rbind,pooled),observed_only_metrics=do.call(rbind,observed),
    calibration_bins=aggregate_bins,run_metadata=metadata,
    solver_checks=transform(solver_checks,dataset=config$dataset_id,trait=config$trait),
    recipe_checksums=data.frame(dataset=config$dataset_id,source_file=names(provenance$scripts_md5),
      md5=unname(provenance$scripts_md5),canonical_lf_sha256=vapply(names(provenance$scripts_md5),function(path) {
        if(!file.exists(path)) return(NA_character_)
        stopifnot(unname(tools::md5sum(path))==unname(provenance$scripts_md5[[path]]))
        contents<-readChar(path,file.info(path)$size,useBytes=TRUE)
        digest::digest(gsub('\r\n','\n',contents,fixed=TRUE),algo='sha256',serialize=FALSE)
      },character(1))))
  if(file.exists(file.path(run_dir,'sessionInfo.txt')))
    attr(tables,'fit_session')<-readLines(file.path(run_dir,'sessionInfo.txt'))
  tables
}
write_prediction_report <- function(tables,directory) {
  if(dir.exists(directory)) stop('Report destination exists')
  dir.create(directory,recursive=TRUE)
  for(name in names(tables)) write.csv(tables[[name]],file.path(directory,paste0(name,'.csv')),row.names=FALSE,na='NA')
  if(!is.null(attr(tables,'fit_session')))
    writeLines(sub('[[:space:]]+$','',attr(tables,'fit_session')),file.path(directory,'fit-sessionInfo.txt'))
  plot_prediction_report(tables,directory)
  page <- c('---','layout: default','title: GPBench-matched benchmark','---','# GPBench-matched benchmark','',
    '## Scientific question and dataset','',
    'Predict supplied phenotypes using all source markers and the published GPBench ten-fold split algorithm. Original IDs, upstream processing and phenotype units remain unverified.','',
    markdown_table(tables$dataset_catalogue[,c('dataset','species','trait','individuals_evaluated','observed_targets','imputed_targets','available_markers','markers_used')]),'','[Full dataset catalogue and source definitions](dataset_catalogue.csv)','',
    '## Methods and validation','',
    'Shuffled ten-fold KFold, seed 42, scikit-learn 1.6.1 and NumPy 1.26.4. Raw supplied dosage coding; no marker filtering or SD scaling. The benchmarked model estimates variance components by REML through our greml/gsolve implementation. greml uses the equivalent covariance K=ZZt/p. Implementations remain installed privately; no private source or binaries are distributed.','',
    'To reproduce GPBench, missing phenotypes are mean-imputed before splitting. Two maize DTT targets are imputed; cattle has none. Imputed labels are not genuinely observed phenotypes. The observed-target-only sensitivity summary excludes them from evaluation. This reproduction does not endorse whole-dataset phenotype imputation for a new scientific study.','',
    markdown_table(tables$method_settings[,c('method','package','package_version','native_engines','tuning','convergence')]),'','[Full model and method settings](method_settings.csv)','',
    'Fitting calls gsuite::gs_lmm_fit through our R interface to the compiled greml/gsolve libraries. Exact implementation revisions are pinned below; these repositories are private.','',
    software_source_table(tables$software_sources),'','[Software and source commits](software_sources.csv)','',
    '## Results','',
    'Main scores are arithmetic means of ten test-fold metrics, matching GPBench. Predictive R2 uses each test fold mean as its reference. Descriptive fold standard deviations use NumPy ddof=0; no confidence intervals or independent fold replicates are implied. Pooled OOF metrics are separate.','',
    markdown_table(tables$benchmark_results[,c('dataset','trait','method','predictive_ability','rmse','predictive_r_squared','calibration_slope','fit_seconds','prediction_seconds','kernel_seconds','workflow_seconds','status')]),'',
    '[Results CSV](benchmark_results.csv) · [Fold values](fold_results.csv) · [Pooled OOF](pooled_results.csv) · [Observed targets only](observed_only_metrics.csv)','',
    '## Performance and computational cost','')
  for(kind in c('performance','improvement','runtime')) page <- c(page,
    paste0('<figure class="report-figure"><img src="',kind,'.svg" alt="',kind,' comparison within each dataset and trait, using the matched ten-fold validation."></figure>'),'',
    paste0('[Full-size ',kind,' SVG](',kind,'.svg)'), '')
  page <- c(page,
    'Workflow seconds include ten fits, ten predictions and construction of the reusable raw-dosage kernel, including fold block preparation. Shared kernel construction is data-only and uses no held-out responses. Zero recorded seconds means below the elapsed timer resolution. These are single-execution measurements on our hardware. Peak RAM is not measured.','',
    'R/OpenBLAS and the MKL environment request four threads. The component backend returns requested/resolved/support settings of one in this build; those returned values are retained in the fold CSV. These settings do not measure CPU utilization. The separate fixed-variance solver check requests one supported worker.','',
    '## Calibration, convergence and solver checks','',
    '<figure class="report-figure"><img src="calibration.svg" alt="Aggregate OOF calibration bins with identity line, separately for each dataset and trait."></figure>','',
    '[Full-size calibration SVG](calibration.svg) · [Aggregate bins](calibration_bins.csv)','',
    markdown_table(tables$fold_results[,c('dataset','method','fold','status','convergence','warning_count')]),'',
    'The following fixed-variance gsolve check uses the variance estimates from our greml fit on representative folds: cattle folds 1 and 9 (including the previously problematic fold), maize fold 1. It checks prediction equivalence; its solve time excludes REML and is not another complete-method timing.','',
    markdown_table(tables$solver_checks),'','[Solver checks CSV](solver_checks.csv)','',
    '## Reproduce','',
    'Build and activate the pinned environment using environment/README.md in the repository. Set external GPCT_DATA_DIR and GPCT_OUTPUT_DIR; acknowledge positional alignment. Then run scripts/prepare.R CASE, benchmarks/CASE_prediction/run.R, scripts/check_solvers.R RUN_DIRECTORY and scripts/report_prediction.R RUN_DIRECTORY.','',
    '[Run metadata](run_metadata.csv) · [Recipe checksums](recipe_checksums.csv) · [Reporting session](report-sessionInfo.txt)','',
    'Individual predictions, fold assignments, saved fits, raw diagnostics, private implementation source and binaries stay outside the public repository.')
  if('earlier_attempts'%in%names(tables)&&nrow(tables$earlier_attempts)) {
    failures<-tables$earlier_attempts[tables$earlier_attempts$status=='failed',]
    note<-c('## Earlier attempt and convergence sensitivity','',
      'An earlier cattle run at score tolerance 1e-6 completed nine folds but failed the likelihood-step acceptance check in fold nine. The current benchmark reruns every fold at the common tolerance 1e-4. Earlier costs are disclosed separately and excluded from current-run timings; predictions are compared with the successful stricter fits.','',
      markdown_table(failures),'','[Earlier statuses and costs](earlier_attempts.csv) · [Prediction sensitivity](tolerance_comparison.csv)','')
    position<-match('## Reproduce',page)-1L
    page<-append(page,note,after=position)
  }
  if(!is.null(attr(tables,'fit_session')))
    page<-c(page,'','[R packages loaded during fitting](fit-sessionInfo.txt)')
  writeLines(page,file.path(directory,'report.md'))
  writeLines(sub('[[:space:]]+$','',capture.output(sessionInfo())),file.path(directory,'report-sessionInfo.txt'))
}
if(sys.nframe()==0L) {
  args <- commandArgs(trailingOnly=TRUE);stopifnot(length(args)%in%c(1L,2L))
  source('scripts/paths.R');run_dir <- normalizePath(args[1],winslash='/',mustWork=TRUE)
  destination <- if(length(args)==2L) args[2] else file.path(run_dir,'report')
  root <- tolower(normalizePath('.',winslash='/'))
  target <- tolower(normalizePath(destination,winslash='/',mustWork=FALSE))
  if(target==root||startsWith(target,paste0(root,'/'))) stop('Generate measured reports externally, then review before publication.')
  write_prediction_report(summarize_prediction_run(run_dir),destination)
  cat('Report written to',destination,'\n')
}
