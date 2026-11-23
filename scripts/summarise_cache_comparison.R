# Review local cache comparison outputs only; no fitting or publication.
args <- commandArgs(TRUE);partial <- '--partial' %in% args
env_root <- Sys.getenv('GPCT_ENV_DIR');stopifnot(nzchar(env_root))
.libPaths(c(file.path(env_root,'comparison-library'),.libPaths()))
root <- file.path(Sys.getenv('GPCT_OUTPUT_DIR',file.path(Sys.getenv('USERPROFILE'),'gpct-results')),
  Sys.getenv('GPCT_RUN_ID','20261121-cache-comparison'))
reference_root <- file.path(Sys.getenv('USERPROFILE'),'gpct-results','20261121-mcmc-learning-check')
results <- diagnostics <- invariants <- list()
for(case in c('cattle','maize')) for(method in c('bayesC_mcmc','bayesR_mcmc','bglr_bayesC_masked')) {
  directory <- file.path(root,method,case)
  files <- file.path(directory,c('fold-results.csv','process-resources.json'))
  if(!all(file.exists(files))) {
    if(partial)next
    stop('Incomplete run: ',method,' / ',case)
  }
  score <- read.csv(files[[1]],stringsAsFactors=FALSE)
  resource <- jsonlite::fromJSON(files[[2]])
  stopifnot(nrow(score)==1L,score$fold==1L,score$status=='completed',
    resource$exit_code==0L,resource$affinity_mask==4L,score$actual_workers==1L)
  cache <- list(status='external dense matrix',allocated_bytes=NA_real_,budget_bytes=NA_real_,
    available_bytes=NA_real_,preparation_seconds=NA_real_)
  preparation <- sampler <- NA_real_
  if(method=='bglr_bayesC_masked') {
    trace <- read.csv(file.path(directory,'retained-parameter-traces.csv'))
    variables <- c('residual_variance','effect_variance','inclusion_probability')
    draws <- array(NA_real_,c(1000L,2L,3L),
      dimnames=list(iteration=1:1000,chain=1:2,variable=variables))
    for(chain in 1:2) draws[,chain,] <- as.matrix(trace[trace$chain==chain,variables])
  } else {
    fit <- readRDS(file.path(directory,'fold1-fit.rds'))
    old <- readRDS(file.path(reference_root,method,case,'fold1-fit.rds'))
    for(field in c('prior','learning','initialization')) stopifnot(identical(fit$input[[field]],old$input[[field]]))
    for(field in c('samples','markers','coding')) stopifnot(identical(fit$data[[field]],old$data[[field]]))
    for(field in c('nit','nburn','nthin','nchains','ncores','seeds'))
      stopifnot(identical(fit$input$execution[[field]],old$input$execution[[field]]))
    stopifnot(fit$input$likelihood=='individual_bed',isTRUE(fit$input$learning[['updateB']]),
      isTRUE(fit$input$learning[['updateE']]),fit$input$nativeControl$threads==1L)
    cache <- fit$diagnostics$genotypeCache
    stopifnot(cache$allocated_bytes<=cache$budget_bytes,cache$budget_bytes<=2*1024^3,
      cache$budget_bytes<=cache$available_bytes/5)
    if(cache$status=='enabled') stopifnot(cache$allocated_bytes==score$n_train*score$markers_used*8,
      isTRUE(cache$shared_across_chains))
    preparation <- fit$diagnostics$nativeTiming$genotype_preparation_seconds
    sampler <- fit$diagnostics$nativeTiming$sampler_seconds
    draws <- fit$draws$parameters;names(dimnames(draws)) <- c('iteration','chain','variable')
    order_same <- all(vapply(seq_along(fit$final$states),function(chain)
      identical(fit$final$states[[chain]]$marker_order,old$final$states[[chain]]$marker_order),logical(1)))
    rng_same <- all(vapply(seq_along(fit$final$states),function(chain)
      identical(fit$final$states[[chain]]$rng_state,old$final$states[[chain]]$rng_state),logical(1)))
    stopifnot(order_same)
    invariants[[length(invariants)+1L]] <- data.frame(dataset=case,method,
      prior_learning_coding_samples_markers_execution_identical=TRUE,
      marker_visit_order_identical=order_same,final_rng_state_identical=rng_same,
      maximum_effect_difference_from_original=max(abs(fit$posterior$effects-old$posterior$effects)),
      maximum_parameter_trace_difference_from_original=max(abs(fit$draws$parameters-old$draws$parameters)))
  }
  for(parameter in c('effect_variance','residual_variance')) for(chain in 1:2) {
    values <- draws[,chain,parameter]
    stopifnot(all(is.finite(values)),all(values>0),length(unique(values))>1L)
  }
  d <- as.data.frame(posterior::summarise_draws(posterior::as_draws_array(draws),
    'mean','sd','rhat','ess_bulk','ess_tail'))
  d$dataset <- case;d$method <- method
  diagnostics[[length(diagnostics)+1L]] <- d
  variance <- d[d$variable %in% c('residual_variance','effect_variance'),]
  results[[length(results)+1L]] <- data.frame(dataset=case,trait=score$trait,method,fold=1L,
    n_train=score$n_train,n_test=score$n_test,available_markers=score$available_markers,
    markers_used=score$markers_used,predictive_ability=score$predictive_ability,rmse=score$rmse,
    predictive_r_squared=score$predictive_r_squared,calibration_slope=score$calibration_slope,
    external_preparation_seconds=score$preparation_seconds,fit_seconds=score$fit_seconds,
    prediction_seconds=score$prediction_seconds,fit_prediction_seconds=score$fit_seconds+score$prediction_seconds,
    native_genotype_preparation_seconds=preparation,native_sampler_seconds=sampler,
    cache_status=cache$status,cache_bytes=cache$allocated_bytes,cache_budget_bytes=cache$budget_bytes,
    available_bytes_at_allocation=cache$available_bytes,cache_preparation_seconds=cache$preparation_seconds,
    process_elapsed_seconds=resource$elapsed_seconds,process_peak_ram_gib=resource$peak_working_set_bytes/1024^3,
    process_user_cpu_seconds=resource$user_cpu_seconds,threads=1L,affinity_mask=resource$affinity_mask,
    variance_learning_verified=TRUE,variance_max_rhat=max(variance$rhat),variance_min_ess_bulk=min(variance$ess_bulk))
}
if(!length(results))stop('No completed runs yet.')
results <- do.call(rbind,results)
write.csv(results,file.path(root,'comparison.csv'),row.names=FALSE)
write.csv(do.call(rbind,diagnostics),file.path(root,'mcmc-diagnostics.csv'),row.names=FALSE)
if(length(invariants))write.csv(do.call(rbind,invariants),file.path(root,'unchanged-model-checks.csv'),row.names=FALSE)
speed <- list()
for(case in c('cattle','maize')) {
  native <- results[results$dataset==case & results$method=='bayesC_mcmc',]
  external <- results[results$dataset==case & results$method=='bglr_bayesC_masked',]
  if(nrow(native)&&nrow(external))speed[[case]] <- data.frame(dataset=case,
    gbayes_fit_prediction_seconds=native$fit_prediction_seconds,
    BGLR_fit_prediction_seconds=external$fit_prediction_seconds,
    BGLR_over_gbayes_elapsed=external$fit_prediction_seconds/native$fit_prediction_seconds)
}
if(length(speed))write.csv(do.call(rbind,speed),file.path(root,'bayesc-speed-comparison.csv'),row.names=FALSE)
writeLines(c('Local fold-1 cache comparison. No website update or publication.',
  'Identical saved GPBench 10-fold/seed-42 fold 1, QC markers, training coding, priors and chain settings.',
  'Two sequential chains: 500 burn-in + 1000 retained transitions each. One thread; all new runs use logical CPU 2.',
  'Cache cap: min(2 GiB, 20% of physical RAM available immediately before allocation).',
  'One read-only training cache shared across chains. Packed fallback when disabled, over budget or allocation fails.',
  'Only the native BED data-access object changed; all 90 other native archive objects are byte-identical.',
  'Fit seconds include genotype/cache preparation, native sampler work and result formatting. Prediction is separate.',
  'Native sampler time includes its original variance learning and diagnostics. Cache setup is also reported separately.',
  'BGLR uses masked test phenotypes and native yHat predictions; its fitting call includes prediction updates.',
  'BGLR BayesC has matched variance and inclusion-probability priors; its intercept, initialization and transition differ.',
  'There is no direct BGLR BayesR comparator here. BayesR is a separate gsuite model.',
  'Process peak RAM covers loading, preparation, fitting, saving and prediction; it is not fit-only RAM.',
  'Prior uncached timings used different CPU scheduling and are not a controlled runtime baseline for these new runs.',
  'Gaussian PCG remains unchanged; it was not rerun in this comparison.',
  'Short chains may mix poorly; accuracy and parameter estimates remain provisional.',
  'Individual predictions and private source remain local.'),file.path(root,'comparison-notes.txt'))
print(results[,c('dataset','method','predictive_ability','fit_prediction_seconds','cache_preparation_seconds',
  'process_peak_ram_gib','variance_max_rhat','variance_min_ess_bulk')],row.names=FALSE)
cat(if(partial)'Partial local comparison.' else 'Six local runs checked.','\n')
