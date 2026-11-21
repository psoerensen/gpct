# Rebuild the gpct Windows environment

The benchmark recipes use existing ecosystem interfaces. A new laptop needs a
way to rebuild those interfaces, not an undocumented copy of an old library.
This directory pins that recipe. It builds existing package source without
editing an owner checkout or adding statistical methods.

## Inputs and isolation

| Input | Pin / check |
| --- | --- |
| R | 4.4.3 UCRT x64; copied into a private environment before any BLAS replacement |
| Rtools44 | GCC 13.3.0, with the SHA-256-pinned OpenBLAS 0.3.29 static archive |
| R BLAS exports | Pinned upstream R source commit and SHA-256 in `runtime.csv` |
| CRAN dependencies | Exact Windows 4.4 package URLs, versions and SHA-256 in `cran-windows-4.4.csv` |
| Ecosystem source | Exact Git commits in `sources.csv`; clean snapshots, excluding uncommitted owner edits |
| Package assembly | The pinned gsuite `tools/build/build_source_repository.R`, reused unchanged |

Prerequisites on a fresh Windows laptop:

1. Install [R 4.4.3](https://cran.r-project.org/bin/windows/base/old/4.4.3/R-4.4.3-win.exe).
2. Install the x64 [Rtools44 6459-6401](https://cran.r-project.org/bin/windows/Rtools/rtools44/files/rtools44-6459-6401.exe)
   at `C:/rtools44`. The recipe checks the compiler and exact OpenBLAS archive;
   a different toolchain fails rather than silently changing the environment.
3. Install Git and authenticate for any source repositories that require access.
   The source pins are not a promise that private development repositories are
   anonymously downloadable. No credentials are stored in gpct.

PowerShell 7 is the tested shell. The default environment is
`~/gpct-environments/windows-r443-openblas`, outside this checkout. Archives,
source snapshots, build logs/caches, the R runtime and installed packages stay
there or in the configured download cache. Original source repositories and
shared R installations are read-only inputs.

## One build command

From the gpct repository root:

```powershell
./environment/bootstrap.ps1 -RHome 'C:/Program Files/R/R-4.4.3'
```

If the registered R 4.4.3 installation is already correct, `-RHome` is optional.
To reuse local source repositories as a download cache while still checking out
the pinned clean commits into separate snapshots:

```powershell
./environment/bootstrap.ps1 `
  -RHome 'C:/path/to/R-4.4.3' `
  -SourceRoot 'C:/Users/YOU/Documents/GitHub'
```

`-EnvRoot`, `-DownloadCache` and `-BlasThreads` can be supplied explicitly.
The default four BLAS runtime threads are separate from the single gbayes
package worker requested by each pilot.

The default build selects `gbase` and `gbayes`, plus the pinned CRAN dependencies
needed by the pilots. Source snapshots include the owners required by the
canonical builder. The same existing builder can be requested for the seven
public packages:

```powershell
./environment/bootstrap.ps1 -Packages gbase,gbayes,gcorr,glma,gmap,gscore,gsea
```

That command is a build recipe, not a claim that all seven have been freshly
qualified on this laptop. Current execution evidence belongs in
`docs/verification.md`. The root gsuite package and licensed standalone
application are separate distribution units.

The script uses the canonical source-package builder with `--skip-check` and
`--local-only`: package assembly, compilation, installation and the builder's
load smoke check run, but a complete `R CMD check` and broad scientific
qualification are not implied. The gpct smoke test separately checks the
documented Gaussian and weighted elastic-net example and numerical BLAS basics.

## Activate, verify and run

In each new PowerShell session:

```powershell
./environment/activate.ps1
Rscript --vanilla environment/preflight.R
Rscript --vanilla environment/smoke_test.R

$env:GPCT_DATA_DIR = 'C:/data/gpct'
$env:GPCT_OUTPUT_DIR = 'C:/results/gpct'
$env:GPCT_ACCEPT_POSITIONAL_IDS = 'yes'
$env:RETICULATE_PYTHON = 'C:/path/to/python-with-numpy.exe'

Rscript --vanilla scripts/prepare.R cattle
Rscript --vanilla benchmarks/cattle_prediction/run.R
Rscript --vanilla scripts/prepare.R maize
Rscript --vanilla benchmarks/maize_prediction/run.R
```

Preparation also needs an existing Python with NumPy; `reticulate` does not
install Python automatically. The archive revision, checksum and data contract
remain in `datasets/README.md` and the registry.

Preflight checks R and package versions, package paths, exported fitting
interfaces, the actually loaded OpenBLAS implementation and runtime thread
setting. The smoke test uses the exact small example from the
[public gbayes workflow](https://psoerensen.github.io/gtools/gsuite/docs/gbayes-workflow.html#runnable-gaussian-and-weighted-elastic-net-examples).
It verifies expected coefficients and prediction without touching the benchmark
data. Its output is not a benchmark result.

R retains its supplied LAPACK library while BLAS calls use OpenBLAS. This follows
R's [Windows fast-BLAS mechanism](https://cran.r-project.org/bin/windows/base/rw-FAQ.html#Can-I-use-a-fast-BLAS_003f)
and [OpenBLAS linker recipe](https://github.com/wch/r-source/blob/trunk/src/extra/blas/Makefile.win).
`blas_probe.c` only inspects the loaded DLL and OpenBLAS configuration; it
implements no numerical method. `runtime-checksums.csv` records the resulting
R/BLAS binary hashes. A configured memory budget is not a peak-RAM measurement.

## Rebuild and release policy

Keep the lock files under Git. Change a source revision, toolchain or dependency
only deliberately, then rebuild and rerun the smoke checks. Downloads are
checksum-verified and any mismatch stops the build. If an upstream archive is
removed, retain a verified cached copy or update the lock explicitly; the recipe
does not substitute an unpinned newer version.

The build can resume using its source/download caches, but canonical package
assembly may rebuild a package. It does not delete or clean original owner
caches. Preserve failed build evidence and diagnose failures in the isolated
environment.

No package or native binary is committed to gpct or automatically published to
gtools. Publishing a source-package release to gtools is a separate maintainer
workflow with package checks, interface tests, checksums, release indices and
an explicit publication request. The benchmark pages publish reviewed aggregate
outputs, not an unqualified ecosystem release.
