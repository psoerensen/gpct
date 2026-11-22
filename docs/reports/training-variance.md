---
layout: default
title: Training-only variance comparison
---
# Training-only variance comparison

<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}</style>

<!-- report-version:80c9caf4f579f40b -->

Four current genomic-prediction methods on the cattle **mkg** and maize **DTT** panels, using QC PLINK → Glist, shared saved folds and training-only preprocessing. Only completed ten-fold method/dataset results receive aggregate scores.

<a id="methods-in-this-comparison"></a>
## Methods in this comparison

| Method | What is fitted | Variance policy | Threads |
|---|---|---|---:|
| Gaussian PCG | Equal Gaussian shrinkage across standardized markers. | Uniform-kernel variance pair estimated from training phenotypes, then fixed. | 4 |
| D-weighted PCG | Fixed allele-frequency weights: qⱼ = [2pⱼ(1−pⱼ)]^0.75. | Variance pair estimated using the matching D-weighted training kernel, then fixed. | 4 |
| Warm-start adaptive B | Deterministic two-Gaussian conditional weight updates around PCG; previous solutions warm-start subsequent solves. | Initial uniform-kernel training variance pair stays fixed as weights adapt. Not BayesB MCMC. | 4 |
| BayesA MCMC | All markers; sampled continuous marker-specific variances and posterior-mean effects. | Marker and residual variances learned by MCMC; two sequential chains, each 500 burn-in + 1,000 post-burn sweeps. | 1 |

Gaussian, D-weighted and B use training empirical genotype variance and normalize their kernel to mean diagonal one. BayesA retains its existing HWE coding. Their priors/inference therefore differ; the table compares predictions rather than claiming statistical equivalence.

## Data scope

| Dataset / trait | Individuals | Observed phenotypes scored | Available markers | Markers used across folds |
|---|---:|---:|---:|---:|
| Cattle / mkg | 5,024 | 5,024 | 42,551 | 42,373–42,373 |
| Maize / DTT | 1,458 | 1,456 | 75,304 | 75,304–75,304 |

Available markers and markers used are separate counts. Training-fold polymorphism checks can change the retained count. Synthetic BIM/FAM labels are bookkeeping, not biological maps. See the [dataset catalogue](../datasets.html).

## Predictive performance

| Dataset | Method | PCC mean | RMSE mean | Pooled predictive R² | Calibration slope | Status |
|---|---|---:|---:|---:|---:|---|
| Cattle / mkg | Gaussian PCG | 0.7772 | 0.6283 | 0.6048 | 1.0019 | Completed |
| Cattle / mkg | D-weighted PCG | 0.7808 | 0.6238 | 0.6104 | 1.0024 | Completed |
| Cattle / mkg | Warm-start adaptive B | — | — | — | — | Pending: 1/10 folds |
| Cattle / mkg | BayesA MCMC | — | — | — | — | Pending: 1/10 folds |
| Maize / DTT | Gaussian PCG | 0.6423 | 2.1986 | 0.4076 | 0.9915 | Completed |
| Maize / DTT | D-weighted PCG | 0.6507 | 2.1789 | 0.4183 | 0.9939 | Completed |
| Maize / DTT | Warm-start adaptive B | — | — | — | — | Pending: 1/10 folds |
| Maize / DTT | BayesA MCMC | — | — | — | — | Pending: 0/10 folds |

PCC and RMSE are arithmetic means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Fold dots show descriptive variation, not independent experimental replicates or confidence intervals. A failed or missing fit suppresses its ten-fold accuracy aggregate. MCMC mixing warnings remain provisional.

## Computational cost

| Dataset | Method | Threads | Variance setup s/fold | Fit + predict s/fold | Total s/fold | Peak process MiB |
|---|---|---:|---:|---:|---:|---:|
| Cattle | Gaussian PCG | 4 | 40.1 | 19.9 | 60.1 | 2364 |
| Cattle | D-weighted PCG | 4 | 39.2 | 20.8 | 59.9 | 2364 |
| Cattle | Warm-start adaptive B | 4 | — | — | — | 2364 |
| Cattle | BayesA MCMC | 1 | included in MCMC | — | — | 1727 |
| Maize | Gaussian PCG | 4 | 20.6 | 12.7 | 33.3 | 1231 |
| Maize | D-weighted PCG | 4 | 18.4 | 11.7 | 30.1 | 1232 |
| Maize | Warm-start adaptive B | 4 | — | — | — | 1231 |
| Maize | BayesA MCMC | 1 | included in MCMC | — | — | — |

Times are mean seconds per fold, including genotype/cache preparation, variance estimation, fitting and prediction; startup and saving are excluded. Gaussian and B share one actual uniform-kernel variance estimate per fold, but each standalone total includes that setup. BayesA learns variances during sampling. All fits run sequentially on the same machine; PCG requests four MKL product threads and BayesA one worker. Some validated first-fold measurements are reused from earlier serial runs. Peak RAM covers complete R processes.

## Validation and settings

Saved ten-fold CV uses seed 42. Cohort-level genotype-only QC defines the marker panel (MAF ≥1%, marker missingness ≤5%; HWE reported without filtering). Each training fold then gets its own Glist, genotype scaling and phenotype mean. Missing training phenotypes use the training-only observed mean. Maize has two missing phenotypes; their held-out occurrences in folds 2 and 7 are excluded from scoring (1,456 observed targets overall). All 5,024 cattle targets are observed. Held-out outcomes cannot enter variance estimation or phenotype preprocessing; this distinguishes the configuration from older full-panel-imputation results.

Gaussian and D estimate their genetic/residual pair with the existing native continuous Monte Carlo REML variance-ratio controller, using 64 common simulation pairs (seed 82803), initial log(e/g)=0, equation tolerance 1e-4 or bracket width 0.005. Each kernel gets its own estimate. B inherits the uniform Gaussian pair and keeps both absolute components fixed while adapting marker weights. No previous outer-test grid score selects a setting. The equation MC standard error is conditional simulation error, not a heritability standard error.

For these small panels, variance fitting uses bounded training covariance matrices and existing MKL Cholesky/projection kernels; final predictions use the RAM-budgeted genotype cache with packed fallback and PCG. Inner PCG tolerance is 1e-10 with a 1e-8 true-residual gate and 1,000-iteration cap. B requires three consecutive weight/effect/training-prediction changes below 0.002, with damping 0.5 and an 80-solve cap. It is a deterministic working prototype, distinct from BayesB MCMC.

BayesA uses one worker and two sequential chains, each with 500 burn-in and 1,000 post-burn sweeps, thinning one, seeds 42000 + 2×fold and the next integer. Both local marker and residual variances are sampled. Fixed inverse-chi-squared hyperpriors have df=4 and training-derived scales. R-hat >1.05, bulk ESS <100 or unavailable diagnostics make a completed MCMC row provisional.

Every published prediction is checked by an independent reconstruction from BED genotypes and fitted effects. Training-only input checks, native numerical gates and unique out-of-fold coverage are retained. Individual predictions stay local; the calibration downloads are reviewed bin means and counts.

Fitting uses the existing gsuite native libraries greml, gsolve, gbits and gbayes, reached through experimental private adapters. Public downloads contain aggregate metrics, settings, diagnostics and binary identities; individual predictions, effects and implementation source remain private. This is bounded evidence for the tested builds and panels, not a released-interface or large-cohort qualification claim.

## Downloads

[Summary CSV](../assets/reports/training-variance/summary.csv) · [Completed fold metrics](../assets/reports/training-variance/fold-results.csv) · [Method settings](../assets/reports/training-variance/method-settings.csv) · [Variance estimates](../assets/reports/training-variance/variance-estimates.csv) · [Validation](../assets/reports/training-variance/validation.csv) · [Process resources](../assets/reports/training-variance/process-resources.csv) · [Build identities](../assets/reports/training-variance/build-info.csv)

<style>.comparison-scroll{overflow-x:auto;margin:1.25rem 0}.comparison-scroll img{display:block;width:100%;min-width:640px;height:auto}.comparison-scroll figcaption{font-size:.95rem;color:#586069}</style>

## Cattle / mkg

| Dataset | Method | PCC mean | RMSE mean | Pooled predictive R² | Calibration slope | Status |
|---|---|---:|---:|---:|---:|---|
| Cattle / mkg | Gaussian PCG | 0.7772 | 0.6283 | 0.6048 | 1.0019 | Completed |
| Cattle / mkg | D-weighted PCG | 0.7808 | 0.6238 | 0.6104 | 1.0024 | Completed |
| Cattle / mkg | Warm-start adaptive B | — | — | — | — | Pending: 1/10 folds |
| Cattle / mkg | BayesA MCMC | — | — | — | — | Pending: 1/10 folds |

| Dataset | Method | Threads | Variance setup s/fold | Fit + predict s/fold | Total s/fold | Peak process MiB |
|---|---|---:|---:|---:|---:|---:|
| Cattle | Gaussian PCG | 4 | 40.1 | 19.9 | 60.1 | 2364 |
| Cattle | D-weighted PCG | 4 | 39.2 | 20.8 | 59.9 | 2364 |
| Cattle | Warm-start adaptive B | 4 | — | — | — | 2364 |
| Cattle | BayesA MCMC | 1 | included in MCMC | — | — | 1727 |

### Predictive performance

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/performance.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/cattle/performance.svg?v=80c9caf4f579f40b" alt="Cattle: Fold PCC dots and completed ten-fold means by method. Pending or failed aggregates are not assigned a score."></a><figcaption>Fold PCC dots and completed ten-fold means by method. Scroll on smaller screens or <a href="../assets/reports/training-variance/cattle/performance.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Improvement over Gaussian

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/improvement.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/cattle/improvement.svg?v=80c9caf4f579f40b" alt="Cattle: Difference in mean PCC from the training-estimated Gaussian baseline. Pending or failed aggregates are not assigned a score."></a><figcaption>Difference in mean PCC from the training-estimated Gaussian baseline. Scroll on smaller screens or <a href="../assets/reports/training-variance/cattle/improvement.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Performance and runtime

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/runtime.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/cattle/runtime.svg?v=80c9caf4f579f40b" alt="Cattle: Mean PCC against mean total seconds per fold, logarithmic runtime axis. Pending or failed aggregates are not assigned a score."></a><figcaption>Mean PCC against mean total seconds per fold, logarithmic runtime axis. Scroll on smaller screens or <a href="../assets/reports/training-variance/cattle/runtime.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Aggregate calibration

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/calibration.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/cattle/calibration.svg?v=80c9caf4f579f40b" alt="Cattle: Binned pooled out-of-fold observed phenotype against prediction, with identity line. Pending or failed aggregates are not assigned a score."></a><figcaption>Binned pooled out-of-fold observed phenotype against prediction, with identity line. Scroll on smaller screens or <a href="../assets/reports/training-variance/cattle/calibration.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>


## Maize / DTT

| Dataset | Method | PCC mean | RMSE mean | Pooled predictive R² | Calibration slope | Status |
|---|---|---:|---:|---:|---:|---|
| Maize / DTT | Gaussian PCG | 0.6423 | 2.1986 | 0.4076 | 0.9915 | Completed |
| Maize / DTT | D-weighted PCG | 0.6507 | 2.1789 | 0.4183 | 0.9939 | Completed |
| Maize / DTT | Warm-start adaptive B | — | — | — | — | Pending: 1/10 folds |
| Maize / DTT | BayesA MCMC | — | — | — | — | Pending: 0/10 folds |

| Dataset | Method | Threads | Variance setup s/fold | Fit + predict s/fold | Total s/fold | Peak process MiB |
|---|---|---:|---:|---:|---:|---:|
| Maize | Gaussian PCG | 4 | 20.6 | 12.7 | 33.3 | 1231 |
| Maize | D-weighted PCG | 4 | 18.4 | 11.7 | 30.1 | 1232 |
| Maize | Warm-start adaptive B | 4 | — | — | — | 1231 |
| Maize | BayesA MCMC | 1 | included in MCMC | — | — | — |

### Predictive performance

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/performance.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/maize/performance.svg?v=80c9caf4f579f40b" alt="Maize: Fold PCC dots and completed ten-fold means by method. Pending or failed aggregates are not assigned a score."></a><figcaption>Fold PCC dots and completed ten-fold means by method. Scroll on smaller screens or <a href="../assets/reports/training-variance/maize/performance.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Improvement over Gaussian

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/improvement.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/maize/improvement.svg?v=80c9caf4f579f40b" alt="Maize: Difference in mean PCC from the training-estimated Gaussian baseline. Pending or failed aggregates are not assigned a score."></a><figcaption>Difference in mean PCC from the training-estimated Gaussian baseline. Scroll on smaller screens or <a href="../assets/reports/training-variance/maize/improvement.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Performance and runtime

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/runtime.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/maize/runtime.svg?v=80c9caf4f579f40b" alt="Maize: Mean PCC against mean total seconds per fold, logarithmic runtime axis. Pending or failed aggregates are not assigned a score."></a><figcaption>Mean PCC against mean total seconds per fold, logarithmic runtime axis. Scroll on smaller screens or <a href="../assets/reports/training-variance/maize/runtime.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>

### Aggregate calibration

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/calibration.svg?v=80c9caf4f579f40b"><img src="../assets/reports/training-variance/maize/calibration.svg?v=80c9caf4f579f40b" alt="Maize: Binned pooled out-of-fold observed phenotype against prediction, with identity line. Pending or failed aggregates are not assigned a score."></a><figcaption>Binned pooled out-of-fold observed phenotype against prediction, with identity line. Scroll on smaller screens or <a href="../assets/reports/training-variance/maize/calibration.svg?v=80c9caf4f579f40b">open the full-size SVG</a>.</figcaption></figure>
