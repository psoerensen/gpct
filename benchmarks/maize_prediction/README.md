# Maize prediction: DTT pilot

**Status: planned; recipe written, not executed in R.**

Question: how well do conventional REML ridge prediction and two fixed-setting
gbayes predictors recover held-out supplied `DTT` values in random within-panel
five-fold validation? Target is the source numeric trait; biological definition,
units, environments and prior adjustment need confirmation. We do not infer
environmental transfer or breeding-value accuracy from these splits.

Data: GPBench Maize, 1,458 rows × 75,304 markers, traits DTT/PH/EW. Drop the two
nonfinite DTT outcomes before partitioning, preserving source row IDs, leaving
1,456 eligible samples. Use **512 evenly spaced source marker columns** without
outcome-based marker selection. Original sample/marker IDs are absent; explicit
positional alignment acknowledgement is required.

Methods/settings are identical to the [cattle pilot](../cattle_prediction/README.md):
REML rrBLUP baseline; gbayes fixed Gaussian prior (variance 0.5/p, residual 0.5);
gbayes elastic net (lambda 0.1, alpha 0.5). Outcomes/features use training-only
scales; gbayes deterministic fits allow 2,000 iterations, tolerance 1e-8. No
tuning uses the outer test folds. All predictions include intercepts and return
to supplied phenotype units. Folds are saved, five-fold seed 4401, shared across
methods. No environment or kinship stratification is claimed.

Requires R, rrBLUP, compatible gbayes/native dependencies, and for preparation
digest, reticulate and existing Python/NumPy. See [methods](../../docs/methods.md)
for the source-only qualification limits. No installation is changed.

From the repository root with the environment variables in the
[root README](../../README.md):

```text
Rscript --vanilla scripts/check_dependencies.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
```

Expected output under `GPCT_OUTPUT_DIR/maize/<run-id>/`:
`predictions.csv`, `performance.csv`, `folds.rds`, `settings.rds`,
`preprocessing-fold*.rds`, `*-diagnostics.rds`, `provenance.rds`,
`package_versions.csv`, `sessionInfo-start.txt`, `sessionInfo.txt`,
`run_status.csv`. Failures retain explicit status and NA metrics.
See [metric definitions](../../docs/protocol.md) and
[data provenance](../../datasets/README.md).

Full-marker BayesC/BayesR and environment/family holdouts remain future cases.
