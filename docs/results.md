---
layout: default
title: Results and timings
---
# Results and timings

<!-- training-variance-comparison:start -->
<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}.markdown-body a[href*="/combined-"][href*=".svg"]{display:block;max-width:100%;overflow-x:auto}.markdown-body img[src*="/combined-"]{width:100%;min-width:800px;max-width:none;height:auto}</style>
<!-- report-version:802595498d46594d -->
<!-- training-variance-comparison:end -->

Genomic prediction benchmarks using QC-selected Glist and the same saved ten-fold splits.

<!-- ranked-overview:start -->
<style>.ranked-figure{margin:1.5rem 0}.ranked-plots{max-width:100%;overflow-x:auto}.ranked-plots img{display:block;width:100%;min-width:960px;max-width:none;height:auto}</style>

<figure class="ranked-figure"><div class="ranked-plots"><a href="assets/reports/training-variance/cattle/ranked-overview.svg?v=08cf0e2fffb3"><img src="assets/reports/training-variance/cattle/ranked-overview.svg?v=08cf0e2fffb3" alt="Cattle / mkg: methods ranked by mean held-out PCC, highest first, and recorded peak process RAM, lowest first."></a></div><figcaption>Cattle / mkg · <a href="assets/reports/training-variance/cattle/ranked-overview.svg?v=08cf0e2fffb3">Open full-size figure</a></figcaption></figure>

<figure class="ranked-figure"><div class="ranked-plots"><a href="assets/reports/training-variance/maize/ranked-overview.svg?v=08cf0e2fffb3"><img src="assets/reports/training-variance/maize/ranked-overview.svg?v=08cf0e2fffb3" alt="Maize / DTT: methods ranked by mean held-out PCC, highest first, and recorded peak process RAM, lowest first."></a></div><figcaption>Maize / DTT · <a href="assets/reports/training-variance/maize/ranked-overview.svg?v=08cf0e2fffb3">Open full-size figure</a></figcaption></figure>

Dots show ten-fold mean PCC, without confidence intervals. * marks provisional MCMC diagnostics. Memory is recorded peak process RAM; worker and chain configurations differ. On narrow screens, scroll the figures horizontally.
<!-- ranked-overview:end -->

## Predictive performance

| Dataset | Method | Correlation | RMSE | Pooled predictive R² | Calibration slope | Status |
| --- | --- | --- | --- | --- | --- | --- |
| [Cattle / mkg](reports/cattle.html) | Gaussian PCG (fixed h²=0.5) | 0.767 | 0.650 | 0.577 | 1.160 | Completed |
| [Cattle / mkg](reports/cattle.html) | BayesN / Bayesian ridge | 0.777 | 0.628 | 0.605 | 1.002 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesA MCMC | 0.796 | 0.605 | 0.634 | 1.018 | Completed |
| [Cattle / mkg](reports/cattle.html) | BayesB MCMC | 0.762 | 0.647 | 0.581 | 0.979 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesC MCMC | 0.790 | 0.612 | 0.625 | 0.996 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | BayesR MCMC | 0.795 | 0.605 | 0.633 | 1.003 | Provisional (mixing) |
| [Cattle / mkg](reports/cattle.html) | Gaussian PCG (training variance) | 0.7772 | 0.6283 | 0.6048 | 1.0019 | Completed |
| [Cattle / mkg](reports/cattle.html) | D-weighted PCG (training variance) | 0.7808 | 0.6238 | 0.6104 | 1.0024 | Completed |
| [Cattle / mkg](reports/cattle.html) | BayesA MCMC (2 chains, 1 worker) | 0.7958 | 0.6048 | 0.6337 | 1.0178 | Provisional: mixing warnings in 1/10 folds |
| [Cattle / mkg](reports/cattle.html) | GLMA Gaussian / infinitesimal | 0.7744 | 0.6362 | 0.5949 | 1.0954 | Completed |
| [Cattle / mkg](reports/cattle.html) | GLMA prior-selected | 0.7700 | 0.6404 | 0.5895 | 1.0781 | Completed |
| [Maize / DTT](reports/maize.html) | Gaussian PCG (fixed h²=0.5) | 0.621 | 2.265 | 0.370 | 1.201 | Completed |
| [Maize / DTT](reports/maize.html) | BayesN / Bayesian ridge | 0.642 | 2.197 | 0.408 | 1.017 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesA MCMC | 0.648 | 2.184 | 0.415 | 1.012 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesB MCMC | 0.605 | 2.286 | 0.360 | 0.923 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesC MCMC | 0.631 | 2.226 | 0.393 | 0.954 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | BayesR MCMC | 0.645 | 2.191 | 0.411 | 0.998 | Provisional (mixing) |
| [Maize / DTT](reports/maize.html) | Gaussian PCG (training variance) | 0.6423 | 2.1986 | 0.4076 | 0.9915 | Completed |
| [Maize / DTT](reports/maize.html) | D-weighted PCG (training variance) | 0.6507 | 2.1789 | 0.4183 | 0.9939 | Completed |
| [Maize / DTT](reports/maize.html) | BayesA MCMC (2 chains, 1 worker) | 0.6492 | 2.1829 | 0.4162 | 1.0135 | Provisional: mixing warnings in 9/10 folds |
| [Maize / DTT](reports/maize.html) | GLMA Gaussian / infinitesimal | 0.6181 | 2.2758 | 0.3648 | 1.2090 | Completed |
| [Maize / DTT](reports/maize.html) | GLMA prior-selected | 0.5995 | 2.3029 | 0.3498 | 1.1631 | Completed |

Correlation and RMSE are means of ten held-out folds. Predictive R² and calibration slope use pooled out-of-fold predictions. Compare methods within each dataset and trait. MCMC rows are provisional when retained parameter R-hat exceeds 1.05 or bulk ESS is below 100; completing iterations does not establish convergence.

## Computational cost

| Dataset | Method | Workers | Fit seconds | Predict seconds | Total process seconds | Fit + predict seconds | Process peak MiB |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cattle / mkg | Gaussian PCG (fixed h²=0.5) | 1 | 197.6 | 14.5 | not available | 212.1 | 1725 |
| Cattle / mkg | BayesN / Bayesian ridge | 4 | 2819.9 | 12.3 | 2844.5 | 2832.1 | 1728 |
| Cattle / mkg | BayesA MCMC | 4 | 3134.6 | 13.4 | 3161.6 | 3148.1 | 1727 |
| Cattle / mkg | BayesB MCMC | 4 | 2315.3 | 14.3 | 2343.3 | 2329.6 | 1727 |
| Cattle / mkg | BayesC MCMC | 4 | 2081.3 | 13.0 | 2120.6 | 2094.3 | 1726 |
| Cattle / mkg | BayesR MCMC | 4 | 3340.9 | 10.9 | 3364.8 | 3351.8 | 1732 |
| Cattle / mkg | Gaussian PCG (training variance) | 4 MKL threads | not separated | not separated | 625.4 | 600.7 | 2364 |
| Cattle / mkg | D-weighted PCG (training variance) | 4 MKL threads | not separated | not separated | 621.3 | 599.1 | 2364 |
| Cattle / mkg | BayesA MCMC (2 chains, 1 worker) | 1 worker / 2 chains | not separated | not separated | 4325.1 | 4311.7 | 1727 |
| Cattle / mkg | GLMA Gaussian / infinitesimal | 4 MKL threads | not separated | not separated | 285.5 | 275.6 | 1776 |
| Cattle / mkg | GLMA prior-selected | 4 MKL threads | not separated | not separated | 311.7 | 301.8 | 1861 |
| Maize / DTT | Gaussian PCG (fixed h²=0.5) | 1 | 100.1 | 12.7 | not available | 112.9 | 270 |
| Maize / DTT | BayesN / Bayesian ridge | 4 | 1433.1 | 7.7 | 1456.7 | 1440.8 | 1063 |
| Maize / DTT | BayesA MCMC | 4 | 1767.9 | 8.9 | 1795.1 | 1776.8 | 1063 |
| Maize / DTT | BayesB MCMC | 4 | 1454.8 | 8.6 | 1482.3 | 1463.4 | 1063 |
| Maize / DTT | BayesC MCMC | 4 | 1305.0 | 8.9 | 1343.9 | 1313.9 | 1062 |
| Maize / DTT | BayesR MCMC | 4 | 2899.1 | 8.0 | 2926.1 | 2907.1 | 1070 |
| Maize / DTT | Gaussian PCG (training variance) | 4 MKL threads | not separated | not separated | 366.6 | 333.2 | 1231 |
| Maize / DTT | D-weighted PCG (training variance) | 4 MKL threads | not separated | not separated | 335.0 | 300.7 | 1232 |
| Maize / DTT | BayesA MCMC (2 chains, 1 worker) | 1 worker / 2 chains | not separated | not separated | 2730.9 | 2714.3 | 1005 |
| Maize / DTT | GLMA Gaussian / infinitesimal | 4 MKL threads | not separated | not separated | 138.0 | 124.4 | 1089 |
| Maize / DTT | GLMA prior-selected | 4 MKL threads | not separated | not separated | 149.0 | 137.5 | 1283 |

Times sum all ten folds; divide by ten for seconds per fold. “Not separated” means only the combined fitting/prediction stage was timed. Peak RAM is the maximum across recorded processes.

New training-variance rows use the same ten-fold splits, with training-only phenotype imputation; the two missing maize test outcomes are excluded. PCG totals include variance estimation. The new BayesA run uses two sequential chains; the original MCMC rows use four concurrent chains.
