---
layout: default
title: Benchmark recipes
---
# Benchmark recipes

The current collection evaluates native gsuite prediction methods from
QC-selected Glist. Full MCMC runs use four concurrent chains and one BLAS thread.
Ordinary RHE + BLUP instead uses one fit with up to four native MKL threads.
Each method is evaluated on cattle and maize. Failed fits remain visible;
aggregate accuracy requires all ten held-out folds to be accepted.

| Dataset | Trait | Individuals | Available markers | QC-retained markers | Report |
| --- | --- | ---: | ---: | ---: | --- |
| GPBench cattle | mkg | 5,024 | 42,551 | 42,373 | [Cattle](reports/cattle.html) |
| GPBench maize | DTT | 1,458 | 75,304 | 75,304 | [Maize](reports/maize.html) |

All methods use the same saved ten-fold partitions, seed 42. The two imputed
maize DTT outcomes remain flagged. See [dataset provenance](datasets.html),
[Glist preparation](genotype-preparation.html), [settings](methods.html) and
[evaluation protocol](protocol.html).

The retained local development checkout uses the following entry point. It
requires the qualified, unreleased gbayes build and local controller identified
in the settings and checksums; this aggregate website update does not release
those implementation changes.

```powershell
./environment/run-glist-benchmark-plan.ps1
```

The command above runs the gbayes collection. The retained private RHE recipe
uses the same Glist inputs and splits with existing greml/gsolve/gbits routines;
see its [evaluation and variance diagnostics](reports/rhe-blup.html).
Individual data, fits and diagnostics stay in external directories. Only
reviewed summaries and static SVG plots enter the site.
