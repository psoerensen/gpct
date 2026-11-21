# gpct

Reproducible benchmarks for methods and models implemented in the gsuite ecosystem.

The cattle/mkg and maize/DTT benchmarks match the published GPBench regression
scheme: all supplied markers, raw dosage coding, shuffled ten-fold cross-validation
with scikit-learn 1.6.1 and seed 42, and arithmetic means of test-fold metrics.
[Results and timings](https://psoerensen.github.io/gpct/results.html).

| Benchmark | Individuals | Markers | Methods |
| --- | --- | --- | --- |
| Cattle / mkg | 5,024 | 42,551 | Genomic BLUP: greml REML with gsolve |
| Maize / DTT | 1,458 | 75,304 | Genomic BLUP: greml REML with gsolve |

GPBench mean-imputes missing phenotypes before splitting. To reproduce that
scheme, the two missing maize DTT values are imputed and flagged. A separate
observed-target-only sensitivity summary excludes them from scoring. This is
not a claim that phenotype imputation before validation is appropriate for a
new scientific study. Original IDs, upstream preprocessing and units remain
unverified; source-position IDs are explicit surrogates.

## Reproduce

Build and activate the [pinned environment](environment/README.md). R uses
OpenBLAS; the private gsolve/greml integration uses its existing MKL backend.
Public files contain thin benchmark calls, settings, provenance and reviewed
aggregates. Numerical implementation source and binaries are not distributed.
Access to the private integration is required to reproduce these fits. GPBench
provides datasets and a validation scheme; external fitters are outside gpct's scope.

```powershell
./environment/activate.ps1
$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
Rscript --vanilla environment/preflight.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla tests/check_interfaces.R
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
Rscript --vanilla scripts/check_solvers.R RUN_DIRECTORY
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

Preparation verifies the pinned archive checksum. GPCT_ARCHIVE can select an
existing verified archive. All individual data, predictions, fold assignments,
saved fits and raw diagnostics stay in external data/output directories.

The benchmark includes REML estimation and BLUP prediction using our implementation.
Kernel preparation is charged to the greml/gsolve workflow. Fixed-variance gsolve
checks are reported separately and are not represented as complete REML fits.
Timings are elapsed seconds from one execution; peak RAM is not measured.
Fold variation is descriptive, not independent experimental replication.

See [protocol](docs/protocol.md), [dataset provenance](datasets/README.md),
[interfaces](docs/methods.md), [reporting](docs/reporting.md) and
[verification](docs/verification.md).
