# Scripts

Invoke scripts with `Rscript --vanilla` from the repository root after activating
the pinned private environment.

| Script | Purpose |
| --- | --- |
| `prepare.R cattle` / `prepare.R maize` | Verify the archive and prepare all supplied markers |
| `paths.R` | Enforce external data and individual-artifact directories |
| `gpbench_folds.py` | Save the actual scikit-learn ten-fold partitions, seed 42 |
| `evaluate.R` | Verify saved splits; calculate fold and pooled metrics |
| `fit_greml.R` | Thin call to our installed REML/BLUP interfaces |
| `fit_gbayes.R` | Training-only working priors and thin calls to existing streamed Gaussian/normal-mixture VB |
| `fit_glma.R` | Thin calls to existing native joint Gaussian/prior-selected full-marker prediction; no LOCO |
| `combine_glma_reports.R` | Verify matching private inputs/folds/outcomes and combine reviewed aggregate history with the completed GLMA batch |
| `run_prediction.R` | Shared recipe sourced by each benchmark entry point |
| `check_solvers.R RUN_DIRECTORY` | Verify our fixed-variance solver against our fitted predictions, after timing the benchmark |
| `report_prediction.R RUN_DIRECTORY` | Generate aggregate CSVs, four SVGs and a report outside the checkout |

Only methods/models implemented in gsuite are benchmarked. No external statistical
fitter is used. Base R and optimized BLAS/LAPACK perform ordinary input preparation;
our installed engines perform REML, mixed-model solving and variational fitting.

Default configs run genomic BLUP, Gaussian VB and normal-mixture VB. Set
`GPCT_METHODS=gbayes_gaussian,gbayes_mixture` to execute only the additional models.
All methods use the same saved ten-fold partitions and phenotype rule. gbayes
preserves raw dosage coordinates, uses a native intercept projection and fixes
working h2=0.5 with mixture inclusion probability 0.1; there is no test-fold tuning.

Set explicit external GPCT_DATA_DIR and GPCT_OUTPUT_DIR paths. Existing run and
report directories are refused. GPCT_RUN_ID selects a unique label. Input, split
and recipe identities are retained with each run. Individual predictions include
imputed-target flags and the training-mean reference used for the RMSE improvement
plot. They are never copied to the website.

Failures and warnings remain visible in performance.csv and run_status.csv.
Fitting and prediction times exclude diagnostics serialization. Kernel preparation
and total case time are recorded separately. A fixed-variance solver check is not
a complete REML timing. Peak RAM remains unavailable.

gbayes matrix extraction is recorded as preparation time; prior calculations and
native source reads/projection/updates are included in fitting. Fold summaries
retain sweep counts, convergence, prior values, decoded backend and native source
read seconds. A sweep-cap result is provisional and keeps its explicit status.

Reporting verifies OOF row/fold alignment, distinguishes means of fold metrics
from pooled scores, and keeps fold variation descriptive. It fits no models.
Run tests/check_protocol.R, tests/check_interfaces.R and tests/check_reporting.R
before publication. Publish only the reviewed aggregate allowlist described in
docs/reporting.md.
