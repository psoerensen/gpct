---
layout: default
title: Reproducible genomic prediction
---
# Reproducible genomic prediction

**gpct** collects datasets, ordinary R analysis recipes, execution instructions
and reviewed results for genomic prediction and related statistical genetics.
Existing packages perform the computation. gpct is a benchmark collection.

## Start with two explicit pilots

| Case | Dataset | Target | Status |
| --- | --- | --- | --- |
| Cattle prediction | GPBench Cattle | supplied mkg | Planned; R execution pending |
| Maize prediction | GPBench Maize | supplied DTT | Planned; R execution pending |

Each pilot uses 512 predeclared source marker columns, the same saved five-fold
splits across methods (seed 4401), training-only processing and predictions on
the source trait scale. The baseline is REML rrBLUP, compared with fixed Gaussian
and elastic-net gbayes fits. These are execution pilots, not genome-wide rankings.

Read the [dataset catalogue](datasets.html), [reproduction commands](benchmarks.html),
[package interfaces](methods.html) and [evaluation protocol](protocol.html).
There are [no benchmark performance results yet](results.html).

## Contribute

Add source provenance and rights to the registry, a small R config and recipe,
and an explicit scientific question and validation design. Preserve sample
identity, report failures, and distinguish planned, runnable and completed cases.
Animal, plant and appropriately consented human datasets are welcome.

The [repository](https://github.com/psoerensen/gpct) contains the full local
scaffold once the owner pushes it. See its `CONTRIBUTING.md` for the checklist.
Only reviewed aggregate results and small supporting artifacts should be public.
Individual genotypes, phenotypes, predictions and folds stay outside git.

Local verification and limitations are recorded on the [verification page](verification.html).
