---
layout: default
title: One versus four workers
---
# One versus four workers

Matched short probes on saved fold 1: four identical seeded chains, each with 100 burn-in and 200 post-burn transitions. Only the maximum concurrent chain count changes. BLAS stays at one thread. These probes measure threading, and are separate from the ten-fold accuracy results.

| Dataset | Method | 1-worker fit s | 4-worker fit s | Fit speedup | Sampler speedup |
| --- | --- | --- | --- | --- | --- |
| cattle | BayesA MCMC | 159.5 | 64.4 | 2.48 | 2.54 |
| maize | BayesA MCMC | 98.0 | 36.7 | 2.67 | 2.73 |
| cattle | BayesB MCMC | 115.6 | 46.0 | 2.51 | 2.68 |
| maize | BayesB MCMC | 72.3 | 33.2 | 2.18 | 2.29 |
| cattle | BayesC MCMC | 93.2 | 46.6 | 2.00 | 2.23 |
| maize | BayesC MCMC | 59.5 | 25.6 | 2.32 | 2.46 |
| cattle | BayesN / Bayesian ridge | 137.4 | 63.9 | 2.15 | 2.22 |
| maize | BayesN / Bayesian ridge | 71.9 | 36.0 | 2.00 | 2.10 |
| cattle | BayesR MCMC | 183.4 | 66.5 | 2.76 | 2.84 |
| maize | BayesR MCMC | 239.6 | 56.1 | 4.27 | 4.39 |

Speedup is one-worker time divided by four-worker time. Fitting includes genotype/cache preparation; the sampler column isolates native sampling. Seeded effects and parameter traces must be identical. A changed cache admission state makes the speedup unavailable. Process peak RAM and all timings are in the [summary CSV](../assets/reports/gbayes-glist/thread-comparison.csv).

Four workers run independent chains concurrently; marker updates within each chain retain their existing order. These short probes do not establish convergence. The separate [chain-efficiency comparison](chain-efficiency.html) measures the effect of adding chains.

[Back to results](../results.html)
