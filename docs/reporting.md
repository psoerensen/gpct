---
layout: default
title: Reporting contract
---
# Reporting contract

`scripts/publish_gbayes.R` reads local gbayes Glist runs and publishes only
aggregate summaries after a method completes ten folds on both datasets.

| File | Contents |
| --- | --- |
| benchmark-results.csv | Fold means and SDs, labelled pooled metrics, timings and process RAM |
| fold-results.csv | Metrics, marker counts, native worker count and diagnostics for each fold |
| calibration-summary.csv | Reviewed prediction-bin counts and mean predicted/observed outcomes |
| method-settings.csv | Existing gbayes method/algorithm selectors and frozen settings |
| performance.svg | Predictive correlation by method, including descriptive fold variation |
| improvement.svg | Paired fold correlation difference from Gaussian PCG |
| runtime.svg | Predictive correlation versus total fit and held-out prediction time |
| calibration.svg | Aggregate calibration bins and identity line |

Compare each dataset/trait separately. Distinguish pooled out-of-fold metrics
from mean fold metrics. Do not treat folds as independent experimental
replicates. Source IDs, individual outcomes/predictions, saved fits, allele
tables and raw logs are never website artifacts. Failed fits and incomplete
MCMC diagnostics are shown explicitly rather than silently omitted.
