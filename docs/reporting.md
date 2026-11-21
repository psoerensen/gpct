---
layout: default
title: Reporting benchmarks
---
# Reporting benchmarks

Generate measured reports outside the checkout, then review before copying an
explicit aggregate-file allowlist to the website:

```powershell
Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY
```

Existing report destinations are refused. No report generation fits a model,
installs software, or publishes individual artifacts.

| Output | Meaning |
| --- | --- |
| dataset_catalogue.csv | Source scope, observed/imputed targets and available/used markers |
| method_settings.csv | Installed package versions, model, REML/VB controls and tuning |
| software_sources.csv | Software versions and exact private implementation repository commits |
| benchmark_results.csv | Means of ten fold metrics, costs, convergence, failures and links |
| fold_results.csv | Aggregate metrics/status for every method and test fold |
| pooled_results.csv | Metrics from all OOF predictions, separately labelled |
| observed_only_metrics.csv | Fold-averaged evaluation excluding imputed target labels |
| calibration_bins.csv | Public aggregate bin counts and means, at least five samples per bin |
| solver_checks.csv | Fixed-variance prediction agreement; solve timing excludes REML |
| run_metadata.csv | Input/source identity, splits, imputation counts, loaded BLAS and hardware |
| recipe_checksums.csv | Run-time byte MD5 and canonical LF SHA-256 identities of recipes |
| identity_checks.csv | Equality of input, saved folds, outcomes, target flags and BLAS when combining execution batches |
| fit-sessionInfo.txt | R packages loaded during fitting, labelled by execution batch |
| Four SVGs | Performance, RMSE reduction versus training mean, performance/workflow time and calibration |

Review the full ten-fold coverage, common source identities/outcomes, imputed
label flags, convergence, warnings and failures. Main scores must be fold means,
with test-fold-mean R2. Keep pooled metrics separate. Fold SD is descriptive,
not a confidence interval. Missing resources remain NA rather than zero.
gbayes fold summaries also retain the prior variance, inclusion probability,
sweep count, convergence status and native decoded-backend/source-read diagnostics.
Native source-read seconds are included in fitting and must not be added again.
Maximum-sweep results keep provisional status and their measured scores/costs.

Fitting and prediction seconds sum ten calls. Workflow seconds also include
matrix extraction for gbayes, or kernel construction and per-fold block preparation for greml/gsolve. gbayes fit time includes training-prior calculation and native projection. The data-only
kernel is reusable across folds and never uses phenotypes. Whole-case time includes
shared work and saving; solver checks run separately, so it is not a per-method number.
One execution does not establish timing uncertainty. Backend differences are explicit.

Do not copy whole run folders. Keep individual predictions, fold assignments,
raw diagnostics, saved fits and private source/binaries external. Publish only
reviewed CSVs/SVGs, a reporting session summary and the corresponding case page.
