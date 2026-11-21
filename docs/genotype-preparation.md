---
layout: default
title: Genotype preparation and QC
---
# Genotype preparation and QC

The replacement cattle and maize workflow starts with PLINK BED/BIM/FAM,
then uses the existing `gbase::gprep` and `gbase::gfilter` interfaces to create
a shared QC-selected `Glist`. Conversion and QC completed on 21 November 2026.
The replacement model fits are still being qualified; these counts do not
represent a new accuracy or timing result.

| Dataset | Individuals | Available markers | QC-retained markers | MAF exclusions | Missingness exclusions |
| --- | ---: | ---: | ---: | ---: | ---: |
| Cattle | 5,024 | 42,551 | 42,373 | 178 | 0 |
| Maize | 1,458 | 75,304 | 75,304 | 0 | 0 |

[Download the QC summary](assets/reports/20261121-glist-qc/summary.csv).

The selected rules are MAF at least 1% and marker missingness at most 5%.
The existing selector excludes MAF exactly equal to 1%; no marker in either
panel lies on that boundary. Neither panel has missing genotype calls.
HWE is reported without filtering: 101 cattle markers and all 75,304 maize
markers have a calculated HWE p-value below 1e-12. This is a genotype-count
diagnostic, not an exclusion rule or a claim that these breeding panels should
follow random-mating population assumptions.

QC uses the supplied whole-cohort genotypes without phenotypes. It removes no
individuals and preserves source row order, so the original saved ten-fold
seed-42 partitions remain unchanged. Training means and any model scaling
remain fold-specific. Marker-level diagnostics and individual records stay local.

## Synthetic metadata

GPBench supplies dosage arrays without original sample IDs, marker IDs,
alleles or genomic maps. The conversion therefore records source-row sample
IDs, source-column marker IDs and positions, a single synthetic contig `1`,
and synthetic A/C alleles. FAM pedigree and sex are unknown. The manifest and
`Glist` provenance explicitly mark these annotations as synthetic.

Every original dosage was independently decoded from the resulting BED and
checked for exact equality. Synthetic annotations permit full-marker prediction
and genotype-count QC. They must not be interpreted as biological chromosomes,
used for biological LOCO, genomic-distance LD or allele harmonization.

## Reproduce preparation

Use the pinned isolated environment and external data directory described in
the [dataset contract](https://github.com/psoerensen/gpct/blob/main/datasets/README.md).
After source-array extraction:

```powershell
Rscript --vanilla scripts/prepare_glist.R
```

The recipe preserves the source triplet, writes a separate QC-selected triplet,
validates both `Glist` objects, and saves the conversion manifest and QC audit
outside the repository. Existing outputs are checked rather than silently
replaced. The new resources are not retroactively assigned to the
[historical unfiltered results](results.html).
