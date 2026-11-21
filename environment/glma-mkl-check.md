# GLMA MKL interface check, 21 November 2026

Both `glma_infinitesimal_loco()` and `glma_prior_selected_loco()` passed a
bounded synthetic interface check using the private full native prefix.
This is not cattle/maize accuracy evidence or a release qualification.

## Backend evidence

- GLMA R/native 0.1.2, gsuite source `19f876e71df014b996dbd09d0ae01ab3d0709829`,
  GLMA native source `3eac226f87dcb53a0b01b1145ac68ab81f182b48`.
- Release native build through the canonical
  `tools/build/build_workflow.ps1 -Action NativeOnly -NativeComponents glma -NativeTests`.
  This command builds/installs; it does not execute native tests.
- Full prefix manifest: `suite-full`, `GSOLVE_MKL_DENSE_KERNELS=ON`;
  actual gsolve compilation defines `GSOLVE_HAS_MKL_DENSE_KERNELS=1`.
- Intel MKL 2026.2.1, Intel OpenMP 2026.2.0. The R driver uses R 4.4.3;
  R's separate BLAS is OpenBLAS 0.3.29.
- `MKL_VERBOSE=1` recorded **33 DGEMM calls per infinitesimal run** and
  **45 per prior-selected run**, with the requested `NThr:1` / `NThr:4`.
  These counts are inside each named function call, excluding genotype preparation.

The default standalone GLMA R package recipe requires the portable profile and
rejects MKL. For this check, a private build-only patch adds the explicit
`GLMA_ALLOW_SUITE_FULL_MKL=1` opt-in and stages the qualified MKL/SuiteSparse
DLL closure. Default portable guards remain. No statistical implementation changed.
At this initial fixture checkpoint the patch was retained privately and not yet
committed. It has since been included in the private gsuite prediction-adapter
checkpoint `7d87cbde35bd0459ddcb6573457e34fe48ae1bd6`, with the native prepared
prediction resource at GLMA `0d7a23aa88d5fdddb4232c33ec1b8afe832653e0`.
Both checkpoints are pushed to their private repositories and pinned in
sources.csv. See build-glma-mkl.ps1 for the build/dispatch-check recipe.

Private evidence is under
`~/gpct-environments/windows-r443-openblas/qualification/glma-mkl/`:
`private-build-support.patch`, `runtime-checksums.csv`, `timings.csv`,
`synthetic-fits.rds`, and `session-info.txt`.
The patch SHA256 is
`a7779e6eee9ed076492f9f21de2f0643ec0c5d76fa66c2e34899048d97e4027e`.
Build, dispatch and non-verbose test logs are in that environment's `logs/`.
Private source, patches, binaries and individual results stay outside gpct.

## What was tested

The deterministic fixture has 128 synthetic individuals, 96 synthetic markers,
two synthetic chromosomes and one covariate. Both functions ran with one and four
workers, decoded full-marker products, prepared storage, block size 32 and
caller-supplied association scaling factor 1. All 96 association p-values were
finite and within [0,1]; both chromosome refits were returned. One/four-worker
p-values agreed at tolerance 1e-7 and selected the same prior.

| Interface | Candidates | Selected prior | Whole call, 1 worker | Whole call, 4 workers |
| --- | ---: | --- | ---: | ---: |
| Infinitesimal LOCO | 1 | ridge | 0.02 s | 0.02 s |
| Prior-selected LOCO | 10 | elastic_p0.010000_f0.100000 | 0.01 s | 0.01 s |

These are single, tiny, sequential calls with verbose logging disabled. Their
coarse timings and warm-up effects do not support method speed rankings or
thread-scaling conclusions. The variance diagnostic for both is
`blocked_rhe_mc_grid`: approximate blocked RHE/Monte Carlo refinement,
not the exact REML fit used by the existing greml/gsolve benchmark.

With the qualified GLMA package already installed, repeat the interface check:

```powershell
./environment/activate.ps1
$env:MKL_VERBOSE='1'
Rscript --vanilla tests/check_glma_mkl.R
$env:MKL_VERBOSE='0'
Rscript --vanilla tests/check_glma_mkl.R
```

The R check tests interfaces and worker agreement; the separate verbose log
establishes MKL dispatch. Passing the R check alone does not prove an MKL backend.

## Boundary for cattle and maize at the initial fixture checkpoint

These exported interfaces produce LOCO association scans. They do not directly
replace the benchmark's out-of-fold prediction interface. The current GPBench
arrays lack true chromosome/position/allele metadata; synthetic fixture metadata
must not be transferred to them. Real-data LOCO evaluation needs documented
marker mappings. The subsequently approved prediction comparison instead uses
the underlying global full-marker fits, without chromosome exclusions, through
the thin private prediction adapter. It is labelled full-marker prediction,
with prior selection confined to outer training individuals.
