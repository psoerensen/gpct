# Audit the four local fold-1 checkpoints without refitting or publishing.
args <- commandArgs(TRUE)
paths <- args[!startsWith(args,'--')]
partial <- '--partial' %in% args
root <- if(length(paths)) paths[[1]] else file.path(Sys.getenv('USERPROFILE'),
  'gpct-results','20261121-mcmc-learning-check')
results <- learning <- diagnostics <- list()
for(method in c('bayesC_mcmc','bayesR_mcmc')) for(dataset in c('maize','cattle')) {
  directory <- file.path(root,method,dataset)
  required <- file.path(directory,c('fold1-fit.rds','fold-results.csv'))
  if(!all(file.exists(required))) {
    if(partial) next
    stop('Checkpoint not ready: ',method,' / ',dataset)
  }
  fit <- readRDS(required[[1]])
  flags <- fit$input$learning
  stopifnot(isTRUE(flags[['updateB']]),isTRUE(flags[['updateE']]),
    fit$input$algorithm=='mcmc',fit$input$likelihood=='individual_bed',
    fit$input$method==if(method=='bayesC_mcmc') 'bayesC' else 'bayesR',
    fit$input$nativeControl$threads==1L,fit$input$execution$ncores==1L,
    fit$input$execution$nchains==2L,
    isTRUE(fit$input$nativeControl$estimate_effect_variance),
    isTRUE(fit$input$nativeControl$estimate_residual_variance),
    identical(as.numeric(fit$input$execution$seeds),c(42002,42003)))
  traces <- fit$draws$parameters
  stopifnot(length(dim(traces))==3L,dim(traces)[1]==1000L,dim(traces)[2]==2L)
  quantities <- dimnames(traces)[[3]]
  for(parameter in c('effect_variance','residual_variance')) {
    stopifnot(parameter %in% quantities)
    start <- fit$input$initialization[[if(parameter=='effect_variance') 'vb' else 've']]
    for(chain in seq_len(dim(traces)[2])) {
      values <- traces[,chain,match(parameter,quantities)]
      stopifnot(all(is.finite(values)),all(values>0),length(unique(values))>1L)
      learning[[length(learning)+1L]] <- data.frame(dataset,method,parameter,chain,
        initial_variance=as.numeric(start),posterior_mean=mean(values),
        posterior_sd=sd(values),minimum=min(values),maximum=max(values),
        distinct_draws=length(unique(values)),variance_learning_verified=TRUE)
    }
  }
  d <- fit$posterior$parameterSummary
  stopifnot(all(c('parameter','rhat','ess_bulk') %in% names(d)))
  d$dataset <- dataset; d$method <- method
  diagnostics[[length(diagnostics)+1L]] <- d
  scores <- read.csv(required[[2]],stringsAsFactors=FALSE)
  stopifnot(nrow(scores)==1L,scores$fold==1L,scores$status=='completed',
    scores$actual_workers==1L,is.finite(scores$predictive_ability))
  prediction <- read.csv(file.path(directory,'fold1-predictions-local.csv'))
  stopifnot(nrow(prediction)==scores$n_test,all(is.finite(prediction$predicted)))
  monitored <- d[d$parameter %in% c('effect_variance','residual_variance'),]
  stopifnot(nrow(monitored)==2L,all(monitored$estimated))
  scores$variance_learning_verified <- TRUE
  scores$variance_max_rhat <- if(all(is.finite(monitored$rhat))) max(monitored$rhat) else NA_real_
  scores$variance_min_ess_bulk <- if(all(is.finite(monitored$ess_bulk))) min(monitored$ess_bulk) else NA_real_
  scores$diagnostic_note <- 'Two short chains; parameter diagnostics do not establish all-marker mixing.'
  results[[length(results)+1L]] <- scores
}
if(!length(results)) stop('No completed checkpoints available.')
write.csv(do.call(rbind,learning),file.path(root,'variance-learning.csv'),row.names=FALSE)
write.csv(do.call(rbind,diagnostics),file.path(root,'mcmc-diagnostics.csv'),row.names=FALSE)
summary <- do.call(rbind,results)
write.csv(summary,file.path(root,'checkpoint-summary.csv'),row.names=FALSE)
baseline_path <- 'docs/assets/reports/gbayes-glist-1t/fold-results.csv'
if(file.exists(baseline_path)) {
  baseline <- read.csv(baseline_path,stringsAsFactors=FALSE)
  baseline <- baseline[baseline$method=='marker_gaussian' & baseline$fold==1L,]
  columns <- c('dataset','trait','method','fold','n_train','n_test','markers_used',
    'predictive_ability','rmse','fit_seconds','prediction_seconds','actual_workers')
  comparison <- rbind(baseline[,columns],summary[,columns])
  comparison$variance_settings <- ifelse(comparison$method=='marker_gaussian',
    'Fixed variances; working h2=0.5','Native MCMC variance learning')
  write.csv(comparison,file.path(root,'comparison-with-gaussian-pcg.csv'),row.names=FALSE)
}
print(summary[,c('dataset','method','predictive_ability','fit_seconds',
  'prediction_seconds','variance_max_rhat','variance_min_ess_bulk')],row.names=FALSE)
cat('Verified native variance learning, Glist input and one-worker controls for',
  nrow(summary),'fold-1 fits.',if(partial) 'Partial checkpoint audit.' else 'All four checks complete.','\n')
