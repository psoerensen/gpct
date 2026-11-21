---
layout: default
title: 'Cattle prediction: mkg'
---
# Cattle prediction: mkg

Executed 2026-11-21, run `20261121-openblas`. All three methods completed five folds with no warnings or failed fits. Both gbayes methods converged; rrBLUP exposes no convergence flag. All 512 selected markers were used in every fold.

R 4.4.3, gbase 0.1.14, gbayes 0.1.16, rrBLUP 4.6.3; OpenBLAS 0.3.29 with four runtime threads, Intel Core Ultra 7 258V (8 logical processors), 32 GiB RAM. Timings are one execution, without uncertainty estimates. rrBLUP estimates variance components; the other methods use fixed settings, so timing differences include different fitting tasks.

[Recipe checksums](../assets/reports/20261121-openblas/cattle/recipe_checksums.csv). Original trait definitions, units and upstream processing remain unverified; this is a within-cohort 512-marker execution pilot.


**Reviewed aggregate run summary; individual predictions and fold membership remain local.**

## Scientific question and dataset

How well do the declared methods predict the supplied trait within this dataset under shared random five-fold validation? Source trait definitions, upstream adjustments and units remain unverified.

Recipe: [gpbench_cattle](https://github.com/psoerensen/gpct/tree/main/benchmarks/cattle_prediction)

| Species | Dataset | Trait | Individuals available | Eligible individuals | Available markers | Planned markers | Markers fitted, min | Markers fitted, max |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Bos taurus | gpbench_cattle | mkg | 5024 | 5024 | 42551 | 512 | 512 | 512 |

[Dataset catalogue CSV](../assets/reports/20261121-openblas/cattle/dataset_catalogue.csv)

## Methods and validation design

Single shared five-fold partition, seed 4401. All methods use the same eligible samples and frozen training-only transformations. Fixed pilot settings; no tuning on test folds. REML rrBLUP is the baseline.

| Dataset | Trait | Method | Package | Package Version | Tuning Strategy | Model Settings | Convergence Criteria | Requested Package Threads | Actual Threads | Managed Memory Budget Mib |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpbench_cattle | mkg | rrblup | rrBLUP | 4.6.3 | training-only REML variance estimation; no CV tuning | REML ridge; variance ratio fitted on training data; bounds 1e-9 to 1e9 | REML optimizer; no flag exposed | not available | not available | not available |
| gpbench_cattle | mkg | gbayes_gaussian | gbayes | 0.1.16 | none; fixed predeclared settings | marker_gaussian/pcg; standardized outcome; ve=0.5; prior variance=0.5/p; nit=2000 | native tolerance 1e-08 and iteration cap; inspect diagnostics | 1 | not available | 512 |
| gpbench_cattle | mkg | gbayes_elastic_net | gbayes | 0.1.16 | none; fixed predeclared settings | elastic_net/coordinate_descent; standardized outcome; lambda=0.1; alpha=0.5; nit=2000 | native tolerance 1e-08 and iteration cap; inspect diagnostics | 1 | not available | 512 |

[Method settings CSV](../assets/reports/20261121-openblas/cattle/method_settings.csv) · [Run metadata CSV](../assets/reports/20261121-openblas/cattle/run_metadata.csv)

## Main results

Main metrics are calculated from pooled out-of-fold predictions. Fold means are a separate descriptive summary. NA means not run, not measured or undefined; consult status. Available markers and actually fitted markers are separate.

| Dataset | Trait | Method | Predictive ability | RMSE | Predictive R² | Calibration Intercept | Calibration Slope | Fit (s) | Predict (s) | Method elapsed (s) | Peak RAM (MB) | Ram Status | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpbench_cattle | mkg | rrblup | 0.53940 | 0.84199 | 0.29164 | -0.00058196 | 0.98927 | 53.61 | 0.02 | 53.67 | not available | not measured | completed |
| gpbench_cattle | mkg | gbayes_gaussian | 0.53441 | 0.84802 | 0.28144 | -0.00075315 | 0.88438 | 0.79 | 0.03 | 0.88 | not available | not measured | completed |
| gpbench_cattle | mkg | gbayes_elastic_net | 0.43500 | 0.92060 | 0.15319 | -0.00028766 | 1.79060 | 0.70 | 0.02 | 0.82 | not available | not measured | completed |

[Download summary CSV](../assets/reports/20261121-openblas/cattle/benchmark_results.csv) · [Per-fold metrics](../assets/reports/20261121-openblas/cattle/fold_results.csv) · [Fold means](../assets/reports/20261121-openblas/cattle/fold_metric_means.csv)

## Performance and computational cost

Filled dots show pooled OOF scores; open dots show descriptive fold values. No confidence intervals are implied. Baseline changes use matched dataset/trait and folds. Raw RMSE is never combined across traits.

<figure class="report-figure"><img src="../assets/reports/20261121-openblas/cattle/performance.svg" alt="Predictive ability by method, with pooled and fold values distinguished."></figure>

[Full-size performance SVG](../assets/reports/20261121-openblas/cattle/performance.svg)

<figure class="report-figure"><img src="../assets/reports/20261121-openblas/cattle/improvement.svg" alt="Change in predictive ability from rrBLUP with a zero reference line."></figure>

[Full-size baseline-improvement SVG](../assets/reports/20261121-openblas/cattle/improvement.svg)

<figure class="report-figure"><img src="../assets/reports/20261121-openblas/cattle/runtime.svg" alt="Pooled predictive ability versus fitting seconds, coloured by method."></figure>

[Full-size performance/runtime SVG](../assets/reports/20261121-openblas/cattle/runtime.svg)

Fitting and prediction seconds are summed over five folds. Method elapsed includes loading, diagnostics and scoring but excludes shared input/fold preparation and CSV writes. Case elapsed includes all methods and shared work and is not a per-method cost. Peak RAM and observed per-fit thread utilization remain unmeasured. gbayes requests one package worker. Run metadata records the loaded BLAS implementation, its runtime thread setting, binary checksum and hardware; a thread setting does not measure CPU utilization.

## Calibration, convergence, warnings and failed fits

Calibration uses pooled OOF quantile bins (up to ten, at least five individuals per published bin) and an identity line. Only aggregate bin means and counts leave the local run; review them before publication. These plots do not recalibrate predictions.

<figure class="report-figure"><img src="../assets/reports/20261121-openblas/cattle/calibration.svg" alt="Binned mean observed phenotype versus mean prediction, with an identity line."></figure>

[Full-size calibration SVG](../assets/reports/20261121-openblas/cattle/calibration.svg)

[Aggregate calibration CSV](../assets/reports/20261121-openblas/cattle/calibration_bins.csv)

| Method | Fold | Status | Convergence | Warning Count |
| --- | --- | --- | --- | --- |
| rrblup | 1 | completed | not exposed | 0 |
| gbayes_gaussian | 1 | completed | converged | 0 |
| gbayes_elastic_net | 1 | completed | converged | 0 |
| rrblup | 2 | completed | not exposed | 0 |
| gbayes_gaussian | 2 | completed | converged | 0 |
| gbayes_elastic_net | 2 | completed | converged | 0 |
| rrblup | 3 | completed | not exposed | 0 |
| gbayes_gaussian | 3 | completed | converged | 0 |
| gbayes_elastic_net | 3 | completed | converged | 0 |
| rrblup | 4 | completed | not exposed | 0 |
| gbayes_gaussian | 4 | completed | converged | 0 |
| gbayes_elastic_net | 4 | completed | converged | 0 |
| rrblup | 5 | completed | not exposed | 0 |
| gbayes_gaussian | 5 | completed | converged | 0 |
| gbayes_elastic_net | 5 | completed | converged | 0 |

Failed or incomplete methods keep their fold statuses; pooled scores and comparison plots are withheld. Raw warning/error text and full diagnostic objects remain local because they can contain identifiers or paths. Unknown convergence and missing resource measurements are explicit. Completion does not certify scientific validity.

## Reproduce and inspect

From the repository root, first build and activate the pinned environment described in the repository's environment/README.md:

```text
Rscript --vanilla environment/preflight.R
Rscript --vanilla scripts/check_dependencies.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

Set external GPCT_DATA_DIR/GPCT_OUTPUT_DIR and acknowledge the positional-ID contract before preparation. Do not publish individual predictions, folds or raw diagnostic files. Preserve the run's original settings, versions and input checksum.

[Settings and versions](../assets/reports/20261121-openblas/cattle/method_settings.csv) · [Reporting sessionInfo](../assets/reports/20261121-openblas/cattle/report-sessionInfo.txt) · [Run metadata](../assets/reports/20261121-openblas/cattle/run_metadata.csv)

Repeated validation with identical method splits can be added later. Five folds are descriptive partitions, not independent experimental replicates. Association and genetic-correlation cases need separate outcomes and reporting schemas.
