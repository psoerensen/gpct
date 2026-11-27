# gpct

Reproducible benchmarks of existing **gbayes methods**, fitted directly from
QC-selected **Glist** resources. Current datasets are GPBench cattle (`mkg`)
and maize (`DTT`), evaluated with saved ten-fold splits and seed 42.

The route is **BED/BIM/FAM → QC → Glist → training selection → gbayes C++ fit
→ held-out prediction**. Settings are specific to each comparison. The earlier
Glist collection used a one-worker fixed Gaussian reference and four MCMC chains
with one BLAS thread per chain; the separate RHE + BLUP evaluation used up to
four native threads per fit. The [current training-only comparison](docs/protocol.md#current-training-only-comparison)
uses four native MKL product threads for PCG and one worker with two sequential
chains for BayesA. `scripts/run_gbayes.R` defaults to two logical chains and one
worker; benchmark drivers override these settings per run. Preserve each run's
recorded configuration when reproducing results. Native method-specific fitting,
variance procedures and coding are preserved. The earlier experimental result
collection has been removed; no compatibility layer or old result routes are
maintained.

Read the [website](https://psoerensen.github.io/gpct/),
[protocol](docs/protocol.md), [methods](docs/methods.md),
[QC record](docs/genotype-preparation.md) and [results](docs/results.md).

## Reproduce

Use the [pinned environment](environment/README.md) and authorized private
source access. Numerical implementations and individual records are not
distributed in this repository.

```powershell
./environment/activate.ps1 -BlasThreads 1
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla scripts/prepare_glist.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla scripts/run_gbayes.R marker_gaussian maize
Rscript --vanilla scripts/run_gbayes.R marker_gaussian cattle
Rscript --vanilla scripts/publish_gbayes.R
```

`environment/run-method.ps1 -Method marker_gaussian` runs both datasets
sequentially and measures whole-process peak RAM. Its default external paths
are `%USERPROFILE%/gpct-data` and `%USERPROFILE%/gpct-results`.
See [method settings](benchmarks/methods.R) for the six configured methods.
Website summaries are regenerated after each method completes both datasets.
Individual out-of-fold predictions, diagnostics, fits and raw logs remain local.
Only aggregate CSVs and SVG plots are published.
