---
layout: default
title: Verification record
---
# Verification record

Inspection date: **2026-11-21**.

## Actually performed

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

## Not performed

No R installation or Rscript executable was found on PATH or in the checked
standard R installation locations, including a read-only host check. Therefore
installed R package availability could not be established. No packages were
installed or rebuilt, and no sibling package checkout was modified.

The R scripts and `tests/check_protocol.R` have **not been executed**. No model
was fitted. Package/native compatibility, R/reticulate conversion, convergence,
end-to-end outputs and runtime/memory costs remain unverified. In particular,
the inspected gbayes source labels its dense prepared-design adapters as pending
runtime qualification; this scaffold does not certify them.

No scaffold content was pushed. GitHub Pages was not enabled, built or checked
in a browser. The website source is prepared for later standard branch publishing.

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
