---
layout: default
title: Verification record
---
# Verification record

Inspection date: **2026-11-21**.


## Completed native pilots — current status

This record supersedes the execution limitations in the historical scaffold and
template sections below. On 2026-11-21 both 512-marker prediction pilots completed
using a rebuilt private environment. [Reviewed results and timings](results.html)
and detailed [cattle](reports/cattle.html)/[maize](reports/maize.html) reports are available.

- R 4.4.3 UCRT, gbase 0.1.14 and gbayes 0.1.16 were built/installed from pinned clean source snapshots using the existing canonical gsuite source-package builder. rrBLUP 4.6.3 and other CRAN inputs are checksum-pinned.
- The private R loaded OpenBLAS 0.3.29, with four runtime threads, verified from the loaded DLL. Original R installations and sibling owner checkouts were unchanged.
- The documented Gaussian and weighted elastic-net example passed coefficient/prediction checks; BLAS cross-product/SVD checks passed. The canonical package load checks passed. Full R CMD check and all-seven-package release qualification were not performed.
- Protocol and reporting checks passed under native R 4.4.3. Synthetic failure cases were removed; no synthetic results are published.
- The pinned GPBench archive was decoded using existing Python 3.12.14/NumPy 2.3.5 and reticulate 1.46.0. Eligible samples: cattle 5,024; maize 1,456. All 512 selected markers were retained in every fold.
- All 30 real method–fold fits completed without warnings or failures. Both gbayes methods converged in every fold. rrBLUP exposes no convergence flag.
- Report generation verified unique OOF coverage, saved-fold alignment, common outcomes and training means, and recomputed pooled and per-fold metrics. All published calibration bins contain at least 145 maize or 502 cattle observations. Individual predictions and fold assignments remain external.
- Fitting, prediction, method elapsed and case elapsed times were recorded. Case elapsed: cattle 58.64 s; maize 8.69 s. Hardware: Intel Core Ultra 7 258V, 8 logical processors, 32 GiB RAM. Peak RAM and observed thread utilization were not measured. Timings are a single execution; variance estimation and fixed-setting fits perform different tasks.
- An earlier reference-BLAS cattle run was interrupted and retained locally, marked interrupted. Its partial measurements are excluded from published results.

[Environment rebuild recipe](https://github.com/psoerensen/gpct/tree/main/environment)
contains source commits, dependency hashes, the isolated OpenBLAS build, preflight
and numerical checks. Local source repositories were used as caches; all pinned
commits were contained in their recorded origin/main references. This is not a
fresh network-only rebuild test. The recipe requires access to any private sources.
No gtools package release was published.

Source trait definitions, upstream processing, original IDs and genomic annotations
remain unverified. These are random within-cohort execution pilots, not full-genome
comparisons or evidence of transfer across populations.

## Historical scaffold and template records

## Initially performed

- Inspected authenticated GitHub account (`psoerensen`); `gpct` was absent.
- Created an empty public repository before the user asked to keep subsequent work local.
- Initialized a separate local Git repository in the empty gpct directory.
- Read public GPBench card, file-tree API, upstream README and Crossref DOI record.
- Downloaded the 303,192,374-byte archive to a temporary directory outside git.
- Verified archive SHA-256 against Hugging Face LFS metadata.
- Read cattle and maize NPZ arrays with NumPy 2.3.5, `allow_pickle=False`:
  dimensions, dtypes, traits, genotype range and finite counts match the registry.
- Inspected actual gbayes/glma/gcorr/gsuite R documentation and gbayes examples
  from the existing sibling checkout read-only; inspected published rrBLUP API/source.

- Checked that both registry rows match the machine-readable inspection record,
  including dimensions, trait labels, genotype values and finite outcome counts.
- Resolved all 28 local Markdown links and checked that source/documentation
  files are small and contain no ZIP/NPZ/RDS/BED/NPY artifacts.
- Checked Git whitespace and staged-file exclusions before the local commit.

Detailed machine-readable array evidence is in
`datasets/inspection.json`. No individual source data is included in that file.

## Initial limits and later updates

No R installation or Rscript executable was found on PATH or in the checked
standard R installation locations, including a read-only host check. Therefore
installed R package availability could not be established. No packages were
installed or rebuilt, and no sibling package checkout was modified.

At the initial scaffold delivery the R scripts and protocol checks had not been
executed. The later reporting checks below supersede that test-status statement.
No model was fitted. Package/native compatibility, R/reticulate conversion, convergence,
end-to-end outputs and runtime/memory costs remain unverified. In particular,
the inspected gbayes source labels its dense prepared-design adapters as pending
runtime qualification; this scaffold does not certify them.

At the initial local-only delivery no content was pushed and Pages was not
enabled. Later requested website updates were committed, pushed and verified
on the public Pages site. Prediction results remain unavailable.

## Next execution steps

1. Select an existing R installation and existing package/Python environments.
2. Run `scripts/check_dependencies.R`; resolve missing dependencies separately
   without altering shared installations used by other sessions.
3. Read and acknowledge positional sample alignment and source rights/processing limits.
4. Run `tests/check_protocol.R`, then prepare and run cattle and maize using the
   [documented commands](benchmarks.html).
5. Inspect failures, diagnostics and all fold outputs. Record installed versions
   and mark a recipe runnable only after a successful actual run.
6. Confirm original citations, units, IDs and genotype annotations before broader
   benchmarks; publish only reviewed aggregate results and then enable Pages.

## Website presentation update

The public gact Pages HTML and stylesheet were inspected on 2026-11-21.
gpct now selects the same standard `jekyll-theme-primer` theme and includes an
editable SVG explaining the prediction benchmark workflow. Its caption and
status text explicitly distinguish the planned process from measured results.

The SVG was rendered and visually inspected. A local HTML preview using the
public Primer stylesheet was checked in the browser. SVG XML and local links
were checked. Ruby/Jekyll is not available in the checked environment, so a
full Jekyll build and deployed Pages appearance remain unverified. This update
does not change or execute the statistical recipes.

## Reporting templates and checks

On 2026-11-21, `tests/check_protocol.R` and `tests/check_reporting.R` passed under
base R 4.6.0 using an isolated WebR 0.6.1 runtime in ignored local output files.
The Windows path handling of that disposable runtime's JavaScript loader was
adapted locally; no shared R installation or sibling package checkout changed.
Changed R sources were parsed in that runtime.

Checks cover pooled predictive R² with each test individual's training-fold
mean, separation from fold-average metrics, paired baseline changes, constant
predictions, failed/missing fits, duplicate IDs, fold mismatches, inconsistent
outcomes, unavailable resources and exclusion of individual artifacts from
generated reports. Synthetic output was removed, not published as results.
An intentionally failing synthetic runner case also verified per-fold failure
rows, method elapsed times, case elapsed time and explicit unmeasured RAM.

Blank CSVs, detailed report templates and four static SVG plot types were
generated from `scripts/report_prediction.R` using base R graphics. New runner
fields record method/case elapsed time, warning counts, requested worker count
and explicit unavailable actual-thread/peak-RAM measurements. Native benchmark
packages and fits remain unexecuted; timing instrumentation has not been
exercised around a real package fit.

Local page verification for this results update used an HTML preview with the
existing Primer stylesheet: desktop plots were visually inspected, all four SVGs
loaded, and the 390-pixel mobile case page kept tables/figures in local scroll
containers without page overflow. Local links across 14 rendered pages and all
SVG XML parsed successfully. R reporting checks passed again after the reporting
metadata update. GitHub Pages performs the full Jekyll build after publication.
