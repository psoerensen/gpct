# Benchmark recipes

Run from the repository root with the pinned environment activated and external
GPCT_DATA_DIR/GPCT_OUTPUT_DIR paths.

- `prepare.R`: pinned archive extraction and source data contract.
- `npz_to_plink.py`, `prepare_glist.R`: exact PLINK conversion, explicit synthetic metadata, native gbase QC and selected Glist.
- `gpbench_folds.py`: saved ten-fold sklearn partitions, seed 42.
- `run_gbayes.R METHOD DATASET`: native gbayes Glist fit/predict, with explicit worker/chain settings and incremental per-fold local outputs; normally launched by the benchmark driver.
- `publish_gbayes.R`: aggregate-only CSVs, four SVG plots and current result pages after a method completes both datasets.
- `summarise_thread_probe.R`: checks identical seeded outputs for four logical chains at one/four concurrent workers and reports both fitting and native-sampler speedups.

`environment/run-glist-benchmark-plan.ps1` runs measurements serially, performs the
matched threading probes and practical two/four-chain checks, then runs ten-fold
cattle/maize CV with four concurrent chains and one BLAS thread. It updates/checks
local aggregate pages after each completed method. Each chain uses 500 burn-in
and 1000 retained transitions. Results with weak
parameter mixing are explicitly provisional. No commit or push is performed.
When the saved RHE + BLUP receipts are available, `publish_gbayes.R` and
`publish_rhe_report.R` publish the aggregate diagnostics for both datasets.
Fitting uses the separately maintained native implementation and private adapter.

`benchmarks/methods.R` is the method/settings registry. The earlier experimental
fitters and report routes are retired; no compatibility paths are maintained.
