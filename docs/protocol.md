---
layout: default
title: Evaluation protocol
---
# Evaluation protocol

<figure class="workflow-figure"><a href="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}?v={{ site.time | date: '%s' }}"><img src="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}?v={{ site.time | date: '%s' }}" width="1120" height="620" alt="GPBench arrays are converted to PLINK BED/BIM/FAM, filtered by MAF and missingness, and prepared as Glist. Identical ten-fold splits select training samples for existing gbayes C++ methods, followed by held-out prediction and aggregate evaluation."></a><figcaption>BED/BIM/FAM → QC → Glist → training-fold selection → gbayes C++ fitting → held-out prediction. One worker; saved ten-fold splits with seed 42.</figcaption></figure>

[Open full-size workflow SVG]({{ '/assets/images/benchmark-workflow.svg' | relative_url }}?v={{ site.time | date: '%s' }}).

## Genotype preparation

Preserve the pinned GPBench dosage arrays exactly when converting to SNP-major
BED. Independently decode every written dosage and check exact source equality.
BIM/FAM fields explicitly identify synthetic source-row IDs, source-column
marker IDs and positions, one synthetic contig and A/C alleles. These are
bookkeeping fields, not biological alleles or coordinates; no biological LOCO
or distance-based LD analysis is supported by them.

Use existing `gbase::gprep()` to inspect the triplet, `gbase::gfilter()` for
MAF 1% and marker missingness 5%, then `gprep(task="subset")` to write the
selected resource and create Glist. HWE is reported without filtering. No
phenotype enters QC. See the [QC record](genotype-preparation.html).

## Validation and fitting

Keep all individuals and the saved scikit-learn 1.6.1/NumPy 1.26.4
`KFold(n_splits=10, shuffle=True, random_state=42)` partitions. Each method uses
the identical outer folds. For each fold, prepare a training-selected Glist
from the QC triplet. Exclude any training-monomorphic markers explicitly and
report actual markers used. Native gbayes training coding and phenotype
centering are preserved. Test outcomes never enter fitting or parameter choice.

Every method receives Glist directly. No GLMA, greml/gsolve reference fit,
external fitter, matrix-input adapter or summary-statistic substitution is
part of this collection. Settings are frozen in the [method registry](methods.html).
This first collection uses declared fixed configurations and native learning,
without outer-test tuning or an extra hyperparameter search.

## Phenotype handling

Match the documented GPBench rule: replace missing outcomes with the whole-cohort
mean before splitting. Maize DTT has two such targets; cattle mkg has none.
Flag these locally, count them publicly and report observed-target-only
sensitivity metrics alongside the main results. Whole-cohort phenotype imputation
can use held-out information; this reproduction is not a recommendation for
new scientific validation. Source phenotype definitions, units and prior
processing remain unverified.

## Accuracy, uncertainty and cost

Save individual out-of-fold predictions locally. Publish mean fold predictive
correlation and RMSE, individual fold metrics, and explicitly labelled pooled
correlation, RMSE, predictive R² and calibration slope. Folds are descriptive
partitions, not independent experimental replicates. No fold-derived confidence
intervals are claimed. Publish only reviewed binned calibration summaries.

Set native workers, OpenMP, OpenBLAS and MKL requests to one; disable diagnostic
BLAS logging for timed runs. Record shared training-Glist preparation separately
from each fit and held-out prediction. Native packed preparation inside a fit
is included in its fitting time. Cost plots use the sum of fitting and prediction
over ten folds. Whole-process peak RAM includes loading, preparation, saved
outputs and prediction; it is not fit-only peak RAM. Show failures, warnings,
unavailable measurements and MCMC mixing limitations explicitly.
