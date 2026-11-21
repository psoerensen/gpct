---
layout: default
title: Results and timings
---
# Results and timings

Existing gbayes methods fitted directly from QC-selected Glist, with **one worker**. Results are added after a method finishes both datasets. The earlier experimental benchmark collection has been retired.

| Method | Algorithm | Status |
| --- | --- | --- |
| Gaussian PCG | pcg | Completed: cattle and maize, ten folds each |
| Elastic net | coordinate_descent | Queued |
| Laplace–Gaussian VB | vbayes | Queued |
| BayesC VB | vbayes | Queued |
| BayesC MCMC | mcmc | Queued |
| BayesR MCMC | mcmc | Queued |

[Cattle / mkg results](reports/cattle.html) · [Maize / DTT results](reports/maize.html)

[Combined summary CSV](assets/reports/gbayes-glist-1t/benchmark-results.csv) · [Fold metrics](assets/reports/gbayes-glist-1t/fold-results.csv) · [Method settings](assets/reports/gbayes-glist-1t/method-settings.csv)

Compare methods within each dataset and trait. Native model scaling, fixed versus learned variances, iteration settings and diagnostics are documented in the [methods](methods.html) and [protocol](protocol.html). Individual out-of-fold predictions stay local.
