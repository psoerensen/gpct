# Dataset catalogue and preparation

The machine-readable [registry](registry.csv) starts with two GPBench datasets.
Verified counts describe the complete source arrays, not the 512-marker pilots.

| ID | Array shape | Traits | Finite outcomes for pilot |
| --- | --- | --- | --- |
| `gpbench_cattle` | 5,024 × 42,551 | mkg, fpro, scs | mkg: 5,024 |
| `gpbench_maize` | 1,458 × 75,304 | DTT, PH, EW | DTT: 1,456 |

Source: [Hugging Face GPBench](https://huggingface.co/datasets/xw97/GPBench),
commit `f0204d8372fb5ec8fa29eb3f00c9a9d0a7656517`.
Actual archive: `Benchmarkdata.zip` (303,192,374 bytes), despite the card's
reference to `Benchmark.zip`. Its SHA-256 is
`fa02416336dd99d521a1533d2035b48fa02b723a7458236bd33b2c11b248ab67`.
The [HF tree API](https://huggingface.co/api/datasets/xw97/GPBench/tree/main)
reports this same LFS checksum. Each species lives under
`Benchmarkdata/Benchmarkdata/{Cattle,Maize}/` with `genotype.npz` and
`phenotype.npz`. Genotype key `arr_0` is an int64 matrix, values 0, 1 or 2.
Phenotype `arr_0` is float64 with three columns; `arr_1` gives Unicode trait names.
No pickle is needed. There are no original sample or marker IDs in these files.

Citation: Zhang, X., et al. (2026), *GPBench: A benchmark framework for genomic
prediction*, [doi:10.64898/2026.10.31.762999](https://doi.org/10.64898/2026.10.31.762999).
Crossref reports posting on 2026-11-04. The
[upstream code](https://github.com/xwzhang2118/GPBench) also links the
[16-species collection](https://doi.org/10.6084/m9.figshare.31007608).
We have not independently traced each species to its original study.

## Provenance limits

The dataset card declares Apache-2.0 and download is public and ungated.
This is the distributor's declaration, not independent verification of original
source permissions. gpct does not mirror the archive or individual records.
Check original study terms before redistribution. Prior filtering, imputation,
phenotype adjustment, trait units and allele orientation are undocumented here.
Possible upstream whole-cohort processing cannot be undone; training-only
processing in gpct does not certify the upstream data as free of leakage.

The supplied trait labels are preserved verbatim. `mkg` is a milk-related label
and `DTT` a flowering-time label, but exact biological definitions, units and
adjustment histories need source confirmation. In particular, do not describe
the cattle response as raw milk yield or estimate breeding-value accuracy.

## Local preparation

Follow the commands in the root README. `scripts/prepare.R cattle` (or `maize`)
verifies the archive checksum and exact member paths, refuses object/pickle
arrays, checks dimensions and dosage coding, and selects 512 evenly spaced
source marker columns without looking at outcomes. It saves `prepared/<case>.rds`
under `GPCT_DATA_DIR`, containing X, phenotypes, surrogate IDs, source columns,
source checksum and preparation metadata. No imputation or scaling is done
until training folds are defined. Runs drop only nonfinite selected outcomes.

Set `GPCT_ACCEPT_POSITIONAL_IDS=yes` after accepting the upstream convention
that the two arrays have matching row order. Equal row counts cannot prove
biological alignment. Surrogates such as `gpbench_cattle:row:000001` preserve
source position, including after outcome exclusions; they are never represented
as original animal/line identifiers. Markers likewise identify source columns,
not mapped SNPs. Do not invent BIM alleles or genomic positions.

The default data directory is `~/gpct-data`; outputs default to `~/gpct-results`.
Both are configurable and scripts refuse paths inside the checkout. A Python
with NumPy is used through `reticulate` only to read NPZ files. Configure it
with `RETICULATE_PYTHON`; scripts never create Python environments or install
packages. Prepare one dataset at a time to bound memory use.

To add further species, create a registry entry and a small explicit preparation
recipe with its own data contract. Human data need appropriate access and consent
documentation. Do not assume the GPBench row-order contract applies elsewhere.
