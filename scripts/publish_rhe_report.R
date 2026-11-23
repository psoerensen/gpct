# Aggregate-only publication. No individual predictions, fitted weights or source.
local({
 evaluation<-bind_rows(lapply(c('cattle','maize'),function(case){
  directory<-file.path(rhe_root,case)
  x<-read.csv(file.path(directory,'fold-results.csv'),stringsAsFactors=FALSE)
  fits<-lapply(1:10,function(k)readRDS(file.path(directory,paste0('fold',k,'-fit.rds'))))
  x$moment_condition<-vapply(fits,function(z)if(is.null(z$variance$condition))NA_real_ else z$variance$condition,numeric(1))
  x$maximum_moment_mc_se<-vapply(fits,function(z)if(is.null(z$variance$moment_matrix_mc_se))NA_real_ else max(z$variance$moment_matrix_mc_se),numeric(1))
  x$cache_budget_bytes<-vapply(fits,function(z)if(is.null(z$cache_budget_bytes))NA_real_ else z$cache_budget_bytes,numeric(1))
  x
 }))
 stopifnot(nrow(evaluation)==20L,!anyDuplicated(evaluation[c('dataset','fold')]),
  all(evaluation$status%in%c('completed','failed')),
  all(evaluation$true_relative_residual[evaluation$status=='completed']<=1e-8))
 write.csv(evaluation,file.path(asset,'rhe-fold-diagnostics.csv'),row.names=FALSE)
 trace_path<-file.path(output_dir(),'20261122-rhe-blup-glist/trace-precision/summary.csv')
 trace<-read.csv(trace_path)
 trace$dataset<-'gpbench_cattle';trace$trait<-'mkg';trace$fold<-1L
 write.csv(trace,file.path(asset,'rhe-trace-precision.csv'),row.names=FALSE)
 modules<-read.csv(file.path(output_dir(),'20261122-rhe-blup-evaluation/loaded-native-modules.csv'),stringsAsFactors=FALSE)
 modules<-modules[c('module','version','sha256','sampled_utc')]
 write.csv(modules,file.path(asset,'rhe-loaded-runtime.csv'),row.names=FALSE)
 reference_directory<-file.path(output_dir(),'20261122-rhe-blup-glist/1t/maize')
 one<-readRDS(file.path(reference_directory,'fold1-fit.rds'))
 four<-readRDS(file.path(rhe_root,'maize/fold1-fit.rds'))
 one_config<-readRDS(file.path(reference_directory,'configuration.rds'))
 four_config<-readRDS(file.path(rhe_root,'maize/configuration.rds'))
 stopifnot(identical(one_config$native_sha256,four_config$native_sha256),
   one_config$probes==four_config$probes,one_config$pcg_tolerance==four_config$pcg_tolerance,
   one$cache_status=='enabled',four$cache_status=='enabled',one$cache_bytes==four$cache_bytes,
   max(abs(one$prediction-four$prediction))<1e-7,
   max(abs(c(one$variance$raw_genetic,one$variance$raw_residual)-c(four$variance$raw_genetic,four$variance$raw_residual)))<1e-8)
 one_row<-read.csv(file.path(reference_directory,'fold-results.csv'))
 four_row<-evaluation[evaluation$dataset=='gpbench_maize'&evaluation$fold==1L,]
 threading<-data.frame(dataset='gpbench_maize',fold=1L,probes=128L,
   one_thread_fit_seconds=one_row$fit_seconds,four_thread_fit_seconds=four_row$fit_seconds,
   fitting_speedup=one_row$fit_seconds/four_row$fit_seconds,
   maximum_prediction_difference=max(abs(one$prediction-four$prediction)),
   native_libraries_match=TRUE,cache_bytes=one$cache_bytes,
   scope='Same saved maize fold, ordinary RHE controls and native libraries; separate from MCMC chain probes')
 write.csv(threading,file.path(asset,'rhe-thread-comparison.csv'),row.names=FALSE)
 score<-s[s$method=='rhe_blup',]
 table<-data.frame(Dataset=ifelse(score$dataset=='gpbench_cattle','Cattle / mkg','Maize / DTT'),
  `Accepted folds`=paste0(score$accepted_folds,' / 10'),Correlation=fmt(score$predictive_ability_mean),
  RMSE=fmt(score$rmse_mean),`Fit seconds`=fmt(score$fit_seconds,1),
  `Predict seconds`=fmt(score$prediction_seconds,1),`Process peak MiB`=fmt(score$process_peak_working_set_mib,0),
  Status=display_status(score$status),check.names=FALSE)
 stages<-do.call(rbind,lapply(split(evaluation,evaluation$dataset),function(x)data.frame(
  Dataset=unique(x$dataset),`Native preparation s`=fmt(sum(x$genotype_preparation_seconds),1),
  `RHE s`=fmt(sum(x$rhe_seconds),1),`BLUP s`=fmt(sum(x$blup_seconds),1),
  `Native covariance adjustments`=sum(x$variance_adjusted),check.names=FALSE)))
 component_view<-data.frame(Dataset=evaluation$dataset,Fold=evaluation$fold,
  `Raw genetic`=fmt(evaluation$raw_genetic,5),`Raw residual`=fmt(evaluation$raw_residual,5),
  `Adjusted genetic`=fmt(evaluation$genetic,5),`Adjusted residual`=format(evaluation$residual,digits=4),
  Status=evaluation$status,check.names=FALSE)
 precision_view<-data.frame(Probes=trace$probes,`Raw genetic`=fmt(trace$raw_genetic,5),
  `Raw residual`=fmt(trace$raw_residual,5),`RHE seconds`=fmt(trace$rhe_seconds,2),check.names=FALSE)
 cattle<-evaluation[evaluation$dataset=='gpbench_cattle',]
 writeLines(c('---','layout: default','title: Ordinary RHE and BLUP','---','# Ordinary RHE + BLUP','',
  'One ordinary native greml RHE variance-estimation pass is followed by the existing native BLUP solve. This is a Gaussian genomic relationship model with an intercept, not REML. Every stage receives selections and training-frequency coding from the same QC-selected Glist and saved GPBench ten-fold splits as the other methods.','',
  markdown_table(table),'',
  'An aggregate accuracy is available only when all ten held-out folds have accepted predictions. Failed fits are retained; successful folds are not selectively averaged into a ten-fold score. Cattle with unavailable accuracy is omitted from the accuracy-versus-runtime and calibration curves. Its attempted fitting cost remains in the cost table.','',
  '## Cattle variance boundary','',
  paste('Ordinary RHE returned negative raw residual estimates in',sum(cattle$raw_residual<0,na.rm=TRUE),'of ten cattle folds. Negative moment estimates are estimates outside the covariance parameter space, not negative biological variances. The existing native adjustment floors the residual covariance at 1e-8; the BLUP solver and its final acceptance check were retained. Native failure messages are in the diagnostics CSV.'),'',
  'The first cattle fold was also checked with larger trace-probe sets. The negative estimate persisted. These are four-thread RHE-only diagnostics; they are not extra CV replicates or accepted prediction runs.','',
  markdown_table(precision_view),'',
  '## Variance estimates by fold','',markdown_table(component_view),'',
  '## Timing and execution','',markdown_table(stages),'',
  'Fit time includes private-interface validation, packed preparation, the decoded cache, RHE and BLUP. Held-out prediction is timed separately. Whole-process time and peak RAM also include loading, saved outputs and Glist metadata. Failed BLUP attempts retain their measured cost; prediction is unavailable when it was not run.','',
  'Heavy covariance products call the existing gsolve::dense_product oneMKL kernels. The native cache is shared across RHS columns and capped at min(2 GiB, 20% of available physical RAM); it falls back to existing packed gbits products when insufficient. Coding and the RHE/BLUP algorithms are unchanged. A separate reference run verified cached versus packed products and one/four-thread predictions against dense RHE moments and GLS/held-out BLUP to about 1e-14.','',
  'Four threads here mean an operation-local native MKL cap for one RHE/BLUP fit, not four MCMC chains. R/OpenBLAS remains at one thread. MKL dispatch and one/four-thread caps were checked outside timed runs with verbose diagnostics; logging was disabled for timings. Loaded oneMKL libraries report version 2026.2.0. Four-thread measurements use logical CPUs 0–3; the one-thread checks use CPU 2.','',
  paste('On the same maize first fold, fitting took',fmt(threading$one_thread_fit_seconds,2),'seconds with one thread and',fmt(threading$four_thread_fit_seconds,2),'seconds with four. Native library checksums, probe controls and cache admission match; the maximum prediction difference was',format(threading$maximum_prediction_difference,scientific=TRUE),'. This is a same-fold threading check, not a comparison of different algorithms.'),'',
  '## Exact controls and scope','',
  '- 128 common Rademacher probes, batches of 8; seed 62000 + outer fold.',
  '- Training allele-frequency HWE coding, mean-imputed from training; K = Z Zᵀ / marker count.',
  '- Native block PCG: inner relative tolerance 1e-10, cap 1000 iterations; final true-relative-residual gate 1e-8.',
  '- Native genetic PSD floor 0 and residual positive floor 1e-8; raw and adjusted estimates remain separate.',
  '- The inner tolerance was tightened from the initial 1e-8 test to satisfy the unchanged final post-GLS residual gate on maize. A retained small negative-residual reference also failed BLUP; no failed solve was accepted by relaxing its gate.','',
  'The implementation and private Glist adapter are not published. This website contains only aggregate results, settings, diagnostics and software identities. Reproduction requires authorized access to the retained qualified native build and local recipes.','',
  '[Fold diagnostics and failure messages](../assets/reports/gbayes-glist/rhe-fold-diagnostics.csv) · [Trace precision](../assets/reports/gbayes-glist/rhe-trace-precision.csv) · [One/four-thread maize check](../assets/reports/gbayes-glist/rhe-thread-comparison.csv) · [Actually loaded native libraries and checksums](../assets/reports/gbayes-glist/rhe-loaded-runtime.csv)','',
  '[Cattle report and plots](cattle.html) · [Maize report and plots](maize.html) · [All results](../results.html)'),
  'docs/reports/rhe-blup.md')
 cat('\n[Ordinary RHE + BLUP: acceptance, variance estimates and failures](reports/rhe-blup.html)\n',file='docs/results.md',append=TRUE)
})
