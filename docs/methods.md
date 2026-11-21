---
layout: default
title: Methods and settings
---
# Methods and settings

Every fit uses the existing `gbayes::bayes(data, Glist=training, ...)` interface
and native C++ engine. Held-out predictions use `predict(fit,
newdata=list(Glist=panel, ids=held_out_ids), type="phenotype")` with saved
training coding. No dense X, marginal-summary or external fitting substitute
is used. All methods request **one worker**. BayesCM is not included.

| ID | Method | Algorithm | Variance/settings policy |
| --- | --- | --- | --- |
| marker_gaussian | Gaussian baseline | pcg | Fixed equal marker variances and residual variance; working h2=0.5; no REML |
| elastic_net | Elastic net | coordinate_descent | Fixed alpha=0.5; lambda=0.01 × training phenotype SD; no tuning |
| laplace_gaussian | Laplace–Gaussian mixture | vbayes | Fixed variance scales; Laplace probability 0.1; Gaussian variance fraction 0.3 |
| bayesC_vb | BayesC | vbayes | Fixed active probability 0.1 and variance scales |
| bayesC_mcmc | BayesC | mcmc | Native scalar variance/probability learning; two sequential chains |
| bayesR_mcmc | BayesR | mcmc | Native scalar variance/probability learning; two sequential chains |

Deterministic iteration/sweep caps are 1000. Gaussian PCG tolerance is 1e-8;
other methods retain their native default tolerances. MCMC uses 500 burn-in
and 1000 post-burn transitions per chain, thinning one, and first seed
42000 + 2 × outer fold. Completion of transitions does not establish mixing;
native convergence diagnostics must be reviewed and limitations reported.

For fixed-prior Gaussian and mixture configurations, the working residual
variance is half the training phenotype variance. Average marker variance is
calibrated using training empirical variance in the native HWE-coded coordinates.
BayesC slab variance divides that average by its active probability. These are
declared fixed configurations, not estimated REML variances or tuned optima.

Native genotype coding is preserved and recorded from each fit. In particular,
the Gaussian and BayesC/R routes use training-frequency HWE coding; elastic net
uses its native training empirical-SD coding. This is a method comparison, not
an assertion that every method fits an identical Gaussian model.

[Exact configuration recipe](https://github.com/psoerensen/gpct/blob/main/benchmarks/methods.R)
· [Download settings CSV](assets/reports/gbayes-glist-1t/method-settings.csv)

The runtime is R 4.4.3/OpenBLAS with gbayes 0.1.16 and gbase, using the existing
compiled packed-genotype implementations. R/OpenBLAS, MKL and OpenMP environment
thread requests are all one. The packed Gaussian PCG route does not imply MKL
DGEMM dispatch; backend claims are specific to the engine actually used.
Private source pins and runtime/build recipes are recorded in the repository;
authorized access is required for rebuilding those components.
