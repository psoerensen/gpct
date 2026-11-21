---
layout: default
title: Verification record
---
# Verification record

Verified 2026-11-21. The current reports benchmark genomic BLUP, Gaussian VB,
sparse normal-mixture VB, and GLMA Gaussian/prior-selected full-marker prediction
implemented in our gsuite ecosystem, using all supplied cattle and maize markers and the pinned
GPBench ten-fold validation scheme. See [results and timings](results.html).

## Statistical execution

The additional gbayes batch uses the installed 0.1.16 streamed interface and
fixed training-only priors. Its 40 method–fold predictions are compared with the
20 retained greml/gsolve fits. Combining checks require identical prepared-input
MD5s, full saved fold/ID mappings, observed and imputed target values, imputation
flags, training means, hardware and the loaded R/OpenBLAS binary hash. Execution
run IDs and immutable recipe commits identify the separate batches. Per-fold
convergence and sweep counts are reported; maximum-sweep results remain provisional.

Gaussian VB was checked against a basic ridge linear-system identity on a small
labelled design, including held-out prediction. The sparse mixture passed native
finite-output and convergence checks. Reporting tests cover all five models,
method-specific preparation/kernel cost accounting and provisional statuses.

- Both retained genomic BLUP cases completed all ten folds at score tolerance 1e-4, with converged REML fits, no failed fits and no warnings. An earlier cattle attempt at 1e-6 failed the likelihood-step acceptance check in fold nine after 202.22 seconds; its status and costs are disclosed separately. Predictions are compared against the nine successful stricter fits.
- Original source dimensions, raw dosage coding and all-marker coverage were checked against the inspected archive. Available and used markers are separate fields.
- The actual scikit-learn 1.6.1 / NumPy 1.26.4 KFold partitions use ten folds, shuffle enabled and seed 42. Saved split hashes and row order were verified locally.
- The source rule mean-imputes two missing maize DTT phenotypes before splitting. Imputed labels are flagged; observed-target-only scores remain separate.
- Reporting verifies unique OOF coverage and saved-fold alignment, recomputes every fold score, and distinguishes fold means from pooled OOF metrics. Calibration publishes only aggregate bins with at least five individuals.
- Our one-worker gsolve check uses variance estimates from our greml fits and recomputes GLS/BLUP predictions on representative folds: cattle 1 and 9 (including the earlier failure), maize 1. Agreement must be within 1e-5. Check timings exclude REML and are separate from benchmark timings.
- Published GPBench numbers provide context only. Its external statistical fitter is not executed by these recipes.

## Runtime and interface checks

The GLMA adapter calls the existing joint prediction modes in native C++,
without chromosome metadata, LOCO refits or association scans. Only outer
training rows/outcomes enter the fitter, including its internal selection split.
It retains native empirical marker standardization and constant-marker handling.
The prepared-genotype adapter and R/MKL build opt-in are pinned and pushed in
private GLMA and gsuite branches; original owner checkouts are unchanged.
The default standalone portable package does not imply MKL acceleration.
Actual MKL DGEMM dispatch was observed in the adapter's numerical check.
Gaussian predictions agreed with an independent fixed-V solve to maximum
absolute difference 2.99e-5 on the controlled fixture. Native joint acceptance
is approximate workflow acceptance, rather than exact REML convergence.
Separate fold-one boundary traces distinguish the R wrapper, the complete
native call and its inner fitting timer; these repeats are excluded from
benchmark costs and published with the reports.

R 4.4.3 runs in an isolated environment with OpenBLAS 0.3.29. Preflight checks
package locations, installed interfaces, native engine versions, loaded BLAS,
runtime thread settings and its DLL hash. The root R package is gsuite 0.43.0;
the native engines are greml 0.92.0 and gsolve 0.28.0. The native component route
uses the existing CHOLMOD/MKL backend.

Focused numerical checks compare our fixed-state and optimized REML interfaces
on small equivalent models, and compare our fixed-variance solver with a basic
dense linear-solve identity. Private bridge checks cover parity of supplied
relationship representations and rejection of incomplete metadata, missing SPD
certification and resource-limit violations. The focused native selected-inverse
gate passed after the private MKL runtime-family discovery fix.

Protocol checks cover metrics, missing-target handling and saved split integrity.
Reporting checks cover fold versus pooled aggregation, complete workflow costs,
failed folds and duplicate sample IDs. Synthetic test outputs are removed and
are not published as results.

Source revisions are pinned in the
[environment recipe](https://github.com/psoerensen/gpct/tree/main/environment).
The tested integration bridge and MKL discovery fix are saved on private owner
repository branches; no private implementation source or binaries enter gpct.
Recipe checksums include the run-time byte MD5 and a canonical LF SHA-256 for
comparison with Git checkouts on different platforms. Native binary identities
are downloadable with the reports. Original sibling checkouts and shared R
installations were not changed.

R/OpenBLAS and MKL environment settings request four threads. The component
backend reports requested/resolved/support settings of one in this build; those
returned fields are retained in the fold CSV. Solver verification requests one
supported worker. These settings do not measure CPU utilization. Fit, prediction,
kernel and whole-case time are recorded separately. Peak RAM is unmeasured;
these are single-execution timings on an Intel Core Ultra 7 258V with 32 GiB RAM.

## Scope of verification

This is a focused benchmark verification, not full R CMD check or all-package
release qualification. The pinned canonical Windows release verifier requires a
separate hard-coded R 4.4.1 installation, absent on this laptop. The build wrapper
records that limitation and requires the benchmark checks under private
R 4.4.3/OpenBLAS instead. A fresh anonymous, network-only rebuild has not been
claimed. Authorized private-source access and qualified native prerequisites
are required. No gtools package release was published.

Local rendering checks cover internal links, SVG parsing, desktop and narrow
viewport sizing, aspect ratios, plots and CSV downloads. The GitHub Pages build
and deployed result assets are checked after publication.

Original biological IDs, genomic annotations, source phenotype units and upstream
processing remain unverified. Random within-cohort validation does not establish
transfer across families, environments, herds or time. The earlier small-marker
pilot pages are retired; interrupted development runs remain private and are
excluded from these reports.
