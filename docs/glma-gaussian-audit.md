---
layout: default
title: GLMA Gaussian model and variance audit
---
# GLMA Gaussian: model and variance audit

Audit completed 21 November 2026. **The current GLMA Gaussian fast path is not a numerically qualified equivalent of the greml/gsolve Gaussian REML baseline.** The original measured scores and times remain available as diagnostic results; their native acceptance flags must not be read as accurate REML or fixed-variance convergence.

## The Gaussian models differ

The retained baseline uses raw dosages with K = XX′/p. GLMA uses training-centered markers divided by their training empirical standard deviations, giving K = ZZ′/p. This changes marker weights and the implied Gaussian prior, rather than just changing the units of one variance parameter. Both use an intercept and the same saved outer folds.

The thin adapter’s means and scales agree with independently calculated training values to less than 1e-14. The diagnostic-only bridge reproduces the saved predictions and variances. There is no evidence of a dosage-cache or effect-conversion error.

[Adapter input checks](assets/reports/20261121-glma-gaussian-audit/adapter-input-checks.csv)

## Controlled maize comparisons

All ten original maize folds were checked. The reference fits use existing greml/gsolve C++ interfaces, not external model fitters. The standardized reference uses fold-specific marker scales and the same Gaussian model as GLMA. Replacing only its variances, or only its numerical solve, separates the effects. These are diagnostic fits, not a new timed benchmark or settings selected using test outcomes.

| Fit | Folds | Mean Correlation |
| --- | --- | --- |
| Raw-dosage Gaussian REML (retained baseline) | 10 | 0.65162 |
| Standardized Gaussian REML (controlled reference) | 10 | 0.64174 |
| Standardized Gaussian, GLMA variances, exact solve | 10 | 0.61794 |
| Published native GLMA Gaussian fast path | 10 | 0.60884 |

[Comparison summary](assets/reports/20261121-glma-gaussian-audit/maize-summary.csv)
 ·
[Per-fold controlled comparisons](assets/reports/20261121-glma-gaussian-audit/comparisons.csv)

Marker weighting explains part of the correlation gap, but not all of it. Using exact standardized-model REML improves the mean correlation to 0.6417; keeping GLMA’s variances and changing only the solve gives 0.6179. The published fast path gives 0.6088. These are fold means, with no claim that folds are independent replicates. The GPBench rule for two mean-imputed maize DTT targets is retained throughout.

## Variance refinement returned the starting value

In **all ten maize Gaussian folds**, the native diagnostic reports used_initial_without_bracket = TRUE. Its three grid points are 0.5, 0.75 and 1 times the starting ratio. They do not search above the starting value. No sign change was found, so the documented grid function returned the starting estimate instead of a solved variance-equation root.

The returned standardized-model ratio was approximately 0.425–0.580; exact standardized-model REML gave approximately 0.970–0.998. These are model-specific variance ratios, not independently established biological heritabilities.

For maize fold 1, the grid was 0.2703, 0.4054, 0.5406 and all native equations were positive (0.5810, 0.3770, 0.2387). The initial and final ratios were both 0.5406; exact REML gave 0.9821. An independent likelihood calculation gives a gain of 39.29 log-likelihood units at the REML ratio. The profile score is 151.77 at the retained GLMA ratio and about 0.000077 at the REML estimate. This is not a converged REML estimate.

Cattle fold 1 also returned its starting ratio without a bracket: 0.6086, compared with 0.8187 under standardized-model REML. Only this representative cattle fold was audited; no ten-fold cattle reference mean is claimed.

[All maize grid/fallback diagnostics](assets/reports/20261121-glma-gaussian-audit/maize-grid-diagnostics.csv)
 ·
[Representative native diagnostics](assets/reports/20261121-glma-gaussian-audit/native-diagnostics.csv)
 ·
[Independent maize likelihood profile](assets/reports/20261121-glma-gaussian-audit/maize-fold1-exact-profile.csv)

## The fast Gaussian refit also stopped too loosely

The representative native refits were accepted after three sweeps. Their relative Gaussian normal-equation residuals were 7.30% for maize and 5.78% for cattle. Holding GLMA’s variances fixed, an exact owned solve changes held-out predictions: RMS difference 0.2129 for maize fold 1 and 0.0955 for cattle fold 1, in the supplied phenotype units.

An independent centered-kernel Cholesky identity agrees with the owned maize fixed-variance predictions to a maximum difference of 9.6e-11. This supports the reference calculation and rules out centering/intercept equivalence as the explanation.

The native joint path uses aggressive chunk retirement and prediction-stability stopping, and reuses projected state without the strict final reconstruction/audit. Native acceptance therefore does not establish a sufficiently solved Gaussian normal equation. The earlier small-fixture check did not expose this full-data accuracy limitation.

## rrBLUP reference

This particular fallback is not used by the original rrBLUP implementation. The pinned [GPBench script](https://github.com/xwzhang2118/GPBench/blob/2c92073fb8c67e6d6c5c1cda8bd410f191c7ef02/method_reg/rrBLUP/rrBLUP.py) calls rrBLUP::mixed.solve with its default REML setting. The [rrBLUP implementation](https://github.com/cran/rrBLUP/blob/master/R/mixed.solve.R) optimizes the spectral REML objective over a broad variance-ratio interval, then calculates BLUPs; it does not use GLMA’s three-point grid or aggressive coordinate retirement. rrBLUP was inspected, not run as a benchmark fitter.

## Input preparation and marker QC

The historical benchmark bypassed Glist: greml/gsolve received a kernel calculated from the supplied dosage matrix; the private GLMA prediction adapter read a dosage-only BED cache into the native prepared-genotype resource. The original chromosome-aware GLMA LOCO interfaces use Glist and have not been tested on these unannotated GPBench arrays. These findings concern the full-marker prediction adapter and its native joint mode, not a qualification of every GLMA workflow.

The existing standard interfaces are gbase::gprep for preparation and genotype summaries, gbase::gfilter for explicit QC selection, and gprep(task="subset") for the selected resource. gprep calculates allele frequency, MAF, missingness and genotype counts; it does not by itself mean that QC filtering was performed. Its ordinary preparation interface consumes BED/BIM/FAM resources.

The historical benchmark checked input dimensions, alignment, finite values and exact 0/1/2 dosage coding, but applied no additional MAF, missingness, HWE or LD filters. GLMA could exclude constant training markers; none were excluded in these runs. All 42,551 cattle and 75,304 maize markers were retained to match GPBench. The source arrays lack original biological marker annotations and their upstream QC is unverified.

For the replacement workflow, the owner authorized explicitly synthetic BIM/FAM bookkeeping fields. PLINK conversion, exact dosage round-trip verification and QC-selected Glist preparation are now complete. MAF/missingness filters retain 42,373 cattle and 75,304 maize markers; HWE is reported without filtering. These synthetic fields do not establish biological maps or alleles and cannot support biological LOCO. See the [preparation and QC record](genotype-preparation.html). The historical results above still refer to the unfiltered inputs.

## Scope and next correction

No statistical fitting algorithm was changed in this audit. The private R bridge only gained diagnostics for initial variances, grid equations, fallback status and refit history. The previously benchmarked package was archived before that diagnostic installation. Numerical fitting remains compiled C++ with MKL; this is not an R-dispatch or BLAS-linking explanation. GLMA requests four coordinate/MKL workers; the greml/gsolve component backend reports one solver worker, while R/OpenBLAS requests four threads.

One standardized-reference attempt in maize fold 6 failed likelihood-step acceptance from GLMA’s initial values. A retry from balanced training-variance initial values converged at the same score tolerance 1e-4. The failed attempt is retained and disclosed; all ten final standardized references converged. No outer test scores chose an initial value, tolerance or model.

[Reference optimizer attempts](assets/reports/20261121-glma-gaussian-audit/optimizer-attempts.csv)
 ·
[Exact private source checkpoints](assets/reports/20261121-glma-gaussian-audit/source-checkpoints.csv)

Before treating these as equivalent Gaussian benchmarks: choose matching marker weights; use a variance path that brackets the root and reports failure when it cannot; and require a fixed-variance solve/normal-equation accuracy gate. Then rerun cross-validation without choosing settings on outer test scores. Future recipe runs now retain a no-bracket estimate as provisional rather than promoting it to completed numerical qualification.

Prior-selected uses the same variance-grid machinery, so its earlier results also remain diagnostic pending separate qualification. This audit does not apply Gaussian normal-equation tests to its non-Gaussian priors. Original benchmark numbers have not been overwritten with these reference fits.

[Original results and timings](results.html) · [Evaluation protocol](protocol.html) · [Verification record](verification.html)
