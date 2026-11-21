---
layout: default
title: Methods and gsuite interfaces
---
# Methods and gsuite interfaces

gpct benchmarks **methods and models implemented in the gsuite ecosystem**.
Model names describe the statistical task; package and engine names identify
our implementation. GPBench supplies data and a validation scheme.

| Benchmarked model | Our interface | Statistical task |
| --- | --- | --- |
| Genomic BLUP with REML | gsuite::gs_lmm_fit, using greml and gsolve | Estimate genetic and residual variances on training data, then predict held-out phenotypes |
| Numerical verification, outside the model ranking | gsuite::gsuite_solve with the fitted greml variances | Recompute fixed-variance GLS/BLUP predictions; no variance estimation |

The genomic BLUP model uses an intercept and the raw-dosage relationship
K = ZZ'/p. REML uses the existing hybrid EM–AI optimizer, at most 100 iterations
and score tolerance 1e-4. The supplied precision and its covariance metadata
come from the same successful Cholesky factorization; no matrix repair is applied.
The component interface uses CHOLMOD/MKL and exact selected inversion.
Convergence, warnings, variance estimates and returned backend settings are
recorded for every fold.

greml owns mixed-model likelihood and variance estimation. gsolve supplies
numerical solvers; it is not a second prediction model. Their R interfaces are
exposed through the root gsuite development package. Public recipes call these
interfaces and do not contain the private numerical implementations.

R uses OpenBLAS 0.3.29. The native integration uses Intel MKL/SuiteSparse.
Requested runtime thread budgets and the settings returned by the native backend
are reported separately; neither measures CPU utilization. The separate gsolve
verification uses its supported one-worker setting.

Other models implemented in the ecosystem, including gbayes prediction models,
can receive their own benchmark entries. Association through glma and genetic
correlation through gcorr require distinct evaluation designs. Scoring and mapping
interfaces retain their gscore/gmap roles. An available interface is not evidence
that a model has already been benchmarked.

Private implementation source and binaries remain in their private owner
repositories. Authorized maintainers can rebuild from the pinned commits in the
[environment recipe](https://github.com/psoerensen/gpct/tree/main/environment).
Public readers can inspect benchmark calls, settings, aggregate results and
provenance. See the [protocol](protocol.html) and
[existing numerical and mixed-model interfaces](https://psoerensen.github.io/gtools/gsuite/docs/gsolve-greml.html).
