---
layout: default
title: Methods and package interfaces
---
# Methods and package interfaces

All optimization is delegated to existing packages. No statistical method is
implemented in gpct. The initial pilot keeps three predictors on the same
512-marker matrix and saved splits.

| Method | Existing interface | Settings |
| --- | --- | --- |
| REML ridge baseline | `rrBLUP::mixed.solve(y, Z, method="REML")` | Training-only variance-component estimation; bounds 1e-9 to 1e9 |
| Fixed Gaussian marker prior | `gbayes::bayes(data, X, trait, method="marker_gaussian", algorithm="pcg")` | Standardized training response/features; ve=0.5; markerVariance=0.5/p |
| Elastic net | `gbayes::bayes(data, X, trait, method="elastic_net", algorithm="coordinate_descent")` | lambda=0.1, alpha=0.5; training-standardized response/features |

The Gaussian scale split is a predeclared working assumption, not an estimated
heritability. The elastic-net penalty is fixed, not tuned. Both gbayes fits cap
iterations at 2,000 with tolerance 1e-8 and managed memory 512 MiB. Future tuning
must be nested inside training folds. REML ridge differs from fixed-prior ridge
because its shrinkage is estimated from training data.

gbayes phenotype prediction uses `stats::predict(fit, newdata=Xtest,
type="phenotype")`; diagnostics use `gbayes::diagnostics(fit)`. rrBLUP prediction
uses its returned intercept and marker effects. Training response scaling is
inverted for both before evaluation.

## API evidence and availability

The baseline signature and returned `beta`, `u`, `Vu`, `Ve`, `LL` were checked
against [CRAN rrBLUP documentation](https://cran.r-project.org/package=rrBLUP)
and [its published R source](https://github.com/cran/rrBLUP/blob/master/R/mixed.solve.R).

Read-only inspection of the existing gsuite checkout supplied actual package
documentation and examples before calls were written:

| Package source | Inspected documentation/examples | Scientific role |
| --- | --- | --- |
| gbayes 0.1.16 source | `packages/gbayes/man/bayes.Rd`, `prepared_design.Rd`, `bayesfit.Rd`; `R/prepared-design.R`; `tools/examples/gbayes/prepared-design.R` | Prediction pilot |
| glma 0.1.2 source | `packages/glma/man/glma.Rd` and DESCRIPTION | Future quantitative/binary association and LOCO scans |
| gcorr 0.1.10 source | DESCRIPTION and `man/ldsc.Rd` | Future covariance/correlation and architecture cases |
| gsuite 0.43.0 source | DESCRIPTION | Future mixed-model and resource preparation cases |

These are inspected source versions, **not verified installed versions**.
gbayes documentation explicitly marks prepared-design adapters as a pending
source batch with runtime qualification deferred. They accept labelled, finite,
centered dense X and have a default 2,048-feature limit. The pilot uses 512
markers and never silently reduces a requested full-genome benchmark. Confirm
local `help("prepared_design", package="gbayes")` and run the recipe before
marking it runnable. A matching version number alone is insufficient.

Public release URLs for these local development packages were not established.
Use the existing source/help available to the owner, e.g.
`help("bayes", package="gbayes")`, `help("glma", package="glma")`,
`help("ldsc", package="gcorr")`, and `help(package="gsuite")`.
Add verified public package/documentation links when releases are available.
No sibling checkout or shared installation was modified.

## Future cases

Full-marker BayesC/BayesR can use documented gbayes Glist/PLINK interfaces after
legitimate source IDs/alleles or an approved import route are available. The
current NPZ collection does not contain enough metadata to invent a BIM map.

glma association tests answer locus-discovery/calibration questions; gcorr
LD-score, covariance and genetic-correlation methods answer architecture and
cross-trait questions. They should have separate benchmarks, reference truth,
overlap/LD assumptions and evaluation measures. gsuite mixed-model cases need
verified resource preparation and prediction semantics. None is forced into
these prediction rankings.
