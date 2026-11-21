---
layout: default
title: Benchmark recipes
---
# Benchmark recipes

Cattle/mkg and maize/DTT use the published GPBench regression scheme with all
source markers and ten folds. [Results](results.html) and detailed
[cattle](reports/cattle.html)/[maize](reports/maize.html) reports use the same
scientific structure while retaining distinct trait units and source limitations.

| Case | Rows evaluated | Markers | Missing target handling |
| --- | --- | --- | --- |
| Cattle / mkg | 5,024 | 42,551 | None missing |
| Maize / DTT | 1,458 | 75,304 | Two mean-imputed DTT targets flagged; observed-only sensitivity score |

These recipes benchmark genomic BLUP implemented in greml/gsolve, estimating
variance components by REML, and gbayes Gaussian/normal-mixture VB with fixed
training-only priors, plus GLMA Gaussian and prior-selected full-marker prediction.
All five use the same outer folds and supplied markers; GLMA applies its native
training-only SD scaling, constant-marker exclusion and RHE/MC variance and inner
selection procedure. These are prediction fits underlying its LOCO interfaces,
without chromosome exclusions or association scans. The gsolve fixed-variance
check is a separate numerical comparison, not another complete model fit.

## Reproduce locally

Build and activate the [pinned environment](https://github.com/psoerensen/gpct/tree/main/environment).
The private integration requires authorized access; implementation source and
binaries are not distributed with gpct. R uses OpenBLAS and the private native
integration uses its existing Intel MKL backend.

```powershell
./environment/activate.ps1
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
Rscript --vanilla environment/preflight.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla tests/check_interfaces.R
Rscript --vanilla tests/check_gbayes.R
Rscript --vanilla tests/check_glma_prediction.R
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
Rscript --vanilla scripts/check_solvers.R RUN_DIRECTORY
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

Preparation downloads and verifies the pinned archive unless GPCT_ARCHIVE points
to an existing copy. Full matrices require several GB RAM and external disk space.
No individual outputs are written inside the repository. Source-position IDs
acknowledge the unverified upstream row-order convention; equal array sizes do
not prove biological alignment.

The runner records folds, OOF predictions, imputed-target flags, metrics,
fit/prediction/kernel timing, settings, versions, recipe/input checksums,
diagnostics and explicit status. Inspect every fold before publication.
Random within-cohort CV does not establish transfer across families, herds,
environments or time. See the [protocol](protocol.html).
