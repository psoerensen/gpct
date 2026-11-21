---
layout: default
title: Results and timings
---
# Results and timings

Existing gbayes methods fitted directly from QC-selected Glist, with **one worker**. Results are added after a method finishes both datasets. The earlier experimental benchmark collection has been retired.

## Predictive performance

| Dataset | Method | Correlation | RMSE | Pooled predictive R² | Calibration slope |
| --- | --- | --- | --- | --- | --- |
| [Cattle / mkg](reports/cattle.html) | Gaussian PCG | 0.767 | 0.650 | 0.577 | 1.160 |
| [Maize / DTT](reports/maize.html) | Gaussian PCG | 0.621 | 2.265 | 0.370 | 1.201 |

Correlation and RMSE are means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Compare methods within each dataset and trait.

## Computational cost

| Dataset | Method | Fit seconds | Predict seconds | Fit + predict seconds | Process peak MiB |
| --- | --- | --- | --- | --- | --- |
| Cattle / mkg | Gaussian PCG | 197.6 | 14.5 | 212.1 | 1725 |
| Maize / DTT | Gaussian PCG | 100.1 | 12.7 | 112.9 | 270 |

Times sum all ten folds. Fitting includes native genotype preparation; shared Glist preparation is reported separately in the detailed reports. Process peak RAM includes loading, preparation, output and prediction, rather than fitting alone.

## Method progress

| Method | Algorithm | Status |
| --- | --- | --- |
| Gaussian PCG | pcg | Completed: cattle and maize, ten folds each |
| Elastic net | coordinate_descent | Checkpoint failed: maize; other runs not launched |
| Laplace–Gaussian VB | vbayes | Running: maize |
| BayesC VB | vbayes | Queued |
| BayesC MCMC | mcmc | Queued |
| BayesR MCMC | mcmc | Queued |

[Cattle / mkg results](reports/cattle.html) · [Maize / DTT results](reports/maize.html)

[Combined summary CSV](assets/reports/gbayes-glist-1t/benchmark-results.csv) · [Fold metrics](assets/reports/gbayes-glist-1t/fold-results.csv) · [Method settings](assets/reports/gbayes-glist-1t/method-settings.csv) · [Run status and failure messages](assets/reports/gbayes-glist-1t/method-status.csv)

Compare methods within each dataset and trait. Native model scaling, fixed versus learned variances, iteration settings and diagnostics are documented in the [methods](methods.html) and [protocol](protocol.html). Individual out-of-fold predictions stay local.
