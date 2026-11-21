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

## Glist-based gbayes benchmarks

The current collection uses existing gbayes C++ methods through Glist with
**one worker**, starting with cattle mkg and maize DTT. The route is
BED/BIM/FAM → MAF/missingness QC → Glist → identical training folds → native
gbayes fitting → held-out prediction. HWE is reported without filtering.

Cattle retains 42,373 of 42,551 available markers; maize retains all 75,304.
Every method uses the same saved ten-fold splits, seed 42. Native method-specific
coding and fitting are preserved. Results are added after a method completes
both datasets. The previous experimental results have been retired.

Read the [dataset catalogue](datasets.html), [Glist/QC record](genotype-preparation.html),
[recipes](benchmarks.html), [methods](methods.html), [protocol](protocol.html)
and [results and timings](results.html).

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
