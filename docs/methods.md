---
layout: default
title: Methods
---
# Methods

<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}.markdown-body a[href*="/combined-"][href*=".svg"]{display:block;max-width:100%;overflow-x:auto}.markdown-body img[src*="/combined-"]{width:100%;min-width:800px;max-width:none;height:auto}</style>

All methods use QC-selected Glist inputs and the same saved cross-validation folds.

| Method | Fitting | Marker weights or shrinkage | Variance estimation | Threads / chains |
|---|---|---|---|---|
| Gaussian PCG (fixed h²=0.5) | gbayes PCG / BLUP | Equal weights | Fixed variance ratio | 1 worker |
| Gaussian PCG (training variance) | greml/gsolve PCG / BLUP | Equal weights | Training-only Monte Carlo REML | 4 MKL threads |
| D-weighted PCG | greml/gsolve PCG / BLUP | Fixed weights: [2p(1−p)]^0.75 | Training-only estimate for the weighted kernel | 4 MKL threads |
| Adaptive B | greml/gsolve warm-start PCG | Learned two-Gaussian mixture weights; non-MCMC | Initial training estimates stay fixed | 4 MKL threads |
| BayesN / Bayesian ridge | gbayes MCMC | Shared Gaussian shrinkage | Learns shared marker and residual variances | 4 concurrent chains |
| BayesA | gbayes MCMC | Marker-specific variances | Learns marker and residual variances | Original: 4 concurrent chains; new run: 2 sequential chains, 1 worker |
| BayesB | gbayes MCMC | Spike at zero plus marker-specific variances | Learns active probability and variances | 4 concurrent chains |
| BayesC | gbayes MCMC | Spike at zero plus a shared active-marker variance | Learns active probability and variances | 4 concurrent chains |
| BayesR | gbayes MCMC | Several marker-variance classes | Learns variance scale and mixture weights | 4 concurrent chains |
| GLMA Gaussian / infinitesimal | glma full-marker fit; gsolve PCG final solve | Existing empirical marker scaling | Existing training RHE and Monte Carlo grid workflow | 4 requested MKL threads |
| GLMA prior-selected | glma/gbayes variational full-marker fit | Existing frequency weighting and ridge/elastic prior selection within training data | Existing training RHE and Monte Carlo grid workflow | 4 product threads; parallel candidate models |

MCMC uses one BLAS thread per chain. Threads within one fit and independent chains are different forms of parallelism. Completed accuracy and timing measurements appear on the Results page.
