# Rebuild the benchmark environment

The public repository contains environment recipes and benchmark calls, not
private numerical implementation source or binaries. All snapshots, build
products, installed libraries, input data and individual results remain external.

## Pinned components

- R 4.4.3 UCRT x64 and Rtools44 GCC 13.3.0.
- OpenBLAS 0.3.29 for R BLAS; archive/export hashes in runtime.csv.
- CRAN Windows dependencies with exact URLs/hashes in cran-windows-4.4.csv.
- Python 3.12 with NumPy 1.26.4, SciPy 1.13.1 and scikit-learn 1.6.1; exact wheels/hashes in requirements-windows-3.12.txt.
- Private integration: gsuite 0.43.0, gsolve 0.28.0, greml 0.92.0 and the gbayes 0.1.16 R package; source commits in sources.csv. gbayes R bindings live in gsuite; its native core has its own repository.
- Native build prerequisites used here: Intel MKL 2026.2.1, Intel OpenMP 2026.2.0, SuiteSparse 7.12.3 and Windows SDK x64 10.0.26100.7705. They are private build inputs, not redistributions by gpct.

Install [R 4.4.3](https://cran.r-project.org/bin/windows/base/old/4.4.3/R-4.4.3-win.exe),
[Rtools44](https://cran.r-project.org/bin/windows/Rtools/rtools44/files/rtools44-6459-6401.exe),
Git and Python 3.12. Authenticate for the pinned private repositories. Use the
private gsuite owner's documented native-prerequisite setup for MKL, SuiteSparse
and the SDK; retain its verified download hashes and qualification evidence.
A public checkout does not grant private source access or distribute that setup.

## Build in PowerShell 7

```powershell
./environment/bootstrap.ps1 `
  -RHome 'C:/Program Files/R/R-4.4.3' `
  -Python 'C:/path/to/python-3.12.exe'

./environment/build-private.ps1 `
  -PrerequisiteRoot 'C:/path/to/qualified-native-dependencies'

./environment/build-glma-mkl.ps1 `
  -PrerequisiteRoot 'C:/path/to/qualified-native-dependencies'
```

The default target is ~/gpct-environments/windows-r443-openblas. Supply EnvRoot
explicitly to both scripts to change it. SourceRoot on bootstrap is an optional
local Git cache; pinned clean snapshots are still checked out separately. Owner
checkouts and shared R/Python installations are never build destinations.

The native prerequisite directory must have the existing owner layout:
intel/Library, suitesparse-prefix and windows-sdk-x64-10.0.26100.7705. The private
build reuses the owner's unchanged tools/build/build_workflow.ps1 in the pinned
gsuite snapshot. It builds the required native dependencies and root R integration
in that snapshot's build directory. The pinned canonical Windows release verifier hard-codes a separate R 4.4.1 installation, so its absence is recorded explicitly; the wrapper instead requires fresh benchmark interface checks under the private R 4.4.3/OpenBLAS runtime. It does not claim the legacy release verifier passed.
The full SuiteSparse closure is staged, including CAMD/CCOLAMD.

The base bootstrap uses the owner's source-package builder for gbase, with
skip-check/local-only. Neither step is a full R CMD check or release qualification.
No source package or binary is uploaded to gtools by these scripts.

## Activate and verify

```powershell
./environment/activate.ps1
Rscript --vanilla environment/preflight.R
Rscript --vanilla tests/check_protocol.R
Rscript --vanilla tests/check_interfaces.R
Rscript --vanilla tests/check_gbayes.R
Rscript --vanilla tests/check_reporting.R
```

Activation selects only libraries inside the private environment. It sets four
BLAS/MKL runtime threads by default, separately from the gsolve PCG worker count.
Preflight verifies the private R location, package paths, interface exports,
native versions, loaded OpenBLAS implementation/thread setting and DLL hash.
Interface checks compare equivalent small REML models and an independent dense
linear-solve reference. Run logs and native binaries stay private.

The [GLMA MKL interface check](glma-mkl-check.md) records a separate verified
full-prefix build of the two existing LOCO interfaces, including actual MKL
dispatch and the private build-support patch needed by their R wrapper.

The full-marker prediction adapter and explicit MKL build opt-in are now pinned
in the private gsuite/glma revisions in sources.csv. build-glma-mkl.ps1 builds
that adapter, checks its Gaussian predictions against an independent fixed-V
solve, and requires observed MKL DGEMM dispatch. It does not fabricate biological
marker annotations or execute association/LOCO scans on GPBench arrays.
Set GPCT_DATA_DIR and GPCT_OUTPUT_DIR explicitly when running recipes: R's `~`
can resolve to a redirected Windows Documents directory.

R retains its supplied LAPACK library while BLAS uses OpenBLAS, following
[R's fast-BLAS mechanism](https://cran.r-project.org/bin/windows/base/rw-FAQ.html#Can-I-use-a-fast-BLAS_003f).
A runtime thread setting does not measure observed CPU utilization. The benchmark
records fitting, prediction, kernel preparation and whole-case time separately;
peak RAM remains unmeasured.

These recipes pin the build inputs available to this authorized maintainer.
They have not been tested as an anonymous, network-only clean-room rebuild.
Do not substitute newer dependencies silently. Preserve failed build logs and
original owner caches; diagnose environment failures in the isolated environment.
