# gpct

Reproducible genomic prediction and related statistical genetics benchmarks.
This is a collection of datasets, recipes, execution records and selected
results, using existing R packages. It does not implement statistical methods
or provide an orchestration framework.

## Current state

| Case | Trait | Scope | Status |
| --- | --- | --- | --- |
| [Cattle prediction](benchmarks/cattle_prediction/README.md) | `mkg` | 512-marker pilot | Completed 2026-11-21; all three methods, five folds |
| [Maize prediction](benchmarks/maize_prediction/README.md) | `DTT` | 512-marker pilot | Completed 2026-11-21; all three methods, five folds |

Both pilots completed with real out-of-fold results and fit/prediction timings. See the [published comparisons](https://psoerensen.github.io/gpct/results.html) and
[verification](docs/verification.md) for evidence and precise missing steps.
The pilot is an execution example, not a genome-wide comparison or a reproduction
of GPBench's published ten-fold experiments.

## Start here

Start with the [pinned environment build recipe](environment/README.md), then
activate it and run `environment/preflight.R` before any long benchmark.
It provides a private R/OpenBLAS runtime and rebuilds the existing ecosystem
packages from pinned clean source snapshots. Shared installations are unchanged.

The analysis requires `rrBLUP`, a compatible `gbayes` exposing
the documented prepared-design `bayes()` interface, `digest`, `reticulate`, and
a Python environment containing NumPy. Analysis scripts install nothing;
`environment/bootstrap.ps1` is the explicit isolated dependency-build entry point.
See [methods and API provenance](docs/methods.md). The pinned gbayes 0.1.16 build passed the documented numerical example and both pilots; package version alone does not establish support.

Run from the repository root. Set environment variables in R, PowerShell or
your shell; these commands show PowerShell:

```powershell
./environment/activate.ps1
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
# Acknowledge the upstream row-order convention; original sample IDs are absent.
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
# If necessary, select an existing Python with NumPy:
# $env:RETICULATE_PYTHON = 'C:/path/to/python.exe'
Rscript --vanilla scripts/check_dependencies.R
Rscript --vanilla environment/preflight.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
```

Preparation downloads the pinned 303 MB archive once, verifies SHA-256, and
extracts only the four cattle/maize NPZ files as needed. Alternatively set
`GPCT_ARCHIVE` to an existing archive. Raw matrices require roughly 1.8 GB for
cattle and 0.9 GB for maize before copying; allow several GB of free RAM.
Prepared pilots and all individual outputs stay outside this repository.
If `Rscript` is absent from PATH, invoke the absolute path to an existing R
installation. Do not modify shared installations just to run these examples.

## Layout

```text
datasets/                 registry and data provenance
benchmarks/
  cattle_prediction/      README.md, config.R, run.R
  maize_prediction/       README.md, config.R, run.R
scripts/                  preparation, evaluation and dependency checks
results/                  publication policy; no individual outputs
docs/                     GitHub Pages source and reproducibility notes
tests/                    small R checks of evaluation and leakage protections
```

Both pilots use saved five-fold partitions with seed **4401**, identical across
methods. Training-only imputation and scaling are applied to held-out genotypes;
held-out outcomes enter evaluation only. Predictions are on the supplied trait
scale, including the training intercept. Details and metric definitions are in
[the protocol](docs/protocol.md).

## Report a run

```text
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

The reporting script generates three standard tables, separate pooled/fold
summaries, four static SVG plot types and a detailed report. Missing resources
and failed fits remain explicit. Individual predictions stay local. The
[results page](docs/results.md) and [reporting guide](docs/reporting.md) contain
blank templates and the review/publication procedure; no measured results exist.

## Contribute and publish

See [CONTRIBUTING.md](CONTRIBUTING.md) to add animal, plant or human datasets.
Keep individual data, predictions, folds, caches and large files outside git.
Publish only reviewed, shareable aggregate summaries.

The public [GitHub Pages site](https://psoerensen.github.io/gpct/) publishes the
`docs/` source from `main`. See [publishing instructions](docs/publishing.md)
for updates and the aggregate-results review procedure.
