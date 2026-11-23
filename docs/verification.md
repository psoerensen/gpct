---
layout: default
title: Verification record
---
# Verification record

The active benchmark collection uses Glist with four concurrent MCMC chains
and one BLAS thread; the fixed Gaussian PCG reference used one worker.
Ordinary RHE + BLUP uses an existing native estimator and solver through a
private Glist adapter, with up to four native MKL threads. All ten attempts
per dataset are recorded. Aggregate accuracy requires ten accepted folds;
failed fits and unavailable scores remain explicit.

Input checks cover exact NPZ-to-BED dosage round trips, explicit synthetic
BIM/FAM metadata, Glist validation, QC counts and source-order sample identity.
Saved outer folds are checked against the pinned sklearn/NumPy splitter and
checksum. Each fit must retain exactly the training sample IDs, requested
method/algorithm and the recorded actual native worker count. Predictions must identify every
held-out sample once. Deterministic fits must report native convergence.

Reporting checks require ten unique folds, one out-of-fold prediction per
individual for accepted complete methods, finite predictions, aggregate-only published files, valid internal
links and SVG assets. Fold means and pooled metrics are kept distinct. Method
settings, software versions, source pins and local diagnostics are retained.
The private RHE adapter passed independent dense moment-equation and GLS/held-out
prediction references, including missing genotypes and sample order. Cached
versus packed and one/four-thread comparisons passed on the reference case.
Native BLUP acceptance requires true relative residual at most 1e-8. An existing
negative-residual boundary failure is retained; no variance floor or acceptance
gate was loosened to accept the benchmark fits. Runtime sampling verified the
loaded native libraries against their recorded checksums and identified MKL 2026.2.0.

These checks establish the stated execution and reporting coverage, not a
complete R package release qualification or general scientific calibration.
MCMC mixing is assessed separately from transition completion. Original
biological IDs/maps, phenotype definitions and upstream processing remain
unverified. Random within-cohort CV does not establish transfer across families,
environments or time. See the [results](results.html) for current coverage.
