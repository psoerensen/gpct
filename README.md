# gpct

Reproducible genomic prediction and related statistical genetics benchmarks.
This is a collection of datasets, recipes, execution records and selected
results, using existing R packages. It does not implement statistical methods
or provide an orchestration framework.

## Current state

| Case | Trait | Scope | Status |
| --- | --- | --- | --- |
| [Cattle prediction](benchmarks/cattle_prediction/README.md) | `mkg` | 512-marker pilot | Planned; recipe written, R execution pending |
| [Maize prediction](benchmarks/maize_prediction/README.md) | `DTT` | 512-marker pilot | Planned; recipe written, R execution pending |

The GPBench archive and aggregate metadata have been inspected. No prediction
benchmark has been executed and there are no performance results. See
[verification](docs/verification.md) for evidence and precise missing steps.
The pilot is an execution example, not a genome-wide comparison or a reproduction
of GPBench's published ten-fold experiments.

## Start here

Use an existing R installation with `rrBLUP`, a compatible `gbayes` exposing
the documented prepared-design `bayes()` interface, `digest`, `reticulate`, and
a Python environment containing NumPy. No script installs dependencies.
See [methods and API provenance](docs/methods.md). The gbayes source inspected
labels these adapters as pending runtime qualification; package version alone
does not establish support.

Run from the repository root. Set environment variables in R, PowerShell or
your shell; these commands show PowerShell:

```powershell
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
# Acknowledge the upstream row-order convention; original sample IDs are absent.
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
# If necessary, select an existing Python with NumPy:
# $env:RETICULATE_PYTHON = 'C:/path/to/python.exe'
Rscript --vanilla scripts/check_dependencies.R
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

## Contribute and publish

See [CONTRIBUTING.md](CONTRIBUTING.md) to add animal, plant or human datasets.
Keep individual data, predictions, folds, caches and large files outside git.
Publish only reviewed, shareable aggregate summaries.

The local Pages source is ready under `docs/`. Per the latest instruction,
content has not been pushed and Pages has not been enabled. See
[publishing instructions](docs/publishing.md) for the later GitHub handoff.
