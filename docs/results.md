---
layout: default
title: Results
---
# Benchmark comparisons

**No prediction benchmark has been executed. All tables and plots below are report templates, with measured values left unavailable.**

Every prediction report answers three questions: **What was compared? How well
did it work? What did it cost?** Compare methods within a dataset–trait pair.
The [cattle report](reports/cattle.html) and [maize report](reports/maize.html)
use the same page order while retaining their own target definitions and units.

## What was compared?

### Dataset catalogue

| Species | Dataset | Trait / phenotype definition | Available / eligible individuals | Available markers | Planned pilot markers | Actually fitted markers | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cattle | GPBench Cattle | Supplied `mkg`; definition, adjustments and units unverified | 5,024 / 5,024 | 42,551 | 512 | Not run | [GPBench](https://huggingface.co/datasets/xw97/GPBench) |
| Maize | GPBench Maize | Supplied `DTT`; definition, adjustments and units unverified | 1,458 / 1,456 | 75,304 | 512 | Not run | [GPBench](https://huggingface.co/datasets/xw97/GPBench) |

**Available markers are not markers used.** The pilot selects 512 source columns;
training-constant markers may be dropped separately in each fold. Reports retain
the minimum and maximum actually fitted counts. No fitted count is claimed yet.

[Dataset catalogue CSV](assets/reports/templates/dataset_catalogue.csv)

### Method settings

| Method | Package / installed version | Model settings | Tuning strategy | Convergence criteria |
| --- | --- | --- | --- | --- |
| REML rrBLUP | rrBLUP / not run | Training-only REML ridge; variance-ratio bounds 1e-9 to 1e9 | Training-only variance estimation; no CV tuning | Optimizer result; no convergence flag exposed |
| Fixed Gaussian | gbayes / not run | Standardized response; residual variance 0.5; prior variance 0.5/p | Fixed predeclared pilot settings | Native tolerance 1e-8; 2,000-iteration cap; inspect diagnostics |
| Elastic net | gbayes / not run | Standardized response; lambda 0.1; alpha 0.5 | Fixed predeclared pilot settings | Native tolerance 1e-8; 2,000-iteration cap; inspect diagnostics |

These are the same settings in both pilots. Source package versions are not
installed versions. Actual reports take versions from each run's recorded
environment. gbayes requests one package worker; rrBLUP/BLAS thread control and
actual thread usage are not measured here.

[Method settings CSV](assets/reports/templates/method_settings.csv)

## How well did it work, and what did it cost?

### Results-table template

Main metrics use **pooled out-of-fold predictions**. All metric/cost dashes below
mean not run, not measured or undefined, never zero. The downloadable CSV keeps
these as `NA` with explicit status and RAM-measurement fields.

| Dataset / trait | Method | Predictive ability | RMSE | Predictive R² | Calibration slope | Fit (s) | Predict (s) | Peak RAM (MB) | Status | Recipe | Detailed report |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cattle / mkg | REML rrBLUP | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/cattle_prediction) | [Cattle](reports/cattle.html) |
| Cattle / mkg | Fixed Gaussian | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/cattle_prediction) | [Cattle](reports/cattle.html) |
| Cattle / mkg | Elastic net | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/cattle_prediction) | [Cattle](reports/cattle.html) |
| Maize / DTT | REML rrBLUP | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/maize_prediction) | [Maize](reports/maize.html) |
| Maize / DTT | Fixed Gaussian | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/maize_prediction) | [Maize](reports/maize.html) |
| Maize / DTT | Elastic net | — | — | — | — | — | — | — | Planned | [Recipe](https://github.com/psoerensen/gpct/tree/main/benchmarks/maize_prediction) | [Maize](reports/maize.html) |

[Summary CSV](assets/reports/templates/benchmark_results.csv) ·
[Fold-results template](assets/reports/templates/fold_results.csv) ·
[Separate fold-average template](assets/reports/templates/fold_metric_means.csv)

### Predictive performance

Horizontal dots will compare methods within each dataset–trait pair. Filled dots
show pooled OOF predictive ability; open dots show fold values as descriptive
variation. There are no confidence intervals and no measured dots yet.

<figure class="report-figure">
  <img src="{{ '/assets/reports/templates/performance.svg' | relative_url }}" alt="Empty predictive-performance plot template with separate cattle/mkg and maize/DTT panels and rows for the three planned methods; no measured dots.">
</figure>

[Open full-size performance SVG](assets/reports/templates/performance.svg)

### Improvement over baseline

The zero line denotes no difference from REML rrBLUP. Reports calculate the
difference in pooled predictive ability and a separate relative RMSE reduction
`1 - RMSE_method / RMSE_baseline`. Fold differences use matched folds. A failed
or unavailable baseline leaves improvement unavailable.

<figure class="report-figure">
  <img src="{{ '/assets/reports/templates/improvement.svg' | relative_url }}" alt="Empty baseline-improvement plot template with a zero reference line and separate panels for cattle/mkg and maize/DTT; no measured improvements.">
</figure>

[Open full-size improvement SVG](assets/reports/templates/improvement.svg)

### Performance versus runtime

Fitting seconds are on the x-axis; pooled predictive ability is on the y-axis;
colour identifies methods. This plot requires both measurements. Fitting time
is not total execution time. Prediction time, per-method elapsed time and whole
case elapsed time have separate CSV columns. Peak RAM remains **not measured**.

<figure class="report-figure">
  <img src="{{ '/assets/reports/templates/runtime.svg' | relative_url }}" alt="Empty performance-versus-fitting-time template with separate dataset/trait panels and a method-colour legend; no runtime or predictive scores have been measured.">
</figure>

[Open full-size runtime SVG](assets/reports/templates/runtime.svg)

### Calibration

Plot binned mean observed phenotype against binned mean prediction with an
identity line. Each dataset–trait pair retains its own units. Individual
prediction plots stay local. Only reviewed aggregate means and counts are
eligible for publication; miniature schematic charts on the homepage are not results.

<figure class="report-figure">
  <img src="{{ '/assets/reports/templates/calibration.svg' | relative_url }}" alt="Empty aggregate-calibration template with an identity line in each dataset/trait panel; no observed or predicted individual values are published.">
</figure>

[Open full-size calibration SVG](assets/reports/templates/calibration.svg) ·
[Calibration-summary CSV schema](assets/reports/templates/calibration_bins.csv)

## Summary and uncertainty rules

- Derive summaries from saved local OOF predictions, preserving sample/fold alignment.
- Keep pooled scores and means of fold metrics distinct. Predictive R² uses each
  individual's own training-fold mean in the pooled denominator.
- Show the five fold values alongside the aggregate; folds are not independent
  experimental replicates and no confidence intervals are implied.
- Do not combine raw RMSE across traits with different units.
- Keep failed/incomplete fits, warnings, unknown convergence, unavailable timing
  and unmeasured RAM explicit. Incomplete methods do not receive pooled rankings.
- Record requested workers separately from actual thread usage. Missing historical
  measurements stay unavailable; managed memory budgets are not peak RAM.

## Generate a report from a real run

```text
Rscript --vanilla tests/check_reporting.R
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

This creates static SVGs, aggregate CSVs and a detailed `report.md` beside the
local run. It does not publish them. Review the output before copying selected
summaries into the website. See the [reporting guide](reporting.html) for commands,
file definitions, timing scope and the publication procedure.

Repeated validation can be added later with identical splits across methods.
Add a baseline-improvement heatmap when enough datasets and traits exist.
Association and genetic-correlation benchmarks will have their own tables and
plots, matching their different evaluation questions.

Individual data, out-of-fold predictions and fold membership are not published
by default. See the [evaluation definitions](protocol.html) and publication
policy in the repository's `results/README.md`.
