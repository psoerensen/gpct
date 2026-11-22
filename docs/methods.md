---
layout: default
title: Methods and settings
---
# Methods and settings


<!-- training-variance-comparison:start -->
<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}</style>

## Current comparison

| Method | What is fitted | Variance policy | Threads |
|---|---|---|---:|
| Gaussian PCG | Equal Gaussian shrinkage across standardized markers. | Uniform-kernel variance pair estimated from training phenotypes, then fixed. | 4 |
| D-weighted PCG | Fixed allele-frequency weights: qⱼ = [2pⱼ(1−pⱼ)]^0.75. | Variance pair estimated using the matching D-weighted training kernel, then fixed. | 4 |
| Warm-start adaptive B | Deterministic two-Gaussian conditional weight updates around PCG; previous solutions warm-start subsequent solves. | Initial uniform-kernel training variance pair stays fixed as weights adapt. Not BayesB MCMC. | 4 |
| BayesA MCMC | All markers; sampled continuous marker-specific variances and posterior-mean effects. | Marker and residual variances learned by MCMC; two sequential chains, each 500 burn-in + 1,000 post-burn sweeps. | 1 |

Fitting uses the existing gsuite native libraries greml, gsolve, gbits and gbayes, reached through experimental private adapters. Public downloads contain aggregate metrics, settings, diagnostics and binary identities; individual predictions, effects and implementation source remain private. This is bounded evidence for the tested builds and panels, not a released-interface or large-cohort qualification claim.

[Current settings and validation protocol](reports/training-variance.html#methods-in-this-comparison).

## Earlier method collection
<!-- training-variance-comparison:end -->


Every fit uses the existing `gbayes::bayes(data, Glist=training, ...)` interface
and native C++ engine. Held-out predictions use `predict(fit,
newdata=list(Glist=panel, ids=held_out_ids), type="phenotype")` with saved
training coding. No dense X, marginal-summary or external fitting substitute
is used. Full MCMC runs request **four concurrent chains** and one BLAS thread.
The fixed Gaussian PCG reference used one worker. BayesCM is not included.

| ID | Method | Algorithm | Variance/settings policy |
| --- | --- | --- | --- |
| marker_gaussian | Gaussian baseline | pcg | Fixed equal marker variances and residual variance; working h2=0.5; no REML |
| bayesN_mcmc | BayesN / Bayesian ridge | mcmc | All markers; learned shared Gaussian marker and residual variances |
| bayesA_mcmc | BayesA | mcmc | All markers; sampled marker-specific and residual variances; fixed variance hyperprior |
| bayesB_mcmc | BayesB | mcmc | Spike plus marker-specific variances; learned active probability and variances; fixed variance hyperprior |
| bayesC_mcmc | BayesC | mcmc | Learned common active-marker variance, residual variance and active probability |
| bayesR_mcmc | BayesR | mcmc | Learned base mixture variance, residual variance and mixture weights |

Deterministic iteration/sweep caps are 1000. Gaussian PCG tolerance is 1e-8;
MCMC uses four chains with 500 burn-in
and 1000 post-burn transitions per chain, thinning one, and first seed
42000 + 2 × outer fold. Completion of transitions does not establish mixing;
native convergence diagnostics are retained and limitations reported. A method
finishes the scheduled benchmark after ten unique folds on both panels; this
does not establish posterior convergence. R-hat above 1.05, bulk ESS below 100,
or unavailable parameter diagnostics make its accuracy estimates provisional.

The fixed Gaussian PCG reference uses a working residual variance of half the
training phenotype variance and empirical feature-variance calibration. MCMC
uses the existing native interface's initialization: half the training phenotype
variance for residual variance, and half divided by marker count and initial
mixture mass for the marker scale. Initial active probability is 0.001 for B/C;
R starts with weights (0.95, 0.02, 0.02, 0.01) and multipliers (0, 0.01, 0.1, 1).
These are initial values; the requested parameters then learn during sampling.
Variance priors use four degrees of freedom and prior means equal to initial
variances. Active probabilities use Beta(1,1); R weights use Dirichlet(1,1,1,1).

BayesA/B sample each marker variance with the existing inverse-chi-square draw.
Their common hyperprior scale stays fixed. A/B's scalar effect-variance trace
averages current marker variances, including prior draws for null B markers;
it is distinct from the shared variance in N/C and the base mixture scale in R.

Native genotype coding is preserved and recorded from each fit. In particular,
all listed methods use training-frequency HWE coding. Their priors and variance
policies differ and are recorded explicitly.

[Download exact method settings](assets/reports/gbayes-glist/method-settings.csv).
The retained local benchmark controller and native development changes are not
released by this aggregate website update. Reproduction requires the identified
qualified development build; installing the version number alone is insufficient.

The runtime is R 4.4.3/OpenBLAS with gbayes 0.1.16 and gbase, using the existing
compiled C++ implementations. Scalar Glist MCMC defaults to a decoded cache
bounded by the smaller of 2 GiB and 20% of available physical RAM. It reuses
the existing gsuite decode and BLAS score/update kernels, shares immutable
genotypes across chains, and falls back to packed access when the budget is
insufficient. Cache preparation is included in fitting and reported separately.
The local development package includes A/B/N additions and recorded source hashes;
its version number alone does not identify that unreleased build.
OpenBLAS/MKL environment thread requests stay one. Native OpenMP runs independent
chains concurrently; updates within each chain retain their existing order.
The fixed Gaussian PCG route does not imply MKL
DGEMM dispatch; backend claims are specific to the engine actually used.
Private source pins and runtime/build recipes are recorded in the repository;
authorized access is required for rebuilding those components.

[Native source revisions from the installed packages](assets/reports/gbayes-glist/native-source-revisions.csv)
· [Loaded package binary checksums](assets/reports/gbayes-glist/runtime-checksums.csv).
The installed gbayes build manifest excludes full-gsolve/full-greml, CHOLMOD,
MKL, PARDISO and root-gsuite. Its native source closure is recorded separately
from the optional full-suite MKL profile. The loaded gbase R helper installation
has no native source manifest; that gap is explicit, and both loaded package
binaries are identified by checksum. The Gaussian baseline uses the existing
packed native PCG engine; this is not a claim of MKL dispatch.

Threading checks hold four seeded chains fixed at one versus four workers.
A separate practical check compares two sequential with four concurrent chains
at unchanged iterations per chain, reporting parameter ESS, ESS per fitting
second and R-hat. The first two trajectories must match. More chains can improve
pooled ESS, but poor mixing makes those ESS estimates provisional too.

RHE + BLUP will be added after its separate validation, using these same input
panels, QC and saved folds. Only reviewed results, settings and software identities
will be published here; its source remains private.

These measurements use an Intel Core Ultra 7 258V laptop with eight logical
processors and 32 GB RAM. One-worker measurements are pinned to logical CPU 2;
four-worker measurements use CPUs 0–3. Available RAM, rather than installed RAM,
controls cache admission. Process resource records retain the actual affinity.
