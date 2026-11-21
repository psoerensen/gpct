---
layout: default
title: "Maize: genomic BLUP"
---
# Maize: genomic BLUP

## Scientific question and dataset

Predict supplied phenotypes using all source markers and the published GPBench ten-fold split algorithm. Original IDs, upstream processing and phenotype units remain unverified.

| Dataset | Species | Trait | Individuals Evaluated | Observed Targets | Imputed Targets | Available markers | Markers Used |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpbench_maize | Zea mays | DTT | 1458 | 1456 | 2 | 75304 | 75304 |

[Full dataset catalogue and source definitions](../assets/reports/20261121-gsuite-final/maize/dataset_catalogue.csv)

## Methods and validation

Shuffled ten-fold KFold, seed 42, scikit-learn 1.6.1 and NumPy 1.26.4. Raw supplied dosage coding; no marker filtering or SD scaling. The benchmarked model estimates variance components by REML through our greml/gsolve implementation. greml uses the equivalent covariance K=ZZt/p. Implementations remain installed privately; no private source or binaries are distributed.

To reproduce GPBench, missing phenotypes are mean-imputed before splitting. Two maize DTT targets are imputed; cattle has none. Imputed labels are not genuinely observed phenotypes. The observed-target-only sensitivity summary excludes them from evaluation. This reproduction does not endorse whole-dataset phenotype imputation for a new scientific study.

| Method | Package | Package Version | Native Engines | Tuning | Convergence |
| --- | --- | --- | --- | --- | --- |
| gblup_reml | gsuite | 0.43.0 | greml 0.92.0; gsolve 0.28.0 | No test-fold tuning | Score tolerance 1e-04 ; hybrid EM-AI; requested direct threads 4; returned backend settings in fold CSV; cap 100 |

[Full model and method settings](../assets/reports/20261121-gsuite-final/maize/method_settings.csv)

Fitting calls gsuite::gs_lmm_fit through our R interface to the compiled greml/gsolve libraries. Exact implementation revisions are pinned below; these repositories are private.

| Software | Version | Private Source Commit |
| --- | --- | --- |
| gsuite | 0.43.0 | [19f876e71df0](https://github.com/psoerensen/gsuite/tree/19f876e71df014b996dbd09d0ae01ab3d0709829) |
| greml | 0.92.0 | [c84f83409e7a](https://github.com/psoerensen/greml/tree/c84f83409e7a08eeada20e854c6ff6c81c8ed25f) |
| gsolve | 0.28.0 | [dd405973d6ae](https://github.com/psoerensen/gsolve/tree/dd405973d6aece137fb9d82367502f78c8feef2d) |

[Software and source commits](../assets/reports/20261121-gsuite-final/maize/software_sources.csv)

## Results

Main scores are arithmetic means of ten test-fold metrics, matching GPBench. Predictive R2 uses each test fold mean as its reference. Descriptive fold standard deviations use NumPy ddof=0; no confidence intervals or independent fold replicates are implied. Pooled OOF metrics are separate.

| Dataset | Trait | Method | Predictive ability | RMSE | Predictive R² | Calibration Slope | Fit (s) | Predict (s) | Kernel Seconds | Workflow Seconds | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpbench_maize | DTT | gblup_reml | 0.65162 | 2.1753 | 0.41319 | 1.0001 | 31.8 | 0.02 | 1.81 | 33.63 | completed |

[Results CSV](../assets/reports/20261121-gsuite-final/maize/benchmark_results.csv) · [Fold values](../assets/reports/20261121-gsuite-final/maize/fold_results.csv) · [Pooled OOF](../assets/reports/20261121-gsuite-final/maize/pooled_results.csv) · [Observed targets only](../assets/reports/20261121-gsuite-final/maize/observed_only_metrics.csv)

## Performance and computational cost

<figure class="report-figure"><img src="../assets/reports/20261121-gsuite-final/maize/performance.svg" alt="performance comparison within each dataset and trait, using the matched ten-fold validation."></figure>

[Full-size performance SVG](../assets/reports/20261121-gsuite-final/maize/performance.svg)

<figure class="report-figure"><img src="../assets/reports/20261121-gsuite-final/maize/improvement.svg" alt="improvement comparison within each dataset and trait, using the matched ten-fold validation."></figure>

[Full-size improvement SVG](../assets/reports/20261121-gsuite-final/maize/improvement.svg)

<figure class="report-figure"><img src="../assets/reports/20261121-gsuite-final/maize/runtime.svg" alt="runtime comparison within each dataset and trait, using the matched ten-fold validation."></figure>

[Full-size runtime SVG](../assets/reports/20261121-gsuite-final/maize/runtime.svg)

Workflow seconds include ten fits, ten predictions and construction of the reusable raw-dosage kernel, including fold block preparation. Shared kernel construction is data-only and uses no held-out responses. Zero recorded seconds means below the elapsed timer resolution. These are single-execution measurements on our hardware. Peak RAM is not measured.

R/OpenBLAS and the MKL environment request four threads. The component backend returns requested/resolved/support settings of one in this build; those returned values are retained in the fold CSV. These settings do not measure CPU utilization. The separate fixed-variance solver check requests one supported worker.

## Calibration, convergence and solver checks

<figure class="report-figure"><img src="../assets/reports/20261121-gsuite-final/maize/calibration.svg" alt="Aggregate OOF calibration bins with identity line, separately for each dataset and trait."></figure>

[Full-size calibration SVG](../assets/reports/20261121-gsuite-final/maize/calibration.svg) · [Aggregate bins](../assets/reports/20261121-gsuite-final/maize/calibration_bins.csv)

| Dataset | Method | Fold | Status | Convergence | Warning Count |
| --- | --- | --- | --- | --- | --- |
| gpbench_maize | gblup_reml | 1 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 2 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 3 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 4 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 5 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 6 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 7 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 8 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 9 | completed | converged | 0 |
| gpbench_maize | gblup_reml | 10 | completed | converged | 0 |

The following fixed-variance gsolve check uses the variance estimates from our greml fit on representative folds: cattle folds 1 and 9 (including the previously problematic fold), maize fold 1. It checks prediction equivalence; its solve time excludes REML and is not another complete-method timing.

| Fold | Status | Max Prediction Difference | Prediction Correlation | Elapsed Seconds | Requested Workers | Stage | Dataset | Trait |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | converged | 1.9657e-08 | 1 | 2.12 | 1 | representative-fold fixed-variance GLS/BLUP; two RHS; REML excluded | gpbench_maize | DTT |

[Solver checks CSV](../assets/reports/20261121-gsuite-final/maize/solver_checks.csv)

## Reproduce

Build and activate the pinned environment using environment/README.md in the repository. Set external GPCT_DATA_DIR and GPCT_OUTPUT_DIR; acknowledge positional alignment. Then run scripts/prepare.R CASE, benchmarks/CASE_prediction/run.R, scripts/check_solvers.R RUN_DIRECTORY and scripts/report_prediction.R RUN_DIRECTORY.

[Run metadata](../assets/reports/20261121-gsuite-final/maize/run_metadata.csv) · [Recipe checksums](../assets/reports/20261121-gsuite-final/maize/recipe_checksums.csv) · [Reporting session](../assets/reports/20261121-gsuite-final/maize/report-sessionInfo.txt)

Individual predictions, fold assignments, saved fits, raw diagnostics, private implementation source and binaries stay outside the public repository.

[R packages loaded during fitting](../assets/reports/20261121-gsuite-final/maize/fit-sessionInfo.txt)
