---
layout: default
title: Evaluation protocol
---
# Evaluation protocol

<!-- training-variance-comparison:start -->
<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}</style>

## Current training-only comparison

Saved ten-fold CV uses seed 42. Cohort-level genotype-only QC defines the marker panel (MAF ≥1%, marker missingness ≤5%; HWE reported without filtering). Each training fold then gets its own Glist, genotype scaling and phenotype mean. Missing training phenotypes use the training-only observed mean. Maize has two missing phenotypes; their held-out occurrences in folds 2 and 7 are excluded from scoring (1,456 observed targets overall). All 5,024 cattle targets are observed. Held-out outcomes cannot enter variance estimation or phenotype preprocessing; this distinguishes the configuration from older full-panel-imputation results.

PCG uses four native MKL product threads; BayesA uses one worker and two sequential chains. Only completed ten-fold aggregates are published; failed folds and mixing diagnostics remain explicit.

[Full current protocol, settings and source-availability limits](reports/training-variance.html).

## Earlier configuration
<!-- training-variance-comparison:end -->

<figure class="workflow-figure"><a href="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}?v={{ site.time | date: '%s' }}"><img src="{{ '/assets/images/benchmark-workflow.svg' | relative_url }}?v={{ site.time | date: '%s' }}" width="1120" height="620" alt="GPBench arrays are converted to PLINK BED/BIM/FAM, filtered by MAF and missingness, and prepared as Glist. Identical ten-fold splits select training samples for existing gbayes C++ methods, followed by held-out prediction and aggregate evaluation."></a><figcaption>BED/BIM/FAM → QC → Glist → training-fold selection → gbayes C++ fitting → held-out prediction. Four concurrent MCMC chains; saved ten-fold splits with seed 42.</figcaption></figure>

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
report actual markers used. Native training coding and phenotype handling
are preserved. Test outcomes never enter fitting or parameter choice.

Every method begins with Glist. The gbayes collection uses its public Glist
interface; ordinary RHE + BLUP uses a private Glist adapter to existing
greml/gsolve/gbits routines. Fitting and genotype products stay in C++.
Settings are recorded in the [method registry](methods.html).
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

Use four concurrent MCMC chains, with OpenBLAS and MKL requests at one; disable diagnostic
BLAS logging for timed runs. RHE + BLUP uses one fit with an operation-local
MKL thread cap of four; its R/OpenBLAS control remains one. Record shared training-Glist preparation separately
from each fit and held-out prediction. Native packed preparation inside a fit
is included in its fitting time. Cost plots use the sum of fitting and prediction
over ten folds. Whole-process peak RAM includes loading, preparation, saved
outputs and prediction; it is not fit-only peak RAM. Show failures, warnings,
unavailable measurements and MCMC mixing limitations explicitly. A failed fold
suppresses the method's aggregate accuracy, rather than publishing an average
of only successful folds. Cost tables retain the failed fitting attempts.
