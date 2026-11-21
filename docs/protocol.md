---
layout: default
title: Evaluation protocol
---
# Evaluation protocol

<figure class="workflow-figure"><a href="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}"><img src="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}" width="1120" height="620" alt="All cattle and maize markers enter the same GPBench ten-fold splits with seed 42. Our greml/gsolve and gbayes models fit training data, predict held-out targets, and report aggregate performance and costs. Imputed phenotype targets are flagged and private numerical implementations remain external."></a><figcaption>Matched full-marker validation, REML and fixed-prior VB workflows, and separate fixed-variance solver checks. GPBench phenotype imputation is explicitly flagged.</figcaption></figure>

[Open the full-size workflow SVG]({{ '/assets/images/benchmark-workflow.svg' | relative_url }}).

## Match the published regression scheme

The data and validation reference is the authors' [GPBench regression script](https://github.com/xwzhang2118/GPBench/blob/2c92073fb8c67e6d6c5c1cda8bd410f191c7ef02/method_reg/rrBLUP/rrBLUP.py).
Its external fitter is not executed. Model fitting uses our gsuite interfaces.
Use all rows in source order and all 42,551 cattle or 75,304 maize markers.
Pass the stored genotype dosages directly: no SNP filtering, empirical-SD scaling,
allele recoding, or outcome-based feature selection. Original marker annotations
and sample identifiers are absent, so source-position surrogates are labelled.

Generate the actual sklearn.model_selection.KFold(n_splits=10, shuffle=True,
random_state=42) partitions with scikit-learn 1.6.1 and NumPy 1.26.4. Every method
uses those same saved partitions. Train/test rows remain in source order.
R's random-number generator is not substituted for the Python splitter.

GLMA full-marker prediction uses those same outer folds and input dosage columns,
with its native training-only empirical SD standardization. Constant training
columns have zero effects and are counted separately. Its Gaussian and ten-prior
joint fits estimate variance by blocked RHE/Monte Carlo refinement and use an
internal training-fold validation split. They do not perform chromosome exclusions
or association scans. These preprocessing and fitting differences are declared
model choices; the comparison is not a test of interchangeable solvers.

## Phenotype handling

The upstream code replaces missing phenotypes with their whole-dataset mean
before cross-validation. Matching this rule retains all 1,458 maize rows,
including two mean-imputed DTT targets. Cattle mkg has no missing values.
Imputed targets are flagged locally and counted publicly; an observed-target-only
sensitivity score excludes them from evaluation, while retaining the same fits.
That sensitivity score does not remove the upstream imputation rule from training.

Whole-dataset phenotype imputation can use held-out information. We reproduce
it transparently for the source comparison; it is not a recommended validation
rule for a new scientific analysis. No further test responses enter REML fitting
or tuning. No test-fold hyperparameter tuning is performed.

## Genomic BLUP in gsuite

We fit y = intercept + g + e through greml, with covariance K = Z Z' / p,
where p is the
full marker count. Its genetic variance parameter equals p times marker-effect
variance. The held-out BLUP uses the corresponding train/target cross-covariance.
The existing private gsolve engine supplies numerical operations.

gbayes Gaussian VB and sparse normal-mixture VB use the existing streamed
normal-mixture interface on the same raw training markers and saved folds.
Native projection handles an intercept without marker SD normalization. Working
h2=0.5 fixes residual variance to half the training phenotype variance; the other
half divided by the sum of training marker variances sets average effect variance.
The mixture fixes nonzero probability at 0.1 and divides its nonzero variance by
that probability. All calculations use training rows only. These fixed-prior
variational fits are compared with REML as distinct models and fitting tasks.

A separate fixed-variance gsolve check uses our greml variance estimates and
recomputes the GLS intercept. Prediction differences and solve time are reported separately. It
does not estimate variances and is not ranked as a complete competing REML fit.

## Metrics and aggregation

For each test fold, calculate Pearson correlation, MAE, MSE, RMSE and predictive
R2 = 1 - sum((observed - predicted)^2) / sum((observed - test_fold_mean)^2).
This R2 reference matches sklearn.metrics.r2_score. It is not squared correlation.
Calibration is the intercept and slope of observed phenotype regressed on prediction.

The main score is the arithmetic mean of ten fold scores, matching GPBench.
The descriptive standard deviation of correlations uses NumPy's ddof=0 convention.
Pooled out-of-fold metrics are provided separately; they are not silently substituted
for fold means. Fold variation is descriptive. Folds are not independent experimental
replicates, and no confidence intervals are implied. Compare methods within each
dataset/trait; raw RMSE values across traits have different units.

## Computational costs and disclosure

Record fit, prediction, reusable kernel preparation, method elapsed and total case
time separately. Complete-workflow timing includes the greml/gsolve kernel build
and fold block preparation once, plus all ten fits and predictions. Kernel preparation
uses genotypes only.
gbayes workflow timing includes training/target matrix extraction, training-prior
calculation, native projection, fitting and prediction. The reviewed greml/gsolve
measurements are retained alongside a new gbayes batch on the same hardware and
optimized runtime. Input hashes, saved folds, outcomes and imputed-target flags
must match before combining; run IDs distinguish the executions.
Whole-case time includes input loading and saving. Reporting and fixed-variance
solver checks run separately after the benchmark. Timings are one execution on the
recorded hardware, not measurements of the authors' computing environment.

Loaded BLAS versions, thread settings and binary hashes are recorded. Runtime
thread settings do not measure CPU utilization. Peak RAM is explicitly unmeasured.
Keep failed fits, warnings, nonconvergence and missing measurements visible.
Only reviewed aggregate CSVs, calibration bins and SVGs are published. Private
numerical source, binaries, individual predictions, fold assignments and raw
fit objects remain external.
