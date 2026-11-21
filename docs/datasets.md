---
layout: default
title: Dataset catalogue
---
# Dataset catalogue

Inspected 2026-11-21 from the
[GPBench archive](https://huggingface.co/datasets/xw97/GPBench), pinned revision
`f0204d8372fb5ec8fa29eb3f00c9a9d0a7656517`.

| ID | Species | Samples | Available markers | Available traits | Benchmark target |
| --- | --- | --- | --- | --- | --- |
| gpbench_cattle | Bos taurus | 5,024 | 42,551 | mkg, fpro, scs | mkg; 5,024 finite |
| gpbench_maize | Zea mays | 1,458 | 75,304 | DTT, PH, EW | DTT; 1,456 finite |

Genotypes are int64 sample-by-marker NPZ arrays (`arr_0`) with observed 0/1/2
coding. Phenotype NPZ files contain float64 `arr_0` and Unicode names `arr_1`.
The full arrays were inspected for dimensions, traits, finite counts and dosage
range. Original sample IDs, allele orientation and marker positions are absent.

Preparation checks SHA-256
`fa02416336dd99d521a1533d2035b48fa02b723a7458236bd33b2c11b248ab67`
for the 303,192,374-byte `Benchmarkdata.zip`. Only selected NPZ members are
extracted outside git. The source arrays preserve raw dosages; the benchmark then uses the [PLINK/QC/Glist route](genotype-preparation.html), retaining 42,373 cattle and 75,304 maize markers. Synthetic row/column IDs identify archive
positions. They do not establish biological identity; row-order alignment must
be explicitly acknowledged.

## Processing and access

Upstream filtering, imputation, phenotype adjustment and units are unverified.
All genotype entries in both inspected matrices are finite. All cattle outcomes
are finite; maize finite counts are DTT 1,456, PH 1,457, EW 1,454.
GPBench mean-imputes missing phenotypes before splitting; matching that rule retains two imputed maize DTT targets, explicitly flagged. An observed-target-only sensitivity summary is separate. Neither this reproduction nor downstream processing certifies the upstream data as leakage-free.

The Hugging Face card declares Apache-2.0 and the download is ungated. Original
source rights and consent have not been independently established. gpct does
not redistribute individual data. Review original study terms before sharing.

Citation: Zhang, X., et al. (2026), *GPBench: A benchmark framework for genomic
prediction*, [doi:10.64898/2026.10.31.762999](https://doi.org/10.64898/2026.10.31.762999).
The [upstream code](https://github.com/xwzhang2118/GPBench) links a
[16-species dataset collection](https://doi.org/10.6084/m9.figshare.31007608).

See `datasets/registry.csv` and `datasets/README.md` in the repository for the
machine-readable catalogue, exact member paths and preparation contract.
