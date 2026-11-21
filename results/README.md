# Results publication policy

No benchmark performance results are available. Both initial cases are planned.

The [website results source](../docs/results.md) now contains standard dataset,
method and result tables, four empty plot templates, and links to separate
cattle/maize report pages. Generated blank CSV/SVG bundles live under
`docs/assets/reports/templates/`; all measurement columns are unavailable.

After a real run, `Rscript --vanilla scripts/report_prediction.R RUN_DIRECTORY`
generates pooled and per-fold aggregate CSVs, four static SVGs and `report.md`
under a new local report directory. This does not publish any output. Review
the bundle using `docs/reporting.md`, then copy selected aggregate files only.

Complete run artifacts belong under the external `GPCT_OUTPUT_DIR`, including
predictions, fold membership, settings, diagnostics, timings and sessionInfo.
These can contain individual information. Do not copy whole run directories here.

After a successful, reviewed run, manually select small aggregate tables and
static figures. Include the case, target units/adjustment limits, marker scope,
input/config checksum, all five fold values, packages, seeds, hardware/timing
scope, convergence caveats and explicit failure counts. Document aggregation;
never average only the successful folds without saying so. Individual results
need a separate rights/privacy review and are excluded by default.

Update `docs/results.md` and case status only when there is real execution
evidence. A successful script exit alone does not certify numerical convergence
or scientific validity. No placeholder performance numbers belong here.
