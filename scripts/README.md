# Benchmark recipes

Run from the repository root with the pinned environment activated and external
GPCT_DATA_DIR/GPCT_OUTPUT_DIR paths.

- `prepare.R`: pinned archive extraction and source data contract.
- `npz_to_plink.py`, `prepare_glist.R`: exact PLINK conversion, explicit synthetic metadata, native gbase QC and selected Glist.
- `gpbench_folds.py`: saved ten-fold sklearn partitions, seed 42.
- `run_gbayes.R METHOD DATASET`: one-worker existing gbayes Glist fit/predict, with incremental per-fold local outputs.
- `publish_gbayes.R`: aggregate-only CSVs, four SVG plots and current result pages after a method completes both datasets.

`benchmarks/methods.R` is the method/settings registry. The earlier experimental
fitters and report routes are retired; no compatibility paths are maintained.
