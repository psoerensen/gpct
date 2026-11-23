# Aggregate the saved fold-1 fits only. No fitting or website output.
source('scripts/paths.R')
.libPaths(c(file.path(Sys.getenv('GPCT_ENV_DIR'),'comparison-library'),.libPaths()))
root <- file.path(output_dir(),'20261121-mcmc-learning-check')
columns <- c('dataset','trait','method','fold','n_train','n_test','available_markers','markers_used',
  'predictive_ability','rmse','predictive_r_squared','calibration_slope',
  'preparation_seconds','fit_seconds','prediction_seconds','actual_workers')
baseline <- read.csv('docs/assets/reports/gbayes-glist-1t/fold-results.csv')
baseline <- baseline[baseline$method=='marker_gaussian' & baseline$fold==1L,columns]
results <- list(baseline); diagnostics <- list()
for(case in c('cattle','maize')) for(method in c('bayesC_mcmc','bayesR_mcmc','bglr_bayesC')) {
  directory <- file.path(root,if(method=='bglr_bayesC') 'bglr_bayesC_masked' else method,case)
  score <- read.csv(file.path(directory,'fold-results.csv'))
  stopifnot(nrow(score)==1L,score$fold==1L,score$status=='completed')
  results[[length(results)+1L]] <- score[,columns]
  if(method=='bglr_bayesC') {
    trace <- read.csv(file.path(directory,'retained-parameter-traces.csv'))
    variables <- c('residual_variance','effect_variance','inclusion_probability')
    draws <- array(NA_real_,c(1000,2,length(variables)),
      dimnames=list(iteration=1:1000,chain=1:2,variable=variables))
    for(chain in 1:2) draws[,chain,] <- as.matrix(trace[trace$chain==chain,variables])
  } else {
    fit <- readRDS(file.path(directory,'fold1-fit.rds'))
    draws <- fit$draws$parameters
    names(dimnames(draws)) <- c('iteration','chain','variable')
  }
  summary <- as.data.frame(posterior::summarise_draws(posterior::as_draws_array(draws),
    'mean','sd','rhat','ess_bulk','ess_tail'))
  summary$dataset <- paste0('gpbench_',case);summary$method <- method
  diagnostics[[length(diagnostics)+1L]] <- summary
}
results <- do.call(rbind,results);diagnostics <- do.call(rbind,diagnostics)
results$fit_and_prediction_seconds <- results$fit_seconds+results$prediction_seconds
results$preparation_fit_prediction_seconds <- results$preparation_seconds+results$fit_and_prediction_seconds
results$variance_settings <- ifelse(results$method=='marker_gaussian',
  'Fixed variances; working h2=0.5','Learned marker-effect and residual variances')
results$variance_max_rhat <- results$variance_min_ess_bulk <- NA_real_
for(i in seq_len(nrow(results))) {
  d <- diagnostics[diagnostics$dataset==results$dataset[i] &
    diagnostics$method==results$method[i] &
    diagnostics$variable %in% c('residual_variance','effect_variance'),]
  if(nrow(d)) {
    results$variance_max_rhat[i] <- max(d$rhat)
    results$variance_min_ess_bulk[i] <- min(d$ess_bulk)
  }
}
write.csv(results,file.path(root,'comparison-with-bglr.csv'),row.names=FALSE)
write.csv(diagnostics,file.path(root,'common-posterior-diagnostics.csv'),row.names=FALSE)
speed <- do.call(rbind,lapply(c('gpbench_cattle','gpbench_maize'),function(dataset) {
  native <- results[results$dataset==dataset & results$method=='bayesC_mcmc',]
  external <- results[results$dataset==dataset & results$method=='bglr_bayesC',]
  data.frame(dataset,gbayes_fit_prediction_seconds=native$fit_and_prediction_seconds,
    BGLR_fit_prediction_seconds=external$fit_and_prediction_seconds,
    gbayes_over_BGLR_elapsed=native$fit_and_prediction_seconds/external$fit_and_prediction_seconds)
}))
write.csv(speed,file.path(root,'bayesc-speed-comparison.csv'),row.names=FALSE)
efficiency <- merge(diagnostics,results[,c('dataset','method','fit_and_prediction_seconds')],
  by=c('dataset','method'))
efficiency$bulk_ess_per_second <- efficiency$ess_bulk/efficiency$fit_and_prediction_seconds
write.csv(efficiency,file.path(root,'parameter-sampling-efficiency.csv'),row.names=FALSE)
write.csv(data.frame(package='posterior',version=as.character(packageVersion('posterior'))),
  file.path(root,'diagnostics-package-version.csv'),row.names=FALSE)
settings <- readRDS(file.path(root,'bglr_bayesC_masked','maize','settings.rds'))
writeLines(c('Local fold-1 checkpoint comparison; no full cross-validation or publication.',
  'Cattle: mkg; maize: DTT. Identical saved GPBench fold-1 splits and QC markers.',
  'Genotypes use the same training-frequency HWE centering and scaling.',
  'Gaussian PCG results are retained unchanged and use fixed variances (working h2=0.5).',
  'MCMC methods: two sequential chains; 500 burn-in and 1000 retained draws per chain; one thread.',
  'BayesC variance priors and Beta(1,1) inclusion-probability prior are matched across packages.',
  settings$differences,
  'Fit times include each interface/native call and its diagnostics/output work.',
  'BGLR dense decoding/scaling is recorded as preparation; gbayes native packed input work is inside fitting.',
  'Compare fitting plus prediction together: the standard BGLR route performs both inside BGLR().',
  'Training Glist preparation may be cached; check the native shared_preparation_seconds field.',
  'BayesC and BayesR are different models; there is no standard BGLR BayesR comparator here.',
  'Common diagnostics use posterior rank-normalized split R-hat and bulk/tail ESS.',
  'Short-chain results are provisional; parameter diagnostics do not establish all-marker mixing.',
  'The preliminary coefficient-average BGLR attempt is excluded; only bglr_bayesC_masked outputs are used.',
  'BGLR prediction reference: https://cloud.r-project.org/web/packages/BGLR/BGLR.pdf',
  'Individual predictions and fits remain local.'),file.path(root,'comparison-notes.txt'))
print(results[,c('dataset','method','predictive_ability','fit_seconds','prediction_seconds',
  'variance_max_rhat','variance_min_ess_bulk')],row.names=FALSE)
cat('One fold per dataset. Short-chain diagnostics limit inference. No publication.\n')
