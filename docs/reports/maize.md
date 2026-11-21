---
layout: default
title: Maize prediction
---
# Maize / DTT

Predict the supplied DTT phenotype within this GPBench cohort using existing gbayes methods. All fits and held-out predictions receive Glist.

1458 individuals; 75304 available markers; 75304 QC-retained markers. Synthetic BIM/FAM annotations are bookkeeping, not biological maps.

Saved GPBench ten-fold splits, seed 42; one native worker and one BLAS/OpenMP thread. Native method-specific coding is preserved. See the [protocol](../protocol.html) and [settings](../methods.html).

| Method | Correlation | RMSE | Pooled predictive R² | Calibration slope | Fit s | Predict s | Process peak MiB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gaussian PCG | 0.621 | 2.265 | 0.370 | 1.201 | 100.1 | 12.7 | 270 |

Correlation and RMSE in this table are means of ten fold metrics. Predictive R² and calibration slope are calculated from pooled out-of-fold predictions. Fold variation is descriptive; no independent-replicate confidence intervals are claimed.

Shared training-Glist preparation across ten folds: 10.04 seconds. Fitting includes native genotype preparation; prediction is timed separately. Process peak RAM covers package loading, preparation, all folds, saved outputs and prediction; it is not fit-only peak RAM.

[Summary CSV](../assets/reports/gbayes-glist-1t/maize/benchmark-results.csv) · [Fold metrics](../assets/reports/gbayes-glist-1t/maize/fold-results.csv) · [Aggregate calibration](../assets/reports/gbayes-glist-1t/maize/calibration-summary.csv)

## Predictive performance

![Predictive performance](../assets/reports/gbayes-glist-1t/maize/performance.svg)

## Improvement over Gaussian

![Difference from Gaussian PCG](../assets/reports/gbayes-glist-1t/maize/improvement.svg)

## Performance and cost

![Performance versus runtime](../assets/reports/gbayes-glist-1t/maize/runtime.svg)

## Calibration

![Aggregate calibration](../assets/reports/gbayes-glist-1t/maize/calibration.svg)

Mean-imputed evaluation targets: 2 . Observed-target-only pooled correlations are provided in the summary CSV. No individual prediction plots or records are published.

## Diagnostics and reproduction

Warnings across published fits: 0 . Convergence status is retained per fold in the downloadable metrics. Native diagnostics and saved fits remain local.

```powershell
./environment/activate.ps1 -BlasThreads 1
Rscript --vanilla scripts/run_gbayes.R marker_gaussian maize
```

Replace the method ID with another listed in the [method settings](../methods.html). Individual data and outputs must use the external directories described in the repository. [Back to all results](../results.html).
