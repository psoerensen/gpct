# Results publication policy

The cattle/mkg and maize/DTT 512-marker pilots completed on 2026-11-21. Reviewed aggregate tables and plots are published under `docs/assets/reports/20261121-openblas/` with [results](../docs/results.md) and detailed case pages. All three methods completed five folds in each case; no individual outputs are public. Blank templates remain separately labelled.

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
