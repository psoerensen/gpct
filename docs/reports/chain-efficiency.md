---
layout: default
title: Chain efficiency
---
# Two versus four chains

Saved fold 1, unchanged 500 burn-in and 1000 post-burn transitions per chain: two sequential chains versus four concurrent chains. The first two seeded parameter trajectories must match. More chains add draws; scheduling the same chains differently changes runtime without changing their draws.

| Dataset | Method | Parameter | Chains | Workers | R-hat | Bulk ESS | ESS / fit second |
| --- | --- | --- | --- | --- | --- | --- | --- |
| cattle | BayesA MCMC | residual_variance | 2 | 1 | 1.01 | 255.4 | 0.511 |
| cattle | BayesA MCMC | effect_variance | 2 | 1 | 1.00 | 1256.4 | 2.512 |
| cattle | BayesA MCMC | residual_variance | 4 | 4 | 1.01 | 411.7 | 1.416 |
| cattle | BayesA MCMC | effect_variance | 4 | 4 | 1.00 | 3130.4 | 10.764 |
| maize | BayesA MCMC | residual_variance | 2 | 1 | 1.03 | 75.2 | 0.290 |
| maize | BayesA MCMC | effect_variance | 2 | 1 | 1.01 | 197.1 | 0.759 |
| maize | BayesA MCMC | residual_variance | 4 | 4 | 1.02 | 177.6 | 1.017 |
| maize | BayesA MCMC | effect_variance | 4 | 4 | 1.01 | 456.3 | 2.613 |
| cattle | BayesB MCMC | residual_variance | 2 | 1 | 1.04 | 79.3 | 0.257 |
| cattle | BayesB MCMC | effect_variance | 2 | 1 | 1.00 | 1879.2 | 6.082 |
| cattle | BayesB MCMC | active_markers | 2 | 1 | 1.01 | 130.0 | 0.421 |
| cattle | BayesB MCMC | weight_0 | 2 | 1 | 1.00 | 269.3 | 0.871 |
| cattle | BayesB MCMC | weight_1 | 2 | 1 | 1.00 | 269.3 | 0.871 |
| cattle | BayesB MCMC | residual_variance | 4 | 4 | 1.11 | 29.4 | 0.131 |
| cattle | BayesB MCMC | effect_variance | 4 | 4 | 1.00 | 3571.2 | 15.926 |
| cattle | BayesB MCMC | active_markers | 4 | 4 | 1.11 | 28.6 | 0.127 |
| cattle | BayesB MCMC | weight_0 | 4 | 4 | 1.04 | 86.6 | 0.386 |
| cattle | BayesB MCMC | weight_1 | 4 | 4 | 1.04 | 86.6 | 0.386 |
| maize | BayesB MCMC | residual_variance | 2 | 1 | 1.15 | 9.6 | 0.051 |
| maize | BayesB MCMC | effect_variance | 2 | 1 | 1.00 | 1779.9 | 9.370 |
| maize | BayesB MCMC | active_markers | 2 | 1 | 1.12 | 12.9 | 0.068 |
| maize | BayesB MCMC | weight_0 | 2 | 1 | 1.08 | 21.5 | 0.113 |
| maize | BayesB MCMC | weight_1 | 2 | 1 | 1.08 | 21.5 | 0.113 |
| maize | BayesB MCMC | residual_variance | 4 | 4 | 1.14 | 21.3 | 0.151 |
| maize | BayesB MCMC | effect_variance | 4 | 4 | 1.00 | 3804.3 | 27.010 |
| maize | BayesB MCMC | active_markers | 4 | 4 | 1.08 | 36.5 | 0.259 |
| maize | BayesB MCMC | weight_0 | 4 | 4 | 1.06 | 56.3 | 0.400 |
| maize | BayesB MCMC | weight_1 | 4 | 4 | 1.06 | 56.3 | 0.400 |
| cattle | BayesC MCMC | residual_variance | 2 | 1 | 1.00 | 118.1 | 0.434 |
| cattle | BayesC MCMC | effect_variance | 2 | 1 | 1.09 | 34.9 | 0.128 |
| cattle | BayesC MCMC | active_markers | 2 | 1 | 1.10 | 34.4 | 0.127 |
| cattle | BayesC MCMC | weight_0 | 2 | 1 | 1.10 | 35.8 | 0.132 |
| cattle | BayesC MCMC | weight_1 | 2 | 1 | 1.10 | 35.8 | 0.132 |
| cattle | BayesC MCMC | residual_variance | 4 | 4 | 1.01 | 189.1 | 0.855 |
| cattle | BayesC MCMC | effect_variance | 4 | 4 | 1.08 | 75.7 | 0.342 |
| cattle | BayesC MCMC | active_markers | 4 | 4 | 1.09 | 68.5 | 0.310 |
| cattle | BayesC MCMC | weight_0 | 4 | 4 | 1.09 | 70.7 | 0.320 |
| cattle | BayesC MCMC | weight_1 | 4 | 4 | 1.09 | 70.7 | 0.320 |
| maize | BayesC MCMC | residual_variance | 2 | 1 | 1.12 | 15.3 | 0.117 |
| maize | BayesC MCMC | effect_variance | 2 | 1 | 1.06 | 22.2 | 0.169 |
| maize | BayesC MCMC | active_markers | 2 | 1 | 1.05 | 18.1 | 0.138 |
| maize | BayesC MCMC | weight_0 | 2 | 1 | 1.05 | 18.4 | 0.140 |
| maize | BayesC MCMC | weight_1 | 2 | 1 | 1.05 | 18.4 | 0.140 |
| maize | BayesC MCMC | residual_variance | 4 | 4 | 1.20 | 16.8 | 0.126 |
| maize | BayesC MCMC | effect_variance | 4 | 4 | 1.19 | 15.5 | 0.116 |
| maize | BayesC MCMC | active_markers | 4 | 4 | 1.23 | 13.1 | 0.098 |
| maize | BayesC MCMC | weight_0 | 4 | 4 | 1.23 | 13.2 | 0.099 |
| maize | BayesC MCMC | weight_1 | 4 | 4 | 1.23 | 13.2 | 0.099 |
| cattle | BayesN / Bayesian ridge | residual_variance | 2 | 1 | 1.05 | 46.7 | 0.118 |
| cattle | BayesN / Bayesian ridge | effect_variance | 2 | 1 | 1.09 | 21.8 | 0.055 |
| cattle | BayesN / Bayesian ridge | residual_variance | 4 | 4 | 1.03 | 126.0 | 0.454 |
| cattle | BayesN / Bayesian ridge | effect_variance | 4 | 4 | 1.05 | 51.5 | 0.186 |
| maize | BayesN / Bayesian ridge | residual_variance | 2 | 1 | 1.16 | 14.9 | 0.081 |
| maize | BayesN / Bayesian ridge | effect_variance | 2 | 1 | 1.38 | 4.7 | 0.025 |
| maize | BayesN / Bayesian ridge | residual_variance | 4 | 4 | 1.11 | 38.9 | 0.258 |
| maize | BayesN / Bayesian ridge | effect_variance | 4 | 4 | 1.26 | 11.7 | 0.078 |
| cattle | BayesR MCMC | residual_variance | 2 | 1 | 1.04 | 70.4 | 0.129 |
| cattle | BayesR MCMC | effect_variance | 2 | 1 | 1.38 | 4.4 | 0.008 |
| cattle | BayesR MCMC | active_markers | 2 | 1 | 1.06 | 15.3 | 0.028 |
| cattle | BayesR MCMC | weight_0 | 2 | 1 | 1.06 | 15.3 | 0.028 |
| cattle | BayesR MCMC | weight_1 | 2 | 1 | 1.49 | 4.2 | 0.008 |
| cattle | BayesR MCMC | weight_2 | 2 | 1 | 1.45 | 4.0 | 0.007 |
| cattle | BayesR MCMC | weight_3 | 2 | 1 | 1.17 | 8.8 | 0.016 |
| cattle | BayesR MCMC | residual_variance | 4 | 4 | 1.05 | 62.0 | 0.192 |
| cattle | BayesR MCMC | effect_variance | 4 | 4 | 1.54 | 7.1 | 0.022 |
| cattle | BayesR MCMC | active_markers | 4 | 4 | 1.43 | 8.3 | 0.026 |
| cattle | BayesR MCMC | weight_0 | 4 | 4 | 1.42 | 8.3 | 0.026 |
| cattle | BayesR MCMC | weight_1 | 4 | 4 | 1.68 | 6.5 | 0.020 |
| cattle | BayesR MCMC | weight_2 | 4 | 4 | 1.59 | 6.8 | 0.021 |
| cattle | BayesR MCMC | weight_3 | 4 | 4 | 1.24 | 12.7 | 0.040 |
| maize | BayesR MCMC | residual_variance | 2 | 1 | 1.23 | 6.6 | 0.015 |
| maize | BayesR MCMC | effect_variance | 2 | 1 | 1.84 | 3.0 | 0.007 |
| maize | BayesR MCMC | active_markers | 2 | 1 | 1.54 | 3.6 | 0.008 |
| maize | BayesR MCMC | weight_0 | 2 | 1 | 1.54 | 3.6 | 0.008 |
| maize | BayesR MCMC | weight_1 | 2 | 1 | 1.84 | 3.0 | 0.007 |
| maize | BayesR MCMC | weight_2 | 2 | 1 | 2.35 | 2.5 | 0.006 |
| maize | BayesR MCMC | weight_3 | 2 | 1 | 1.90 | 2.8 | 0.006 |
| maize | BayesR MCMC | residual_variance | 4 | 4 | 1.44 | 8.0 | 0.027 |
| maize | BayesR MCMC | effect_variance | 4 | 4 | 2.22 | 5.1 | 0.017 |
| maize | BayesR MCMC | active_markers | 4 | 4 | 2.59 | 4.8 | 0.016 |
| maize | BayesR MCMC | weight_0 | 4 | 4 | 2.58 | 4.8 | 0.016 |
| maize | BayesR MCMC | weight_1 | 4 | 4 | 1.65 | 6.8 | 0.023 |
| maize | BayesR MCMC | weight_2 | 4 | 4 | 2.70 | 4.7 | 0.016 |
| maize | BayesR MCMC | weight_3 | 4 | 4 | 2.62 | 4.7 | 0.016 |

Compare ESS per second within the same method, dataset and parameter. ESS estimates remain provisional when chains have not mixed; more chains do not guarantee proportionally more effective samples. Fitting includes genotype/cache preparation. This is distinct from the short matched four-chain [threading probe](threading.html).

[Summary CSV](../assets/reports/gbayes-glist/chain-efficiency.csv) · [Ten-fold results](../results.html)
