# Results publication policy

Only reviewed aggregate tables, plots and provenance summaries belong in the
public website. Current full-marker benchmark assets live under
`docs/assets/reports/20261121-gsuite-models/` after review and publication.

Generate reports externally using scripts/report_prediction.R. Check every test
fold, convergence, warnings, failed fits, common splits/outcomes, imputed-target
handling, metric aggregation and complete-workflow timing. Compare results with
the pinned authors' reference table without treating rounded agreement as proof
of identical hidden processing or original source permissions.

Publish an explicit allowlist: aggregate CSVs, four SVG types, recipe checksums,
reporting session information and curated case pages. Mean-imputed targets are
counted and a genuine-observation sensitivity summary stays separate. Calibration
bins contain at least five observations; folds are descriptive partitions rather
than independent experimental replicates.

Do not publish individual genotypes, phenotypes, predictions, fold assignments,
saved fit objects, raw diagnostics, private numerical implementation source or
binaries. No gtools package release is part of benchmark publication. Complete
run evidence remains in external GPCT_DATA_DIR/GPCT_OUTPUT_DIR locations.

The former small-marker reports are retired once the full-marker comparison is
published. No backward compatibility, redirects or historical asset mirror is
required. Retiring public pages does not authorize deleting private data, logs,
source caches or run evidence.
