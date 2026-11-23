---
layout: default
title: Genomic prediction benchmarks
---
<!-- report-version:ed93c843218e7eb7 -->
<h1 class="page-heading">Genomic prediction benchmarks</h1>

**gpct** compares methods in the gsuite ecosystem: how accurately they predict, how long they take, and how much memory they use.

[View results and timings](results.html)

<figure class="overview-figure">
  <a href="{{ '/assets/images/gpct-overview.svg' | relative_url }}?v={{ site.time | date: '%s' }}" aria-label="Open the full-size gpct overview SVG">
    <img src="{{ '/assets/images/gpct-overview.svg' | relative_url }}?v={{ site.time | date: '%s' }}" width="1152" height="576" alt="Overview of the gpct benchmark collection: documented cattle and maize genotypes and traits feed shared validation and existing R methods. Schematic miniature plots illustrate predictive ability, error, calibration, computational cost and across-fold variation. Reproducible comparisons retain recipes, settings, versions and diagnostics, with reviewed summaries on GitHub Pages. Human datasets, simulations, glma association and gcorr genetic-correlation benchmarks are shown as planned extensions.">
  </a>
  <figcaption>The gpct benchmark collection connects documented datasets, shared validation, existing statistical methods, and reproducible comparisons. Miniature plots are schematic; future extensions are marked separately.</figcaption>
</figure>

[Open the full-size figure]({{ '/assets/images/gpct-overview.svg' | relative_url }}).

Current benchmarks cover cattle milk yield (**mkg**) and maize flowering time (**DTT**), using shared ten-fold validation and Glist.

[Datasets](datasets.html) · [Methods](methods.html)

Recipes and recorded settings support reproducible comparisons.

[Explore the repository or contribute](https://github.com/psoerensen/gpct).
