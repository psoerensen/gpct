# Cattle prediction: mkg pilot

**Status: planned; recipe written, not executed in R.**

Question: how well do conventional REML ridge prediction and two fixed-setting
gbayes predictors recover held-out supplied `mkg` values in random within-cohort
five-fold validation? Target is the supplied, potentially pre-adjusted trait,
in its source numeric units. It is not a verified raw milk measure or breeding
value. See [dataset provenance](../../datasets/README.md).

Data: GPBench Cattle, 5,024 rows × 42,551 markers; all 5,024 `mkg` outcomes finite.
This pilot uses **512 evenly spaced source marker columns**. It does not claim
whole-genome performance. Original sample IDs and marker metadata are absent;
explicit positional alignment acknowledgement is required.

Methods: `rrBLUP::mixed.solve(..., method="REML")` is the established baseline.
`gbayes::bayes(..., method="marker_gaussian", algorithm="pcg")` uses fixed
residual variance 0.5 and equal marker prior variances 0.5/p on training-standardized
outcomes and features. `method="elastic_net", algorithm="coordinate_descent"`
uses lambda 0.1, alpha 0.5. Both have a 2,000-iteration cap and tolerance 1e-8.
These are predeclared pilot settings, not tuned or estimated heritabilities.
The REML ridge baseline learns its variance ratio within each training fold.

Requires R, rrBLUP, compatible gbayes and native dependencies; preparation also
needs digest, reticulate and existing Python/NumPy. Exact API and qualification
limits: [methods](../../docs/methods.md). Optional glma/gcorr/gsuite are not
loaded for prediction. No shared installation is changed.

Validation: saved five-fold partitions, seed 4401, shared across all methods.
Training means/SDs determine genotype imputation/scaling and outcome scaling.
Training-constant markers are dropped identically for all methods within a fold.
Predictions are returned to supplied phenotype units, including training means.
No outer test outcomes enter fitting, preparation or tuning. Random splits do
not test transfer across families, herds or time; source pedigree is unavailable.

From the repository root after setting external directories and acknowledging
positional IDs as in the [root README](../../README.md):

```text
Rscript --vanilla scripts/check_dependencies.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
```

Expected output under `GPCT_OUTPUT_DIR/cattle/<run-id>/`:
`predictions.csv`, `performance.csv`, `folds.rds`, `settings.rds`,
`preprocessing-fold*.rds`, `*-diagnostics.rds`, `provenance.rds`,
`package_versions.csv`, `sessionInfo-start.txt`, `sessionInfo.txt`,
`run_status.csv`. Failed calls are explicit and metrics remain NA.
See [evaluation definitions](../../docs/protocol.md).

Future case: full-marker BayesC/BayesR via verified Glist/PLINK inputs, once
genuine marker/allele metadata or a documented legitimate import route exists.
Do not fabricate genomic metadata to force an interface.
