---
layout: default
title: Benchmark recipes
---
# Benchmark recipes

Both cases are **planned**, with recipe source prepared and execution in R
pending. Neither has been validated by a successful package run.

| Case | Question | Eligibility | Scope |
| --- | --- | --- | --- |
| Cattle/mkg | Predict supplied mkg within cohort | 5,024 finite outcomes | 512-marker pilot |
| Maize/DTT | Predict supplied DTT within panel | 1,456 finite outcomes; two excluded | 512-marker pilot |

These targets use supplied numeric units. Biological definitions, preprocessing
and units need original-source confirmation. Random splits do not evaluate
family, herd, environment or temporal transfer.

## Reproduce locally

Use an existing R installation and package environment. Preparation needs digest,
reticulate and an existing Python with NumPy. Prediction needs rrBLUP and a
compatible gbayes exposing the inspected prepared-design interface. Scripts
report missing dependencies and install nothing. Read [interface limits](methods.html).

From the repository root, in PowerShell:

```powershell
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
# $env:RETICULATE_PYTHON = 'C:/path/to/python.exe'
Rscript --vanilla scripts/check_dependencies.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
```

`GPCT_ACCEPT_POSITIONAL_IDS=yes` acknowledges the unverified upstream row-order
contract; read [data limitations](datasets.html) first. Data/output paths must
be outside the repository. Preparation downloads the pinned archive unless
`GPCT_ARCHIVE` points to an existing copy. Allow several GB RAM for NPZ decoding.

Every run saves out-of-fold predictions with source-position IDs, fold metrics,
separate fit/prediction timings, raw diagnostics, settings, fold-specific
preprocessing, versions, seeds, checksums, sessionInfo and explicit failure
status. Review `run_status.csv` and every `performance.csv` row. Missing or
unsupported APIs fail visibly; completion does not prove adequate convergence.

Each benchmark folder contains its README, `config.R` and `run.R`. Shared
[validation and metric definitions](protocol.html) ensure comparable scales.
