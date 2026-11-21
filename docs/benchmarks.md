---
layout: default
title: Benchmark recipes
---
# Benchmark recipes

The current collection evaluates existing gbayes prediction methods from
QC-selected Glist with one worker. Each method completes cattle and maize
before its aggregate results are added to the website.

| Dataset | Trait | Individuals | Available markers | QC-retained markers | Report |
| --- | --- | ---: | ---: | ---: | --- |
| GPBench cattle | mkg | 5,024 | 42,551 | 42,373 | [Cattle](reports/cattle.html) |
| GPBench maize | DTT | 1,458 | 75,304 | 75,304 | [Maize](reports/maize.html) |

All methods use the same saved ten-fold partitions, seed 42. The two imputed
maize DTT outcomes remain flagged. See [dataset provenance](datasets.html),
[Glist preparation](genotype-preparation.html), [settings](methods.html) and
[evaluation protocol](protocol.html).

```powershell
./environment/run-method.ps1 -Method marker_gaussian
Rscript --vanilla scripts/publish_gbayes.R
```

The runner calls gbayes fitting and native held-out prediction directly with
Glist. Individual data, fits and diagnostics stay in external directories.
Only reviewed summaries and static SVG plots enter the site.
