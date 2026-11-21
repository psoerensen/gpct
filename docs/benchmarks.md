---
layout: default
title: Benchmark recipes
---
# Benchmark recipes

Both 512-marker cases **completed on 2026-11-21** using the pinned private R/OpenBLAS environment. All three methods completed five folds without warnings or failed fits. Both gbayes methods converged; rrBLUP exposes no convergence flag.

| Case | Question | Eligibility | Scope |
| --- | --- | --- | --- |
| Cattle/mkg | Predict supplied mkg within cohort | 5,024 finite outcomes | 512-marker pilot |
| Maize/DTT | Predict supplied DTT within panel | 1,456 finite outcomes; two excluded | 512-marker pilot |

Detailed measured reports: [cattle/mkg](reports/cattle.html) and
[maize/DTT](reports/maize.html). Both follow the same sequence: scientific
question, methods/validation, results table, performance/cost plots,
calibration/diagnostics, and reproduction details. See the
[standard comparison tables and plots](results.html).

These targets use supplied numeric units. Biological definitions, preprocessing
and units need original-source confirmation. Random splits do not evaluate
family, herd, environment or temporal transfer.

## Reproduce locally

Build and activate the [pinned environment](https://github.com/psoerensen/gpct/tree/main/environment) first. Preparation needs digest,
reticulate and an existing Python with NumPy. Prediction needs rrBLUP and a
compatible gbayes exposing the inspected prepared-design interface. Analysis scripts report missing dependencies and install nothing; the explicit environment bootstrap installs into an isolated private library. Read [interface limits](methods.html).

From the repository root, in PowerShell:

```powershell
./environment/activate.ps1
Rscript --vanilla environment/preflight.R
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
