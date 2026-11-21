# Maize prediction: DTT

Full-marker benchmark matching the published GPBench regression scheme.

Use all source rows and markers, raw dosage coding and the exact scikit-learn
1.6.1 ten-fold splitter with seed 42. Main scores are arithmetic means of fold
metrics. [Protocol](../../docs/protocol.md) specifies phenotype imputation,
R2, source-ID limitations and timing scope.

Benchmark genomic BLUP implemented in greml/gsolve, with REML variance estimation.
A separate gsolve check uses our fitted variance estimates; its solve
time excludes REML. Numerical implementations remain installed privately.
No gsolve/greml implementation source or binaries are redistributed.

Build and activate the [environment](../../environment/README.md), then run:

```text
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
Rscript --vanilla scripts/check_solvers.R RUN_DIRECTORY
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

[Reviewed results](https://psoerensen.github.io/gpct/reports/maize.html).
Individual data, folds, predictions, fit objects and raw diagnostics stay external.
