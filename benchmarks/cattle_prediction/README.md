# Cattle prediction: mkg

Full-marker benchmark matching the published GPBench regression scheme.

Use all source rows and markers, raw dosage coding and the exact scikit-learn
1.6.1 ten-fold splitter with seed 42. Main scores are arithmetic means of fold
metrics. [Protocol](../../docs/protocol.md) specifies phenotype imputation,
R2, source-ID limitations and timing scope.

Benchmark genomic BLUP (greml/gsolve REML), Gaussian VB and sparse normal-mixture VB (gbayes), plus GLMA Gaussian and prior-selected full-marker prediction. The gbayes streamed interface retains all raw markers, uses native intercept projection and fixed training-only priors: working h2=0.5 and mixture inclusion probability 0.1. GLMA uses the existing C++ joint fits underlying its LOCO exports, without chromosome exclusions: training empirical marker SD scaling, constant-marker exclusion, blocked RHE/MC variance refinement and internal training-fold validation (seed 17092026). It uses the verified full MKL prefix with four coordinate workers. No outer test-fold tuning is performed. The models differ in preprocessing and variance estimation; timing compares complete workflows.
A separate gsolve check uses our fitted variance estimates; its solve
time excludes REML. Numerical implementations remain installed privately.
No gsolve/greml implementation source or binaries are redistributed.

Build and activate the [environment](../../environment/README.md), then run:

```text
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/check_solvers.R RUN_DIRECTORY
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

[Reviewed results](https://psoerensen.github.io/gpct/reports/cattle.html).
Individual data, folds, predictions, fit objects and raw diagnostics stay external.
