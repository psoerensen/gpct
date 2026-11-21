---
layout: default
title: Reproducible genomic prediction
---
<h1 class="page-heading">Reproducible genomic prediction and statistical genetics benchmarks</h1>

**gpct** collects datasets, ordinary R analysis recipes, execution instructions
and reviewed results for methods and models implemented in the gsuite ecosystem,
covering genomic prediction and related statistical genetics.

<figure class="overview-figure">
  <a href="{{ '/assets/images/gpct-overview.svg' | relative_url }}" aria-label="Open the full-size gpct overview SVG">
    <img src="{{ '/assets/images/gpct-overview.svg' | relative_url }}" width="1152" height="576" alt="Overview of the gpct benchmark collection: documented cattle and maize genotypes and traits feed shared validation and existing R methods. Schematic miniature plots illustrate predictive ability, error, calibration, computational cost and across-fold variation. Reproducible comparisons retain recipes, settings, versions and diagnostics, with reviewed summaries on GitHub Pages. Human datasets, simulations, glma association and gcorr genetic-correlation benchmarks are shown as planned extensions.">
  </a>
  <figcaption>The gpct benchmark collection connects documented datasets, shared validation, existing statistical methods, and reproducible comparisons. Miniature plots are schematic; future extensions are marked separately.</figcaption>
</figure>

[Open the full-size overview SVG]({{ '/assets/images/gpct-overview.svg' | relative_url }}).

## What gpct is for

Use gpct to make prediction comparisons traceable: which dataset and trait were
used, which samples were held out, how each method was fitted, and how its
predictions performed. Start with cattle and maize, then extend the same
documented approach to further animal, plant and human datasets.

## Two matched full-marker benchmarks

| Case | Dataset | Target | Status |
| --- | --- | --- | --- |
| Cattle prediction | GPBench Cattle | supplied mkg | Completed; [results](results.html) |
| Maize prediction | GPBench Maize | supplied DTT | Completed; [results](results.html) |

Both benchmarks use all supplied markers, the same saved GPBench ten-fold splits (seed 42), raw dosage coding and genomic BLUP through our greml/gsolve interfaces. REML estimates variance components before BLUP prediction. A separate fixed-variance check tests our solver. Mean-imputed maize targets are explicitly flagged.

Read the [dataset catalogue](datasets.html), [reproduction commands](benchmarks.html), [interfaces](methods.html), [protocol](protocol.html) and [results and timings](results.html).

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
