---
layout: default
title: Additional benchmark plots
---
# Additional benchmark plots

<!-- report-version:de437bdc3276a77f -->

<style>.markdown-body{min-width:0}.markdown-body table{display:block;max-width:100%;overflow-x:auto}.markdown-body a[href*="/combined-"][href*=".svg"]{display:block;max-width:100%;overflow-x:auto}.markdown-body img[src*="/combined-"]{width:100%;min-width:800px;max-width:none;height:auto}</style>

[Results](../results.html) · [Methods](../methods.html)

Ten-fold aggregates for Gaussian PCG, D-weighted PCG, warm-start adaptive B BayesA MCMC, GLMA Gaussian and GLMA prior-selected. Pending or failed aggregates have no score. Fold dots describe variation across the saved folds.

GLMA retains its existing variance and prior-selection workflow. Its variance setup column records the initial stage; later grid work stays within fitting time.
These aggregate results use retained private development interfaces to the existing native engines. Individual predictions and implementation source stay private; [build identities](../assets/reports/training-variance/build-info.csv), [machine context](../assets/reports/training-variance/machine-info.csv) and [process measurements](../assets/reports/training-variance/process-resources.csv) identify the evaluated runs.
[Summary](../assets/reports/training-variance/summary.csv) · [Fold metrics](../assets/reports/training-variance/fold-results.csv) · [Settings](../assets/reports/training-variance/method-settings.csv) · [Validation](../assets/reports/training-variance/validation.csv)
<style>.comparison-scroll{overflow-x:auto;margin:1.25rem 0}.comparison-scroll img{display:block;width:100%;min-width:640px;height:auto}</style>

## Cattle

### Predictive performance

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/performance.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/cattle/performance.svg?v=de437bdc3276a77f" alt="Cattle: predictive performance across completed methods."></a><figcaption><a href="../assets/reports/training-variance/cattle/performance.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Improvement over Gaussian

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/improvement.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/cattle/improvement.svg?v=de437bdc3276a77f" alt="Cattle: improvement over gaussian across completed methods."></a><figcaption><a href="../assets/reports/training-variance/cattle/improvement.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Performance and runtime

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/runtime.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/cattle/runtime.svg?v=de437bdc3276a77f" alt="Cattle: performance and runtime across completed methods."></a><figcaption><a href="../assets/reports/training-variance/cattle/runtime.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Aggregate calibration

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/cattle/calibration.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/cattle/calibration.svg?v=de437bdc3276a77f" alt="Cattle: aggregate calibration across completed methods."></a><figcaption><a href="../assets/reports/training-variance/cattle/calibration.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>


## Maize

### Predictive performance

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/performance.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/maize/performance.svg?v=de437bdc3276a77f" alt="Maize: predictive performance across completed methods."></a><figcaption><a href="../assets/reports/training-variance/maize/performance.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Improvement over Gaussian

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/improvement.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/maize/improvement.svg?v=de437bdc3276a77f" alt="Maize: improvement over gaussian across completed methods."></a><figcaption><a href="../assets/reports/training-variance/maize/improvement.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Performance and runtime

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/runtime.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/maize/runtime.svg?v=de437bdc3276a77f" alt="Maize: performance and runtime across completed methods."></a><figcaption><a href="../assets/reports/training-variance/maize/runtime.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>

### Aggregate calibration

<figure class="comparison-scroll"><a href="../assets/reports/training-variance/maize/calibration.svg?v=de437bdc3276a77f"><img src="../assets/reports/training-variance/maize/calibration.svg?v=de437bdc3276a77f" alt="Maize: aggregate calibration across completed methods."></a><figcaption><a href="../assets/reports/training-variance/maize/calibration.svg?v=de437bdc3276a77f">Full-size SVG</a></figcaption></figure>
