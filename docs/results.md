---
layout: default
title: Results and timings
---
# Results and timings

Native gbayes methods fitted directly from QC-selected Glist. MCMC runs use four concurrent chains and one BLAS thread; the fixed Gaussian PCG reference used one worker. Results are added after a method finishes both datasets.

## Predictive performance

| Dataset | Method | Correlation | RMSE | Pooled predictive R² | Calibration slope | Status |
| --- | --- | --- | --- | --- | --- | --- |
| [Cattle / mkg](reports/cattle.html) | Gaussian PCG | 0.767 | 0.650 | 0.577 | 1.160 | Completed |
| [Cattle / mkg](reports/cattle.html) | BayesN / Bayesian ridge | 0.777 | 0.628 | 0.605 | 1.002 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesA MCMC | 0.796 | 0.605 | 0.634 | 1.018 | Completed |
| [Cattle / mkg](reports/cattle.html) | BayesB MCMC | 0.762 | 0.647 | 0.581 | 0.979 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesC MCMC | 0.790 | 0.612 | 0.625 | 0.996 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesR MCMC | 0.795 | 0.605 | 0.633 | 1.003 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | Gaussian PCG | 0.621 | 2.265 | 0.370 | 1.201 | Completed |
| [Maize / DTT](reports/maize.html) | BayesN / Bayesian ridge | 0.642 | 2.197 | 0.408 | 1.017 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesA MCMC | 0.648 | 2.184 | 0.415 | 1.012 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesB MCMC | 0.605 | 2.286 | 0.360 | 0.923 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesC MCMC | 0.631 | 2.226 | 0.393 | 0.954 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesR MCMC | 0.645 | 2.191 | 0.411 | 0.998 | Provisional (mixing) |

Correlation and RMSE are means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Compare methods within each dataset and trait. MCMC rows are provisional when retained parameter R-hat exceeds 1.05 or bulk ESS is below 100; completing iterations does not establish convergence.

## Computational cost

| Dataset | Method | Workers | Fit seconds | Predict seconds | Total process seconds | Fit + predict seconds | Process peak MiB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cattle / mkg | Gaussian PCG | 1 | 197.6 | 14.5 | not available | 212.1 | 1725 |
| Cattle / mkg | BayesN / Bayesian ridge | 4 | 2819.9 | 12.3 | 2844.5 | 2832.1 | 1728 |
| Cattle / mkg | BayesA MCMC | 4 | 3134.6 | 13.4 | 3161.6 | 3148.1 | 1727 |
| Cattle / mkg | BayesB MCMC | 4 | 2315.3 | 14.3 | 2343.3 | 2329.6 | 1727 |
| Cattle / mkg | BayesC MCMC | 4 | 2081.3 | 13.0 | 2120.6 | 2094.3 | 1726 |
| Cattle / mkg | BayesR MCMC | 4 | 3340.9 | 10.9 | 3364.8 | 3351.8 | 1732 |
| Maize / DTT | Gaussian PCG | 1 | 100.1 | 12.7 | not available | 112.9 | 270 |
| Maize / DTT | BayesN / Bayesian ridge | 4 | 1433.1 | 7.7 | 1456.7 | 1440.8 | 1063 |
| Maize / DTT | BayesA MCMC | 4 | 1767.9 | 8.9 | 1795.1 | 1776.8 | 1063 |
| Maize / DTT | BayesB MCMC | 4 | 1454.8 | 8.6 | 1482.3 | 1463.4 | 1063 |
| Maize / DTT | BayesC MCMC | 4 | 1305.0 | 8.9 | 1343.9 | 1313.9 | 1062 |
| Maize / DTT | BayesR MCMC | 4 | 2899.1 | 8.0 | 2926.1 | 2907.1 | 1070 |

Fit and prediction times sum all ten folds. Total process time includes loading, preparation, fitting, saving and prediction across recorded process segments; unsuccessful attempts, if any, are included and recorded in the resource context. Unavailable measurements remain explicit. Fitting includes native genotype/cache preparation; shared Glist preparation is reported separately. Peak RAM spans the recorded R processes. Cache state and resumed work can differ; [process resource context](assets/reports/gbayes-glist/process-resources.csv) preserves available details.

## Method progress

| Method | Algorithm | Status |
| --- | --- | --- |
| Gaussian PCG | pcg | Completed: cattle and maize, ten folds each |
| BayesN / Bayesian ridge | mcmc | Completed: cattle and maize, ten folds each |
| BayesA MCMC | mcmc | Completed: cattle and maize, ten folds each |
| BayesB MCMC | mcmc | Completed: cattle and maize, ten folds each |
| BayesC MCMC | mcmc | Completed: cattle and maize, ten folds each |
| BayesR MCMC | mcmc | Completed: cattle and maize, ten folds each |

[Cattle / mkg results](reports/cattle.html) · [Maize / DTT results](reports/maize.html)

[Combined summary CSV](assets/reports/gbayes-glist/benchmark-results.csv) · [Fold metrics](assets/reports/gbayes-glist/fold-results.csv) · [Method settings](assets/reports/gbayes-glist/method-settings.csv) · [Run status and failure messages](assets/reports/gbayes-glist/method-status.csv)

Compare methods within each dataset and trait. Native model scaling, fixed versus learned variances, iteration settings and diagnostics are documented in the [methods](methods.html) and [protocol](protocol.html). Individual out-of-fold predictions stay local.

[One versus four workers](reports/threading.html) · [Two versus four chains and ESS per second](reports/chain-efficiency.html)
