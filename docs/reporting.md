---
layout: default
title: Reporting prediction benchmarks
---
# Reporting prediction benchmarks

Use `scripts/report_prediction.R` from the repository root. It uses base R for
summary calculations, Markdown reports and static SVG plots. No plotting package
or workflow engine is required. It never fits a model or installs dependencies.

## Generate and inspect

After a pilot run has written its local artifacts:

```powershell
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/report_prediction.R 'C:/results/gpct/cattle/RUN_ID'
```

The new `RUN_ID/report/` directory contains the bundle below. Existing report
destinations are refused; an optional second argument names another new output
directory. Measured reports must be generated outside the checkout. If the run
failed before creating settings, saved folds, versions or fold performance,
inspect `run_status.csv` and resolve that failure before attempting a summary.

| File | Meaning |
| --- | --- |
| `dataset_catalogue.csv` | Phenotype/scope, available and eligible samples, available/planned markers, recorded fitted-marker range and source |
| `method_settings.csv` | Recorded package versions, method settings, tuning, convergence criteria and worker controls |
| `benchmark_results.csv` | Pooled OOF metrics, cost, status, baseline changes, recipe and detailed-report links |
| `fold_results.csv` | Per-method, per-fold metrics and statuses; no IDs or individual predictions |
| `fold_metric_means.csv` | Arithmetic means of the five fold metrics, clearly labelled separately from pooled scores |
| `calibration_bins.csv` | Aggregate bin counts, mean predictions and mean observed phenotype |
| `run_metadata.csv` | Dataset/trait, source revision, input checksum where available, seeds and reporting R version |
| `performance.svg` | Pooled and descriptive fold predictive-ability dots |
| `improvement.svg` | Predictive-ability difference from rrBLUP, with matched fold differences and a zero reference |
| `runtime.svg` | Pooled predictive ability versus summed fitting seconds |
| `calibration.svg` | Aggregate observed-versus-predicted bin means and identity line |
| `report.md` | Detailed page in the standard six-section order |
| `report-sessionInfo.txt` | Environment used for reporting; the original run retains its own sessionInfo |

The reader validates unique prediction IDs per method, saved fold membership,
common outcome values and training-mean references across methods. It recomputes
scores from OOF predictions. Each pooled score requires all five successful folds
and exactly the saved eligible sample set. Failed or missing folds remain visible
and withhold the method's pooled score, baseline change and calibration plot.

Undefined metrics also remain NA: constant predictions have no correlation or
calibration slope, zero reference scatter has no predictive R², and zero baseline
RMSE has no defined relative reduction. Status and metric availability are separate.
Reports preserve provisional convergence status; raw diagnostic objects remain local.

## What the summaries mean

Pooled OOF predictive R² is
`1 - sum((observed-predicted)^2) / sum((observed-training_fold_mean)^2)`.
It is not squared correlation. Fold means are arithmetic averages of the five
separately calculated metrics and are not interchangeable with pooled scores.
If a metric is undefined in a fold, its fold mean is unavailable rather than an
average over only the remaining folds.

Baseline changes are calculated only within each dataset–trait pair. The figure
uses `PA_method - PA_rrBLUP`; the CSV also records
`1 - RMSE_method / RMSE_rrBLUP` as a fraction, positive for improvement.
Fold changes use matching saved folds. Open dots show descriptive partition
variation, not an uncertainty interval. There are no confidence intervals for
the initial single five-fold run.

Calibration uses up to ten quantile bins of pooled OOF predictions per method.
Ties can reduce the number of bins. Bins containing fewer than five samples are
omitted; bin counts accompany the means. This is a diagnostic of calibration,
not recalibration of predictions. Review even these aggregates before release.

## Cost and thread measurements

The runner now records `fit_seconds`, `prediction_seconds`,
`method_elapsed_seconds`, `warning_count`, requested workers, actual threads and
peak-RAM availability per fold. It also writes `execution.csv` for the case.

- Fitting seconds measure the package fit call; prediction seconds measure the
  prediction call. Both use elapsed wall time.
- Method elapsed covers method loading/checks, fit, diagnostics, prediction and
  evaluation; it excludes shared data loading/preparation and per-row CSV writes.
- Case elapsed includes shared work and all methods, from runner start through
  session recording. It is reported as context and must not be summed over methods.
- gbayes explicitly requests `ncores=1`. rrBLUP does not expose a worker-count
  argument; BLAS/OpenMP can use their own threads. Actual usage stays NA unless
  measured. Relevant thread environment variables are retained in local execution records.
- Peak RAM is **not measured** by this runner. Its NA is not zero, R object size,
  a configured memory budget or a claim about process memory. Later OS-level
  measurements need their scope/unit documented before filling that field.

Old runs lacking new fields remain usable: unavailable timing, warning counts,
actual threads, peak RAM and case totals stay NA. No historical measurements
are inferred. The runtime plot uses fitting time and only complete score/time pairs.

## Templates and publication

To regenerate the blank templates into a new directory:

```text
Rscript --vanilla scripts/report_prediction.R --templates NEW_DIRECTORY
```

This writes the collection template plus separate cattle and maize bundles.
There are no fake performance values. The checked-in templates were generated
and tested with base R 4.6.0 in an isolated WebR runtime; native package fitting
has not been executed. See [verification](verification.html).

For a real release, choose a stable public URL for that run report and optionally
set `GPCT_REPORT_URL` before generation so its summary CSV points there. The
default links to the corresponding benchmark's detailed page.

Review the summary CSVs, all fold statuses, aggregate bins, plot labels, settings,
versions, checksum, timings and convergence limitations. Copy only the reviewed
bundle's aggregate files into an appropriate `docs/assets/reports/<run-id>/`
directory, move/adapt `report.md` to the desired page and adjust its relative
artifact links. Update the results table and case status deliberately. Do not
copy the source run directory, individual predictions, folds, raw messages or
diagnostics into the site. Commit/publish only after that review.

Repeated validation and a baseline-improvement heatmap remain future additions.
Association and genetic-correlation methods need separate reporting schemas,
ground truth and evaluation measures.
