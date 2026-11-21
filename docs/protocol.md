---
layout: default
title: Validation and evaluation
---
# Validation and evaluation

## Prediction target and partitions

Predict the supplied selected phenotype in source numeric units. This is
**predictive ability**, not accuracy relative to unobserved genetic merit.
Upstream phenotype preprocessing and trait units remain uncertain.

Remove only nonfinite selected outcomes before partitioning, retain source row
IDs, and save five balanced random folds using seed **4401**. R RNG settings
are Mersenne-Twister / Inversion / Rejection. Fold files live outside git and
are reused across every compared method. Sample-ID or ordering mismatches stop
execution. Each run also retains a fold copy and input checksum.

Random within-panel splits can share related individuals or environments and
are not estimates of deployment performance across families, ancestry or time.
Those targets require separately labelled designs with appropriate metadata.

## Training-only transformations

Within each fold, impute nonfinite genotype values with training marker means,
drop all-missing or training-constant markers, then center and divide by training
sample SD. Apply the same frozen transformation to test genotypes. Standardize
training outcomes using their own mean and sample SD. Only the training outcome
table reaches package fitting; test outcomes enter scoring after prediction.

Pilot penalties/prior scales are fixed in configs. There is no tuning on outer
test folds. Future covariate adjustment, QC selection or tuning must also be
learned using training data, with inner folds where needed. Source preprocessing
is undocumented and may already have used whole-cohort information.

All three methods return standardized phenotype predictions with an intercept.
Invert the training response scaling to compare methods in the same source units.
No method receives a test-set mean or SD. Test outcomes are not available to the
fitting call, although the local script must hold them for later evaluation.

## Metrics per held-out fold

Let y be test outcomes, p their predictions, and m the **training** outcome mean.

| Metric | Definition |
| --- | --- |
| Predictive ability | Pearson correlation cor(y,p); undefined if either vector is constant |
| RMSE | sqrt(mean((y-p)^2)), in supplied phenotype units |
| Predictive R-squared | 1 - sum((y-p)^2) / sum((y-m)^2); improvement over the training-mean predictor on these same test individuals |
| Calibration intercept | Intercept from test-only OLS y = a + b p + error |
| Calibration slope | Slope b from that diagnostic regression; ideal a=0 and b=1 |

Predictive R-squared can be negative and is not squared correlation. A zero
denominator gives NA. Constant predictions give NA correlation and calibration
coefficients; no constant is silently reported as a perfect score. Calibration
uses test outcomes only as a diagnostic and never recalibrates saved predictions.

## Records and publication

Save every individual out-of-fold prediction with ID/method/fold, every fold's
metrics and sample counts, wall times for fitting/prediction, raw available
diagnostics, settings, seeds, preprocessing, package versions and sessionInfo.
Package failure is explicit with NA metrics; a fatal stage writes failed run
status and a nonzero exit. Unknown convergence is labelled unavailable, never
assumed. rrBLUP does not expose a convergence flag through mixed.solve.

Do not publish incomplete-method averages as comparable results. Later summaries
should state all five fold values and any aggregation/uncertainty convention.
Pooled out-of-fold R-squared must use each individual's own training-fold mean
in its denominator; do not replace it with the full-cohort mean. Five folds are
not independent biological replicates. Compare methods with matched folds.

Only reviewed aggregate tables and figures may be copied to the site. Individual
predictions, folds, diagnostics with sample axes and source data stay local.
