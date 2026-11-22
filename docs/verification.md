---
layout: default
title: Verification record
---
# Verification record

The active benchmark collection uses existing gbayes Glist interfaces with
four concurrent MCMC chains and one BLAS thread; the fixed Gaussian PCG
reference used one worker. Only completed ten-fold methods
on both datasets are published as completed results.

Input checks cover exact NPZ-to-BED dosage round trips, explicit synthetic
BIM/FAM metadata, Glist validation, QC counts and source-order sample identity.
Saved outer folds are checked against the pinned sklearn/NumPy splitter and
checksum. Each fit must retain exactly the training sample IDs, requested
method/algorithm and the recorded actual native worker count. Predictions must identify every
held-out sample once. Deterministic fits must report native convergence.

Reporting checks require ten unique folds, one out-of-fold prediction per
individual, finite predictions, aggregate-only published files, valid internal
links and SVG assets. Fold means and pooled metrics are kept distinct. Method
settings, software versions, source pins and local diagnostics are retained.

These checks establish the stated execution and reporting coverage, not a
complete R package release qualification or general scientific calibration.
MCMC mixing is assessed separately from transition completion. Original
biological IDs/maps, phenotype definitions and upstream processing remain
unverified. Random within-cohort CV does not establish transfer across families,
environments or time. See the [results](results.html) for current coverage.
