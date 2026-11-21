# Aggregate-only reporting for the GPBench-matched ten-fold benchmarks.
source('scripts/evaluate.R')
source('scripts/plot_prediction.R')
report_metrics <- c('predictive_ability','rmse','mae','mse','predictive_r_squared','calibration_intercept','calibration_slope')
report_labels <- c(gblup_reml='Genomic BLUP',gbayes_gaussian='Gaussian VB',gbayes_mixture='Normal-mixture VB',
  glma_infinitesimal='GLMA Gaussian',glma_prior_selected='GLMA prior-selected')
report_colors <- c(gblup_reml='#168575',gbayes_gaussian='#3267b1',gbayes_mixture='#9863b5',
  glma_infinitesimal='#c7761b',glma_prior_selected='#b84365')
software_source_table <- function(sources) {
  sources<-unique(sources)
  table<-data.frame(Software=sources$repository,Version=sources$version,
    Private_source_commit=paste0('[',substr(sources$revision,1,12),'](',
      sub('[.]git$','',sources$url),'/tree/',sources$revision,')'))
  if('run_id'%in%names(sources)) table$Execution<-sources$run_id
  markdown_table(table)
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
  if(!'preparation_seconds'%in%names(perf))perf$preparation_seconds<-0
  perf$algorithm_iterations<-perf$prior_average_marker_variance<-perf$prior_inclusion_probability<-NA_real_
  perf$native_source_read_seconds<-NA_real_;perf$native_product_backend<-'not recorded'
  for(i in which(grepl('^gbayes_',perf$method))) {
    path<-file.path(run_dir,paste0(perf$method[i],'-fold',perf$fold[i],'-diagnostics.rds'))
    if(file.exists(path)) {
      details<-readRDS(path)
      perf$algorithm_iterations[i]<-details$diagnostics$execution$iterations
      perf$prior_average_marker_variance[i]<-details$prior$average_marker_variance
      perf$prior_inclusion_probability[i]<-details$prior$inclusion_probability
      perf$native_source_read_seconds[i]<-details$diagnostics$batchExecution$sourceReadSeconds
      perf$native_product_backend[i]<-details$diagnostics$batchExecution$productBackend
    }
  }
  for(i in which(grepl('^glma_',perf$method))) {
    path<-file.path(run_dir,paste0(perf$method[i],'-fold',perf$fold[i],'-diagnostics.rds'))
    if(file.exists(path)) {
      details<-readRDS(path)
      perf$algorithm_iterations[i]<-details$sweeps
      perf$native_product_backend[i]<-'decoded; MKL dense products'
    }
  }
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
    if(perf$status[i]%in%c('completed','provisional')) {
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
    full <- nrow(a)==10L&&all(a$status%in%c('completed','provisional'))&&setequal(q$id,folds$id)
    row <- data.frame(dataset=config$dataset_id,trait=config$trait,method,
      summary_type='mean_of_10_fold_metrics',predictive_ability=NA_real_,rmse=NA_real_,mae=NA_real_,mse=NA_real_,
      predictive_r_squared=NA_real_,calibration_intercept=NA_real_,calibration_slope=NA_real_,
      predictive_ability_fold_sd=NA_real_,fit_seconds=NA_real_,prediction_seconds=NA_real_,
      method_elapsed_seconds=NA_real_,preparation_seconds=NA_real_,
      kernel_seconds=if(method=='gblup_reml')execution$shared_kernel_seconds else 0,
      workflow_seconds=NA_real_,case_elapsed_seconds=execution$case_elapsed_seconds,
      peak_ram_mb=NA_real_,ram_status='not measured',available_markers=config$p,
      markers_used_min=min(a$markers),markers_used_max=max(a$markers),
      completed_folds=sum(a$status=='completed'),provisional_folds=sum(a$status=='provisional'),failed_folds=sum(a$status=='failed'),
      warning_count=sum(a$warning_count),convergence=paste(unique(a$convergence),collapse='; '),
      status=if(full)if(all(a$status=='completed'))'completed'else'provisional'else'incomplete',
      mean_predictor_rmse=NA_real_,relative_rmse_reduction=NA_real_,run_id=basename(run_dir),
      recipe_url=paste0('https://github.com/psoerensen/gpct/tree/main/benchmarks/',config$case,'_prediction'),
      report_url=paste0('https://psoerensen.github.io/gpct/reports/',config$case,'.html'))
    if(full) {
      stopifnot(sum(q$phenotype_was_imputed)==provenance$response_imputed_n)
      row[report_metrics] <- as.list(colMeans(a[,report_metrics]))
      row$predictive_ability_fold_sd <- sd(a$predictive_ability)*sqrt(9/10) # numpy.std(ddof=0), descriptive
      row$mean_predictor_rmse <- mean(a$mean_predictor_rmse)
      row$relative_rmse_reduction <- mean(a$relative_rmse_reduction)
      for(field in c('fit_seconds','prediction_seconds','method_elapsed_seconds','preparation_seconds')) row[[field]] <- sum(a[[field]])
      row$workflow_seconds <- row$kernel_seconds+row$preparation_seconds+row$fit_seconds+row$prediction_seconds
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
  for(i in seq_len(nrow(settings)))if(grepl('^gbayes_',settings$method[i])) {
    settings$package[i]<-'gbayes';settings$package_version[i]<-versions$version[match('gbayes',versions$package)]
    settings$native_engines[i]<-'gbayes native streamed variational prediction'
    settings$model[i]<-if(settings$method[i]=='gbayes_gaussian')'Gaussian marker effects; fixed prior and residual variance'else
      'Spike-and-normal mixture; fixed inclusion probability 0.1; fixed variances'
    settings$computation[i]<-'bayes(method=normal_mixture,algorithm=vbayes); raw dosage; native intercept projection; no global marker Gram'
    settings$tuning[i]<-'No tuning; training var(y) split h2=0.5; average effect variance=0.5*var(y)/sum(training marker variances); mixture nonzero variance divided by 0.1'
    settings$convergence[i]<-paste('Per-sample negative-ELBO stabilization; tolerance',config$gbayes$tolerance,
      '; sweep cap',config$gbayes$maximum_sweeps,'; chunk 128; local iterations 20; full refresh 8; one worker; managed 1 GiB; Gram cache 256 MiB')
  }
  for(i in which(grepl('^glma_',settings$method))) {
    settings$package[i]<-'glma'
    settings$package_version[i]<-versions$version[match('glma',versions$package)]
    settings$native_engines[i]<-'glma 0.1.2; gbayes; greml; gsolve MKL'
    settings$model[i]<-if(settings$method[i]=='glma_infinitesimal')
      'Gaussian full-marker joint prediction; empirical standardized marker effects' else
      'Ten ridge/elastic prior candidates; full-marker joint prediction'
    settings$computation[i]<-'Existing native joint full-panel fit; no LOCO exclusions or GWAS calibration; train-only empirical standardization; constant training markers excluded'
    settings$tuning[i]<-'Blocked RHE/MC heritability grid; inner 10% validation within each outer training fold; split seed 17092026; no outer test outcomes'
    settings$convergence[i]<-'Native approximate joint workflow acceptance; prediction stability and adaptive chunk retirement; default sweep cap 100; chunk 256; four coordinate/MKL threads; managed 1 GiB'
  }
  metadata <- data.frame(dataset=config$dataset_id,trait=config$trait,run_id=basename(run_dir),
    gpbench_revision=config$gpbench_revision,source_revision=provenance$source$source_revision,
    prepared_input_md5=provenance$input_md5,fold_seed=42L,folds=10L,score_tolerance=config$tolerance,
    selected_methods=paste(config$methods,collapse=';'),
    gbayes_elbo_tolerance=if(any(grepl('^gbayes_',config$methods)))config$gbayes$tolerance else NA_real_,
    validation='sklearn 1.6.1 KFold(10,shuffle=True,random_state=42); NumPy 1.26.4',
    phenotype_imputation='whole-dataset mean before splitting, matching GPBench; imputed targets flagged',
    imputed_targets=provenance$response_imputed_n,
    execution[,setdiff(names(execution),c('case_elapsed_seconds','shared_kernel_seconds','peak_ram_mb','ram_status')),drop=FALSE])
  aggregate_bins <- do.call(rbind,bins)
  if(is.null(aggregate_bins)) aggregate_bins <- data.frame(dataset=character(),trait=character(),
    method=character(),bin=integer(),n=integer(),mean_prediction=double(),mean_observed=double())
  solver_checks <- if(file.exists(file.path(run_dir,'solver_checks.csv')))read.csv(file.path(run_dir,'solver_checks.csv'))else
    data.frame(fold=integer(),status=character(),max_prediction_difference=double(),prediction_correlation=double(),elapsed_seconds=double())
  solver_checks$message <- NULL
  solver_checks$dataset<-rep(config$dataset_id,nrow(solver_checks))
  solver_checks$trait<-rep(config$trait,nrow(solver_checks))
  source_pins<-if(!is.null(provenance$source_pins))provenance$source_pins else read.csv('environment/sources.csv',stringsAsFactors=FALSE)
  owners<-c('gsuite','greml','gsolve','gbayes',if(any(grepl('^glma_',config$methods)))c('glma','gbits','gmat'))
  source_pins<-source_pins[match(owners,source_pins$repository),]
  source_pins$version<-c('0.43.0','0.92.0','0.28.0',
    if(any(grepl('^glma_',config$methods))&&!any(grepl('^gbayes_',config$methods)))'0.1.0 (native core)'else'0.1.16 (R package)',
    if('glma'%in%owners)c('0.1.2','0.21.0','0.7.0'))
  source_pins$access<-'Private implementation repository; authorized access required'
  tables<-list(dataset_catalogue=data.frame(dataset=config$dataset_id,species=d$species,trait=config$trait,
      phenotype_definition=d$preprocessing_history,individuals_available=config$n,individuals_evaluated=nrow(folds),
      observed_targets=config$n-provenance$response_imputed_n,imputed_targets=provenance$response_imputed_n,
      available_markers=config$p,markers_used=config$p,source=d$source_url),
    method_settings=settings,software_sources=source_pins,benchmark_results=summary,fold_results=perf[,setdiff(names(perf),'message')],
    pooled_results=do.call(rbind,pooled),observed_only_metrics=do.call(rbind,observed),
    calibration_bins=aggregate_bins,run_metadata=metadata,
    solver_checks=solver_checks,
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
  batch_note<-if(length(unique(tables$run_metadata$run_id))>1L)
    'Reviewed earlier executions are retained; added methods were measured in separate sequential execution batches on the same hardware and saved folds. Run IDs, source revisions, fitting sessions and backend descriptions distinguish the measurements.' else
    'Run IDs and fitting sessions identify this execution batch. Combining it with earlier measurements requires matching input identities, saved splits and outcomes.'
  page <- c('---','layout: default','title: GPBench-matched benchmark','---','# GPBench-matched benchmark','',
    '## Scientific question and dataset','',
    'Predict supplied phenotypes using all source markers and the published GPBench ten-fold split algorithm. Original IDs, upstream processing and phenotype units remain unverified.','',
    markdown_table(tables$dataset_catalogue[,c('dataset','species','trait','individuals_evaluated','observed_targets','imputed_targets','available_markers','markers_used')]),'','[Full dataset catalogue and source definitions](dataset_catalogue.csv)','',
    '## Methods and validation','',
    'Shuffled ten-fold KFold, seed 42, scikit-learn 1.6.1 and NumPy 1.26.4. Every method receives the same saved splits and all supplied dosage columns. Genomic BLUP estimates variances by REML through greml/gsolve, using K=ZZt/p. gbayes Gaussian and sparse normal-mixture VB use fixed working h2=0.5 and training-only phenotype/marker variances; the mixture fixes inclusion probability at 0.1. These three methods use raw dosage coordinates without SD scaling.','',
    'GLMA Gaussian and GLMA prior-selected are the full-marker prediction fits underlying glma_infinitesimal_loco() and glma_prior_selected_loco(), respectively. They use the existing native joint fitting modes, without chromosome exclusions or association calibration. GPBench has no chromosome maps; none are invented. Within each outer training fold, GLMA standardizes markers by empirical SD, estimates variance using blocked RHE/Monte Carlo refinement, and uses its internal 10% validation split (seed 17092026). Prior-selected compares ten ridge/elastic candidates; Gaussian uses ridge. The native joint selection/variance procedure sees only outer training outcomes. Its inner selection score is not an external accuracy estimate. Constant training markers are excluded from standardized fitting and receive zero prediction effects; actual counts are in fold/results CSVs.','',
    'The methods share external validation, but differ in preprocessing, prior models, variance estimation and acceptance criteria. Their timings compare complete workflows and do not isolate solver speed. No outer test outcomes enter fitting or prior selection beyond the explicitly reproduced phenotype-imputation rule below.','',
    'To reproduce GPBench, missing phenotypes are mean-imputed before splitting. Two maize DTT targets are imputed; cattle has none. Imputed labels are not genuinely observed phenotypes. The observed-target-only sensitivity summary excludes them from evaluation. This reproduction does not endorse whole-dataset phenotype imputation for a new scientific study.','',
    markdown_table(tables$method_settings[,c('method','package','package_version','native_engines','tuning','convergence')]),'','[Full model and method settings](method_settings.csv)','',
    'Fitting calls gsuite::gs_lmm_fit, gbayes::bayes or the thin glma::glma_full_marker_prediction adapter to our compiled libraries. The GLMA adapter exposes existing C++ fitting and returns effects for a held-out forward prediction; it implements no new estimator. R bindings live in gsuite; native cores have their own repositories. Exact source commits are pinned below; implementation source and binaries remain private.','',
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
    'Workflow seconds include method-specific preparation, ten fits and ten predictions. greml/gsolve includes its reusable raw-dosage kernel and fold blocks. gbayes preparation includes training/target extraction and fitting includes prior calculations. GLMA preparation includes one dosage-only BED cache and target extraction; fitting includes packing training rows, training-marker standardization, RHE/MC variance estimation, candidate selection and the global refit. Each GLMA method is charged the full reusable cache cost once. Native timings exclude verbose tracing. These are single-execution measurements; peak RAM is unmeasured. Zero seconds means below timer resolution.','',batch_note,'',
    'R uses OpenBLAS with four threads. greml/gsolve uses its MKL/CHOLMOD native backend, which reports one component-backend worker. GLMA uses the full native MKL prefix with four requested coordinate/MKL workers; a separate numerical check verified actual MKL DGEMM calls. The earlier gbayes standalone measurements use a portable compiled core without MKL dense kernels and report one worker: R OpenBLAS does not accelerate that core automatically. These backend differences must be considered when comparing times. Returned thread settings do not measure CPU utilization.','',
    'greml acceptance is REML convergence at the declared tolerance. gbayes acceptance is negative-ELBO stabilization. GLMA acceptance is its native approximate joint workflow rule, including prediction stability and adaptive chunk retirement; it is not exact REML or a strict global ELBO certificate. Failed and provisional fits remain explicit.','',
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
      'The retained greml baseline uses score tolerance 1e-4. Its earlier attempt at 1e-6 completed nine folds but failed the likelihood-step acceptance check in fold nine. That attempt and its costs remain disclosed separately. The gbayes convergence criterion is different and is specified in the method settings.','',
      markdown_table(failures),'','[Earlier statuses and costs](earlier_attempts.csv) · [Prediction sensitivity](tolerance_comparison.csv)','')
    position<-match('## Reproduce',page)-1L
    page<-append(page,note,after=position)
  }
  if(any(grepl('^glma_',tables$benchmark_results$method))) page<-append(page,c(
    '> **Numerical audit warning:** The published GLMA Gaussian fast path failed real-data fixed-variance and variance-grid checks. Native acceptance is not numerical qualification. Prior-selected shares the variance-grid path and has not been independently qualified. [Model and variance audit](https://psoerensen.github.io/gpct/glma-gaussian-audit.html).',''),after=6L)
  if(!is.null(attr(tables,'fit_session')))
    page<-c(page,'','[R packages loaded during fitting](fit-sessionInfo.txt)')
  if('glma_fit_diagnostics'%in%names(tables)) page<-c(page,'',
    '## GLMA fitting diagnostics','',
    '[Per-fold selected priors, native acceptance, marker counts and phase timings](glma_fit_diagnostics.csv)','',
    'These are aggregate fit diagnostics; no individual predictions or inner validation identities are published.')
  if('glma_interface_cost'%in%names(tables)) page<-c(page,'',
    '## R interface timing check','',
    'A separate repeat of fold one traces the native Rcpp .Call boundary. It is excluded from benchmark timing totals. Native-call time includes C++ packing, setup and conversion; the inner fitter timer excludes those phases. The difference between the R fitting call and .Call is the measured outside-native wrapper cost, at the coarse elapsed timer resolution. It does not include dataset loading, report generation or the separately recorded target prediction.','',
    markdown_table(tables$glma_interface_cost[,c('dataset','method','r_fit_call_seconds','native_call_seconds','native_inner_fit_seconds','outside_native_call_seconds','native_preparation_and_conversion_seconds')]),'',
    '[Interface timing check CSV](glma_interface_cost.csv)')
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
