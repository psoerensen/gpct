---
layout: default
title: Maize prediction
---
# Maize / DTT

<!-- training-variance-comparison:start -->
<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}</style>
New training-variance fits are included below. All cost entries sum ten folds.
<!-- training-variance-comparison:end -->

Predict the supplied DTT phenotype within this GPBench cohort using existing gbayes methods. All fits and held-out predictions receive Glist.

1458 individuals; 75304 available markers; 75304 QC-retained markers. Synthetic BIM/FAM annotations are bookkeeping, not biological maps.

Saved GPBench ten-fold splits, seed 42. The MCMC collection uses four concurrent chains with one BLAS thread; the fixed Gaussian PCG reference used one worker. Actual workers are reported per method. Native model coding is preserved. See the [protocol](../protocol.html) and [settings](../methods.html).

| Method | Correlation | RMSE | Pooled predictive R² | Calibration slope | Status |
| --- | --- | --- | --- | --- | --- |
| Gaussian PCG (fixed h²=0.5) | 0.621 | 2.265 | 0.370 | 1.201 | Completed |
| BayesN / Bayesian ridge | 0.642 | 2.197 | 0.408 | 1.017 | Provisional (mixing) |
| BayesA MCMC | 0.648 | 2.184 | 0.415 | 1.012 | Provisional (mixing) |
| BayesB MCMC | 0.605 | 2.286 | 0.360 | 0.923 | Provisional (mixing) |
| BayesC MCMC | 0.631 | 2.226 | 0.393 | 0.954 | Provisional (mixing) |
| BayesR MCMC | 0.645 | 2.191 | 0.411 | 0.998 | Provisional (mixing) |
| Gaussian PCG (training variance) | 0.6423 | 2.1986 | 0.4076 | 0.9915 | Completed |
| D-weighted PCG (training variance) | 0.6507 | 2.1789 | 0.4183 | 0.9939 | Completed |

Correlation and RMSE in this table are means of ten fold metrics. Predictive R² and calibration slope are calculated from pooled out-of-fold predictions. Fold variation is descriptive; no independent-replicate confidence intervals are claimed.

## Computational cost

| Method | Workers | Fit s | Predict s | Total process s | Process peak MiB  Fit + predict s |
| --- | --- | --- | --- | --- | ---  --- |
| Gaussian PCG (fixed h²=0.5) | 1 | 100.1 | 12.7 | not available | 270  112.8 |
| BayesN / Bayesian ridge | 4 | 1433.1 | 7.7 | 1456.7 | 1063  1440.8 |
| BayesA MCMC | 4 | 1767.9 | 8.9 | 1795.1 | 1063  1776.8 |
| BayesB MCMC | 4 | 1454.8 | 8.6 | 1482.3 | 1063  1463.4 |
| BayesC MCMC | 4 | 1305.0 | 8.9 | 1343.9 | 1062  1313.9 |
| BayesR MCMC | 4 | 2899.1 | 8.0 | 2926.1 | 1070  2907.1 |
| Gaussian PCG (training variance) | 4 MKL threads | not separated | not separated | 366.6 | 1231 | 333.2 |
| D-weighted PCG (training variance) | 4 MKL threads | not separated | not separated | 335.0 | 1232 | 300.7 |

Shared training-Glist preparation across ten folds: 10.04 seconds. Fitting includes native genotype preparation; prediction is timed separately. Process peak RAM covers package loading, preparation, the folds executed in that process, saved outputs and prediction; it is not fit-only peak RAM. Cache state and resumed work may differ; see [process resource context](../assets/reports/gbayes-glist/process-resources.csv).

[Summary CSV](../assets/reports/gbayes-glist/maize/benchmark-results.csv) · [Fold metrics](../assets/reports/gbayes-glist/maize/fold-results.csv) · [Aggregate calibration](../assets/reports/gbayes-glist/maize/calibration-summary.csv)

## Predictive performance

[![Predictive performance](../assets/reports/gbayes-glist/maize/performance.svg?v=20261122T070620)](../assets/reports/gbayes-glist/maize/performance.svg?v=20261122T070620)

## Improvement over Gaussian

[![Difference from Gaussian PCG](../assets/reports/gbayes-glist/maize/improvement.svg?v=20261122T070620)](../assets/reports/gbayes-glist/maize/improvement.svg?v=20261122T070620)

## Performance and cost

[![Performance versus runtime](../assets/reports/gbayes-glist/maize/runtime.svg?v=20261122T070620)](../assets/reports/gbayes-glist/maize/runtime.svg?v=20261122T070620)

## Calibration

[![Aggregate calibration](../assets/reports/gbayes-glist/maize/calibration.svg?v=20261122T070620)](../assets/reports/gbayes-glist/maize/calibration.svg?v=20261122T070620)

Mean-imputed evaluation targets: 2 . Observed-target-only pooled correlations are provided in the summary CSV. No individual prediction plots or records are published.

## Diagnostics and reproduction

R fitting warnings: 0 . Separately, 41 MCMC fold fits have diagnostic flags. MCMC scores remain provisional if any fold has retained-parameter R-hat above 1.05, bulk ESS below 100, or unavailable diagnostics. Per-fold maxima/minima and status are in the downloadable metrics; these checks do not establish all-marker convergence. Native diagnostics and saved fits remain local.

Reproduction entry point for the retained local development checkout: this requires the identified unreleased native build and local benchmark controller. These implementation changes are not released by this aggregate website update.

```powershell
./environment/run-glist-benchmark-plan.ps1
```

This runs the matched threading/chain checks and the four-chain ten-fold collection on both panels. Use `-Methods bayesC_mcmc` to select one MCMC method. The fixed Gaussian reference is rebuilt if missing. Individual data and outputs use the external directories described in the repository. See the [method settings](../methods.html). [Back to all results](../results.html).
