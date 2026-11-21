---
layout: default
title: Reproducible genomic prediction
---
<h1 class="page-heading">Reproducible genomic prediction and statistical genetics benchmarks</h1>

**gpct** collects datasets, ordinary R analysis recipes, execution instructions
and reviewed results for genomic prediction and related statistical genetics.
Existing packages perform the computation. gpct is a benchmark collection.

<figure class="workflow-figure" tabindex="0" aria-label="Benchmark workflow; scroll horizontally on smaller screens">
  <a href="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}" aria-label="Open the full-size gpct workflow figure">
    <img src="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}" width="1120" height="620" alt="GPBench cattle and maize genotypes and traits enter shared five-fold validation with seed 4401. Existing R packages fit each training fold, then predict held-out samples. Evaluation records predictive ability, error, calibration, timings and failures. Individual records stay local; only reviewed aggregate summaries go to the public site. Both initial cases are planned; no prediction results are available yet.">
  </a>
  <figcaption>From source datasets to reproducible comparisons: every method uses the same held-out samples. Individual data stay local; reviewed aggregate results can be shared. The figure describes the workflow, not measured performance.</figcaption>
</figure>

## What gpct is for

Use gpct to make prediction comparisons traceable: which dataset and trait were
used, which samples were held out, how each method was fitted, and how its
predictions performed. Start with cattle and maize, then extend the same
documented approach to further animal, plant and human datasets.

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

The [repository](https://github.com/psoerensen/gpct) contains the benchmark
recipes and documentation. See its `CONTRIBUTING.md` for the checklist.
Only reviewed aggregate results and small supporting artifacts should be public.
Individual genotypes, phenotypes, predictions and folds stay outside git.

Local verification and limitations are recorded on the [verification page](verification.html).
