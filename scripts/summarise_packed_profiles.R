# Summarise completed kernel replays only; no fitting or publication.
args <- commandArgs(TRUE)
name <- if(length(args)) args[[1]] else 'packed-kernels-memory-budget'
stopifnot(grepl('^[A-Za-z0-9_-]+$',name))
parent <- file.path(Sys.getenv('USERPROFILE'),'gpct-results',
  '20261121-mcmc-learning-check','performance-audit')
directory <- file.path(parent,name)
ratios <- read.csv(file.path(directory,'paired-speed-ratios.csv'))
timings <- read.csv(file.path(directory,'kernel-timings.csv'))
validation <- read.csv(file.path(directory,'kernel-validation.csv'))
memory <- read.csv(file.path(directory,'cache-memory.csv'))
groups <- split(ratios,interaction(ratios$dataset,ratios$model,ratios$kernel,drop=TRUE),drop=TRUE)
summary <- do.call(rbind,lapply(groups,function(x) data.frame(
  dataset=x$dataset[1],model=x$model[1],kernel=x$kernel[1],trials=nrow(x),
  baseline_ms=1000*median(x$baseline_seconds),candidate_ms=1000*median(x$candidate_seconds),
  median_wall_speedup=median(x$speed_ratio),minimum_wall_speedup=min(x$speed_ratio),
  maximum_wall_speedup=max(x$speed_ratio),median_cpu_speedup=median(x$cpu_speed_ratio),
  median_cycle_speedup=median(x$cycle_speed_ratio))))
write.csv(summary,file.path(directory,'profile-summary.csv'),row.names=FALSE)
errors <- aggregate(cbind(max_score_error,max_residual_error)~dataset+model+kernel,validation,max)
write.csv(errors,file.path(directory,'numerical-agreement.csv'),row.names=FALSE)
memory$available_gib <- memory$available_bytes/1024^3
memory$budget_gib <- memory$budget_bytes/1024^3
memory$cache_gib <- memory$required_bytes/1024^3
write.csv(memory,file.path(directory,'cache-memory-readable.csv'),row.names=FALSE)
provenance <- readRDS(file.path(directory,'provenance.rds'))
original <- readRDS(file.path(parent,'packed-kernels','provenance.rds'))
current_sha <- digest::digest(file=provenance$binary,algo='sha256')
stopifnot(identical(original$sha256,provenance$sha256),identical(current_sha,original$sha256))
writeLines(c(
  'Packed-kernel profile: local diagnostic replays, not new benchmark results.',
  'Installed gbayes binary SHA256 remains unchanged:',current_sha,
  'Inputs: saved fold-1 training selections, coding, effects, residuals and marker orders.',
  'Predetermined updates equal 1% of each nonzero saved effect. No MCMC, RNG or variance-learning steps run.',
  'Paired trials alternate candidates between current-kernel anchors. One thread; affinity mask 4 (logical CPU 2).',
  'Wall time, main-thread CPU time and main-thread cycles are reported separately.',
  'Existing gbits decoder and unchanged gbits AVX2 source are exercised in a separate diagnostic DLL.',
  'The installed portable bundle omits gbits AVX2 arithmetic; enabling it alone does not change its fused packed loop.',
  'decode64 variants use a bounded 64-marker decoded buffer. BayesR replay uses an additional packed visit-order view.',
  'The replay view is built once; its setup time and packed size are in kernel-timings.csv.',
  'A production BayesC adapter can borrow its existing ordered packed source.',
  'A production BayesR tile adapter must preserve its saved permutation and account for any reordered packed copy.',
  'cached_blas stores decoded values in ORIGINAL marker coordinates and follows the saved visit order.',
  'It can be shared read-only by chains with the same training coding, without a per-chain reordered dense copy.',
  'Its profiling allocation is capped at min(2 GiB, 20% of then-available physical RAM); otherwise it is skipped.',
  'The cache is released between dataset/model cases. Larger panels can retain the current packed route.',
  'Candidate integration: an opt-in C++ data-access cache, built by the existing gbits decoder from Glist training coding.',
  'Share that immutable cache across chains; apply existing BLAS dot/update kernels in the original sampler order.',
  'Keep the existing packed implementation as the memory-budget fallback. No production cache control exists yet.',
  'Only static genotypes may be decoded/cached in batches. Scores and residual updates remain sequential.',
  'Computing all marker scores from one stale residual would change the sampler and is excluded.',
  'No genotype coding, marker order, fitting equations, variance priors or learning rules have been changed.',
  'Floating-point reduction order differs between kernels; numerical tolerances rather than bitwise equality apply.',
  'Kernel speedups do not establish full-fit speedups. Production integration and full-fit validation are separate work.',
  'No website generation, commit or push was performed.'),file.path(directory,'profile-notes.txt'))
print(summary,row.names=FALSE)
print(memory[,c('dataset','model','allocated','available_gib','budget_gib','cache_gib','seconds')],row.names=FALSE)
cat('Maximum score error:',max(errors$max_score_error),'residual error:',max(errors$max_residual_error),'\n')
