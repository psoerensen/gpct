---
layout: default
title: Ordinary RHE and BLUP
---
# Ordinary RHE + BLUP

One ordinary native greml RHE variance-estimation pass is followed by the existing native BLUP solve. This is a Gaussian genomic relationship model with an intercept, not REML. Every stage receives selections and training-frequency coding from the same QC-selected Glist and saved GPBench ten-fold splits as the other methods.

| Dataset | Accepted folds | Correlation | RMSE | Fit seconds | Predict seconds | Process peak MiB | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cattle / mkg | 0 / 10 | not available | not available | 913.9 | not available | 1705 | Failed: 0/10 folds accepted |
| Maize / DTT | 10 / 10 | 0.619 | 2.272 | 45.7 | 15.7 | 1010 | Completed |

An aggregate accuracy is available only when all ten held-out folds have accepted predictions. Failed fits are retained; successful folds are not selectively averaged into a ten-fold score. Cattle with unavailable accuracy is omitted from the accuracy-versus-runtime and calibration curves. Its attempted fitting cost remains in the cost table.

## Cattle variance boundary

Ordinary RHE returned negative raw residual estimates in 10 of ten cattle folds. Negative moment estimates are estimates outside the covariance parameter space, not negative biological variances. The existing native adjustment floors the residual covariance at 1e-8; the BLUP solver and its final acceptance check were retained. Native failure messages are in the diagnostics CSV.

The first cattle fold was also checked with larger trace-probe sets. The negative estimate persisted. These are four-thread RHE-only diagnostics; they are not extra CV replicates or accepted prediction runs.

| Probes | Raw genetic | Raw residual | RHE seconds |
| --- | --- | --- | --- |
| 128 | 1.08474 | -0.08672 | 1.35 |
| 512 | 1.05939 | -0.06630 | 4.84 |
| 1024 | 1.07379 | -0.08020 | 9.67 |

## Variance estimates by fold

| Dataset | Fold | Raw genetic | Raw residual | Adjusted genetic | Adjusted residual | Status |
| --- | --- | --- | --- | --- | --- | --- |
| gpbench_cattle | 1 | 1.08474 | -0.08672 | 1.08474 | 1.000e-08 | failed |
| gpbench_cattle | 2 | 1.15207 | -0.15027 | 1.15207 | 1.000e-08 | failed |
| gpbench_cattle | 3 | 1.14093 | -0.14081 | 1.14093 | 1.000e-08 | failed |
| gpbench_cattle | 4 | 1.13814 | -0.12372 | 1.13814 | 1.000e-08 | failed |
| gpbench_cattle | 5 | 1.12500 | -0.11488 | 1.12500 | 1.000e-08 | failed |
| gpbench_cattle | 6 | 1.17307 | -0.15924 | 1.17307 | 1.000e-08 | failed |
| gpbench_cattle | 7 | 1.06126 | -0.06363 | 1.06126 | 1.000e-08 | failed |
| gpbench_cattle | 8 | 1.14101 | -0.13818 | 1.14101 | 1.000e-08 | failed |
| gpbench_cattle | 9 | 1.09971 | -0.09187 | 1.09971 | 1.000e-08 | failed |
| gpbench_cattle | 10 | 1.08701 | -0.08562 | 1.08701 | 1.000e-08 | failed |
| gpbench_maize | 1 | 2.10057 | 4.19023 | 2.10057 | 4.190e+00 | completed |
| gpbench_maize | 2 | 2.01157 | 4.20042 | 2.01157 | 4.200e+00 | completed |
| gpbench_maize | 3 | 2.09507 | 4.12222 | 2.09507 | 4.122e+00 | completed |
| gpbench_maize | 4 | 2.12209 | 3.90349 | 2.12209 | 3.903e+00 | completed |
| gpbench_maize | 5 | 1.97285 | 4.27395 | 1.97285 | 4.274e+00 | completed |
| gpbench_maize | 6 | 2.11353 | 4.24270 | 2.11353 | 4.243e+00 | completed |
| gpbench_maize | 7 | 1.82756 | 4.65166 | 1.82756 | 4.652e+00 | completed |
| gpbench_maize | 8 | 1.95228 | 4.41495 | 1.95228 | 4.415e+00 | completed |
| gpbench_maize | 9 | 1.91833 | 4.46985 | 1.91833 | 4.470e+00 | completed |
| gpbench_maize | 10 | 1.99602 | 4.49499 | 1.99602 | 4.495e+00 | completed |

## Timing and execution

| Dataset | Native preparation s | RHE s | BLUP s | Native covariance adjustments |
| --- | --- | --- | --- | --- |
| gpbench_cattle | 42.0 | 15.4 | 854.3 | 10 |
| gpbench_maize | 23.2 | 7.6 | 13.2 | 0 |

Fit time includes private-interface validation, packed preparation, the decoded cache, RHE and BLUP. Held-out prediction is timed separately. Whole-process time and peak RAM also include loading, saved outputs and Glist metadata. Failed BLUP attempts retain their measured cost; prediction is unavailable when it was not run.

Heavy covariance products call the existing gsolve::dense_product oneMKL kernels. The native cache is shared across RHS columns and capped at min(2 GiB, 20% of available physical RAM); it falls back to existing packed gbits products when insufficient. Coding and the RHE/BLUP algorithms are unchanged. A separate reference run verified cached versus packed products and one/four-thread predictions against dense RHE moments and GLS/held-out BLUP to about 1e-14.

Four threads here mean an operation-local native MKL cap for one RHE/BLUP fit, not four MCMC chains. R/OpenBLAS remains at one thread. MKL dispatch and one/four-thread caps were checked outside timed runs with verbose diagnostics; logging was disabled for timings. Loaded oneMKL libraries report version 2026.2.0. Four-thread measurements use logical CPUs 0–3; the one-thread checks use CPU 2.

On the same maize first fold, fitting took 8.96 seconds with one thread and 4.50 seconds with four. Native library checksums, probe controls and cache admission match; the maximum prediction difference was 2.377109e-08 . This is a same-fold threading check, not a comparison of different algorithms.

## Exact controls and scope

- 128 common Rademacher probes, batches of 8; seed 62000 + outer fold.
- Training allele-frequency HWE coding, mean-imputed from training; K = Z Zᵀ / marker count.
- Native block PCG: inner relative tolerance 1e-10, cap 1000 iterations; final true-relative-residual gate 1e-8.
- Native genetic PSD floor 0 and residual positive floor 1e-8; raw and adjusted estimates remain separate.
- The inner tolerance was tightened from the initial 1e-8 test to satisfy the unchanged final post-GLS residual gate on maize. A retained small negative-residual reference also failed BLUP; no failed solve was accepted by relaxing its gate.

The implementation and private Glist adapter are not published. This website contains only aggregate results, settings, diagnostics and software identities. Reproduction requires authorized access to the retained qualified native build and local recipes.

[Fold diagnostics and failure messages](../assets/reports/gbayes-glist/rhe-fold-diagnostics.csv) · [Trace precision](../assets/reports/gbayes-glist/rhe-trace-precision.csv) · [One/four-thread maize check](../assets/reports/gbayes-glist/rhe-thread-comparison.csv) · [Actually loaded native libraries and checksums](../assets/reports/gbayes-glist/rhe-loaded-runtime.csv)

[Cattle report and plots](cattle.html) · [Maize report and plots](maize.html) · [All results](../results.html)
