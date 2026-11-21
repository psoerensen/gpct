---
layout: default
title: Methods and gsuite interfaces
---
# Methods and gsuite interfaces

> **GLMA Gaussian audit warning:** The current fast joint path failed real-data variance-grid and fixed-variance accuracy checks. Its figures are diagnostic; prior-selected shares the variance-grid machinery and remains unqualified. [Controlled audit](glma-gaussian-audit.html).

gpct benchmarks **methods and models implemented in the gsuite ecosystem**.
Model names describe the statistical task; package and engine names identify
our implementation. GPBench supplies data and a validation scheme.

| Benchmarked model | Our interface | Statistical task |
| --- | --- | --- |
| Genomic BLUP with REML | gsuite::gs_lmm_fit, using greml and gsolve | Estimate genetic and residual variances on training data, then predict held-out phenotypes |
| Gaussian VB | gbayes::bayes, method="normal_mixture", algorithm="vbayes", one positive variance | Fit Gaussian marker effects with fixed training-only prior and residual variance |
| Sparse normal-mixture VB | Same native streamed interface, zero spike plus one normal component | Fit a fixed spike-and-normal prior with inclusion probability 0.1 |
| GLMA Gaussian | glma::glma_full_marker_prediction, method="infinitesimal" | Existing joint Gaussian full-marker prediction fit underlying glma_infinitesimal_loco(); no chromosome exclusions |
| GLMA prior-selected | Same thin interface, method="prior_selected" | Existing ten-candidate ridge/elastic joint prediction fit underlying glma_prior_selected_loco(); no chromosome exclusions |
| Numerical verification, outside the model ranking | gsuite::gsuite_solve with the fitted greml variances | Recompute fixed-variance GLS/BLUP predictions; no variance estimation |

The genomic BLUP model uses an intercept and the raw-dosage relationship
K = ZZ'/p. REML uses the existing hybrid EM–AI optimizer, at most 100 iterations
and score tolerance 1e-4. The supplied precision and its covariance metadata
come from the same successful Cholesky factorization; no matrix repair is applied.
The component interface uses CHOLMOD/MKL and exact selected inversion.
Convergence, warnings, variance estimates and returned backend settings are
recorded for every fold.

Both gbayes models retain every marker in raw dosage coordinates. The native
streamed interface projects a training intercept and recovers it for target
prediction, without SD normalization. It avoids a global marker Gram matrix.
The working h2 is fixed at 0.5: residual variance is half the training phenotype
variance, while average marker variance is half that phenotype variance divided
by the sum of training marker variances. The sparse mixture fixes weights at
0.9/0.1 and its nonzero variance at ten times the Gaussian marker variance.
These settings are declared before evaluation; they are not estimated by REML
or chosen using held-out outcomes.

gbayes uses at most 100 sweeps, per-sample negative-ELBO tolerance 1e-6, chunks of
128 features, 20 local iterations, full refresh every eight sweeps, a 256 MiB
per-call Gram cache and a 1 GiB managed-memory budget. It requests one package
worker. The managed budget excludes caller data/runtime memory and is not peak
RAM. Convergence is objective stabilization, not a global-optimum certificate;
sweep-cap fits remain provisional. Per-fold prior values and sweeps are exported.

The GLMA prediction adapter uses existing native C++ joint modes on each outer
training fold. It applies empirical marker SD standardization, excludes constant
training markers (zero effects), and estimates variance using blocked RHE/Monte
Carlo refinement. Its internal 10% validation split uses seed 17092026 within the
outer training rows. Prior-selected considers ten ridge/elastic candidates;
Gaussian uses ridge. All variance estimation, centering and selection stays
inside the outer training fold. The native joint procedure is retained as
implemented; its internal score is a selection score, not external validation.
The adapter returns a single global prediction model, without LOCO refits,
association scans or calibration. No biological marker annotations are invented.
Actual used-marker counts and selected priors are reported per fold.

GLMA uses decoded products, chunk size 256, four coordinate/MKL workers, default
sweep cap 100 and a 1 GiB managed budget. Its native approximate workflow
acceptance includes prediction stability and adaptive chunk retirement; it is
not exact REML or a strict global ELBO certificate. A numerical check verified
actual MKL DGEMM calls and agreement with a fixed-V Gaussian reference.

The earlier gbayes standalone build is a portable C++ core without MKL dense
kernels. R OpenBLAS does not accelerate those C++ products automatically.
greml/gsolve and the new GLMA build use the full native MKL prefix. Timings
therefore compare the documented complete workflows, including these backend
and preprocessing differences, rather than isolating numerical solver speed.

greml owns mixed-model likelihood and variance estimation. gsolve supplies
numerical solvers; it is not a second prediction model. Their R interfaces are
exposed through the root gsuite development package. Public recipes call these
interfaces and do not contain the private numerical implementations.

R uses OpenBLAS 0.3.29. The native integration uses Intel MKL/SuiteSparse.
Requested runtime thread budgets and the settings returned by the native backend
are reported separately; neither measures CPU utilization. The separate gsolve
verification uses its supported one-worker setting.

Other gbayes models can receive separate entries using their documented inputs
and scientific designs. These two streamed routes are not BayesC/BayesR MCMC aliases.
Association through glma and genetic
correlation through gcorr require distinct evaluation designs. Scoring and mapping
interfaces retain their gscore/gmap roles. An available interface is not evidence
that a model has already been benchmarked.

Private implementation source and binaries remain in their private owner
repositories. Authorized maintainers can rebuild from the pinned commits in the
[environment recipe](https://github.com/psoerensen/gpct/tree/main/environment).
Public readers can inspect benchmark calls, settings, aggregate results and
provenance. See the [protocol](protocol.html) and
[existing numerical and mixed-model interfaces](https://psoerensen.github.io/gtools/gsuite/docs/gsolve-greml.html).
