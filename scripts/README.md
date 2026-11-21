# Scripts

Invoke all scripts with `Rscript --vanilla` from the repository root.

| Script | Purpose |
| --- | --- |
| `check_dependencies.R` | Report installed versions and Python/NumPy; installs nothing |
| `prepare.R cattle` / `prepare.R maize` | Verify archive and prepare a positional 512-marker pilot |
| `paths.R` | Enforce external artifact directories |
| `evaluate.R` | Saved five-fold partitions, training-only preparation and metrics |
| `run_prediction.R` | Shared thin recipe sourced by each case's `run.R` |

No statistical optimizer is implemented here. Fitting uses `rrBLUP::mixed.solve`
and `gbayes::bayes`. Folds and seeds are saved, with `RNGkind` fixed. Each run has
a fresh timestamp/PID directory; set `GPCT_RUN_ID` for an explicit unique label.
Existing run directories are refused. Changing eligible sample IDs causes a
saved-fold mismatch error; retain the old folds as provenance and use a separate
`GPCT_DATA_DIR` for a new protocol. The same IDs reuse folds even if values change;
the prepared input checksum distinguishes such runs.

Failures create `run_status.csv`; method-specific failures are also recorded in
`performance.csv` and remaining method/fold combinations continue. Fatal input
or preprocessing failures stop the run with a nonzero exit code. Timings use
elapsed wall seconds and separate package fitting from prediction. Diagnostics
serialization and shared preprocessing are excluded from those two timings.
Failed fitting/prediction calls retain elapsed time to failure; a stage that was
never reached has an unavailable time.

All local outputs may contain sensitive individual information. They are not
automatically copied to `results/` or the website.
