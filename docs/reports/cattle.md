---
layout: default
title: Cattle prediction
---
# Cattle / mkg

<!-- training-variance-comparison:start -->
<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}.markdown-body a[href*="/combined-"][href*=".svg"]{display:block;max-width:100%;overflow-x:auto}.markdown-body img[src*="/combined-"]{width:100%;min-width:800px;max-width:none;height:auto}</style>
New training-variance fits are included below. All cost entries sum ten folds.
<!-- training-variance-comparison:end -->

Predict the supplied mkg phenotype within this GPBench cohort using native gsuite methods. All fits and held-out predictions receive Glist.

5024 individuals; 42551 available markers; 42373 QC-retained markers. Synthetic BIM/FAM annotations are bookkeeping, not biological maps.

The MCMC collection uses four concurrent chains with one BLAS thread; the fixed Gaussian PCG reference used one worker. Actual workers are reported per method. Native model coding is preserved. See the [protocol](../protocol.html) and [settings](../methods.html).

| Method | Correlation | RMSE | Pooled predictive R² | Calibration slope | Status |
| --- | --- | --- | --- | --- | --- |
| Gaussian PCG (fixed h²=0.5) | 0.767 | 0.650 | 0.577 | 1.160 | Completed |
| BayesN / Bayesian ridge | 0.777 | 0.628 | 0.605 | 1.002 | Provisional (mixing) |
| BayesA MCMC | 0.796 | 0.605 | 0.634 | 1.018 | Completed |
| BayesB MCMC | 0.762 | 0.647 | 0.581 | 0.979 | Provisional (mixing) |
| BayesC MCMC | 0.790 | 0.612 | 0.625 | 0.996 | Provisional (mixing) |
| BayesR MCMC | 0.795 | 0.605 | 0.633 | 1.003 | Provisional (mixing) |
| RHE + BLUP | not available | not available | not available | not available | Failed: 0/10 folds accepted |
| Gaussian PCG (training variance) | 0.7772 | 0.6283 | 0.6048 | 1.0019 | Completed |
| D-weighted PCG (training variance) | 0.7808 | 0.6238 | 0.6104 | 1.0024 | Completed |
| BayesA MCMC (2 chains, 1 worker) | 0.7958 | 0.6048 | 0.6337 | 1.0178 | Provisional: mixing warnings in 1/10 folds |
| GLMA Gaussian / infinitesimal | 0.7744 | 0.6362 | 0.5949 | 1.0954 | Completed |
| GLMA prior-selected | 0.7700 | 0.6404 | 0.5895 | 1.0781 | Completed |

Correlation and RMSE in this table are means of ten fold metrics. Predictive R² and calibration slope are calculated from pooled out-of-fold predictions. Fold variation is descriptive; no independent-replicate confidence intervals are claimed.

## Computational cost

| Method | Workers | Fit s | Predict s | Total process s | Process peak MiB | Fit + predict s |
| --- | --- | --- | --- | --- | --- | --- |
| Gaussian PCG (fixed h²=0.5) | 1 | 197.6 | 14.5 | not available | 1725 | 212.1 |
| BayesN / Bayesian ridge | 4 | 2819.9 | 12.3 | 2844.5 | 1728 | 2832.2 |
| BayesA MCMC | 4 | 3134.6 | 13.4 | 3161.6 | 1727 | 3148.0 |
| BayesB MCMC | 4 | 2315.3 | 14.3 | 2343.3 | 1727 | 2329.6 |
| BayesC MCMC | 4 | 2081.3 | 13.0 | 2120.6 | 1726 | 2094.3 |
| BayesR MCMC | 4 | 3340.9 | 10.9 | 3364.8 | 1732 | 3351.8 |
| RHE + BLUP | 4 | 913.9 | not available | 915.4 | 1705 | not available |
| Gaussian PCG (training variance) | 4 MKL threads | not separated | not separated | 625.4 | 2364 | 600.7 |
| D-weighted PCG (training variance) | 4 MKL threads | not separated | not separated | 621.3 | 2364 | 599.1 |
| BayesA MCMC (2 chains, 1 worker) | 1 worker / 2 chains | not separated | not separated | 4325.1 | 1727 | 4311.7 |
| GLMA Gaussian / infinitesimal | 4 MKL threads | not separated | not separated | 285.5 | 1776 | 275.6 |
| GLMA prior-selected | 4 MKL threads | not separated | not separated | 311.7 | 1861 | 301.8 |

Shared training-Glist preparation across ten folds: 12.52 seconds. Fitting includes native genotype preparation; prediction is timed separately. Process peak RAM covers package loading, preparation, the folds executed in that process, saved outputs and prediction; it is not fit-only peak RAM. Cache state and resumed work may differ; see [process resource context](../assets/reports/gbayes-glist/process-resources.csv).

[Summary CSV](../assets/reports/training-variance/cattle/combined-summary.csv?v=802595498d46594d) · [Fold metrics](../assets/reports/training-variance/cattle/combined-fold-results.csv?v=802595498d46594d) · [Aggregate calibration](../assets/reports/training-variance/cattle/combined-calibration.csv?v=802595498d46594d)

## Predictive performance

[![Predictive performance](../assets/reports/training-variance/cattle/combined-performance.svg?v=802595498d46594d)](../assets/reports/training-variance/cattle/combined-performance.svg?v=802595498d46594d)

## Improvement over Gaussian

[![Difference from Gaussian PCG](../assets/reports/training-variance/cattle/combined-improvement.svg?v=802595498d46594d)](../assets/reports/training-variance/cattle/combined-improvement.svg?v=802595498d46594d)

## Performance and cost

[![Performance versus runtime](../assets/reports/training-variance/cattle/combined-runtime.svg?v=802595498d46594d)](../assets/reports/training-variance/cattle/combined-runtime.svg?v=802595498d46594d)

## Calibration

[![Aggregate calibration](../assets/reports/training-variance/cattle/combined-calibration.svg?v=802595498d46594d)](../assets/reports/training-variance/cattle/combined-calibration.svg?v=802595498d46594d)

Mean-imputed evaluation targets: 0 . Observed-target-only pooled correlations are provided in the summary CSV. No individual prediction plots or records are published.

## Diagnostics and reproduction

R fitting warnings: 0 . Separately, 39 MCMC fold fits have diagnostic flags. MCMC scores remain provisional if any fold has retained-parameter R-hat above 1.05, bulk ESS below 100, or unavailable diagnostics. Per-fold maxima/minima and status are in the downloadable metrics; these checks do not establish all-marker convergence. Native diagnostics and saved fits remain local.

RHE + BLUP uses up to four native MKL threads for one fit, rather than four chains. Any failed fold suppresses its ten-fold accuracy and calibration summaries. Timings retain failed fitting attempts. See the [RHE evaluation and variance diagnostics](rhe-blup.html).

Reproduction entry point for the retained local development checkout: this requires the identified unreleased native build and local benchmark controller. These implementation changes are not released by this aggregate website update.

```powershell
./environment/run-glist-benchmark-plan.ps1
```

This runs the matched threading/chain checks and the four-chain ten-fold collection on both panels. Use `-Methods bayesC_mcmc` to select one MCMC method. The fixed Gaussian reference is rebuilt if missing. Individual data and outputs use the external directories described in the repository. See the [method settings](../methods.html). [Back to all results](../results.html).
