# Reproducible gbayes benchmark environment

Use an isolated Windows R 4.4.3/OpenBLAS 0.3.29 environment, gbayes 0.1.16,
gbase 0.1.14 and the pinned Python/sklearn splitter. Sources and dependency
hashes are recorded in gbayes-sources.csv, runtime.csv and the dependency manifests.
Authorized access to private source repositories is required. Native numerical
source and binaries are not published in gpct.

```powershell
./environment/bootstrap.ps1 -RHome 'C:/Program Files/R/R-4.4.3' `
  -Python 'C:/path/to/python-3.12.exe' -Packages gbase,gbayes -BlasThreads 1
./environment/activate.ps1 -BlasThreads 1
Rscript --vanilla environment/preflight.R
Rscript --vanilla tests/check_protocol.R
```

Bootstrap uses existing owner source-package builders in isolated pinned
snapshots, not owner development checkouts. It does not run a full R CMD check
or publish any package. Preserve edited development snapshots; choose a clean
environment for a fresh rebuild rather than overwriting uncommitted work.

The current benchmark calls only gbayes with Glist. It does not require the
root gsuite mixed-model interface or a new GLMA adapter. The optional
build-private.ps1 recipe remains for the existing full-suite maintainer build;
that is separate from this benchmark and is not executed by its runner.
For that separate full-suite profile, bootstrap can explicitly select
`-SourceManifest environment/sources.csv`. The gbayes profile instead matches
the installed gbase/gbayes source manifests, including gsolve 8aa261a6b92b;
it must not be confused with the full-suite MKL build's gsolve revision.

Activation requests one OpenBLAS, MKL and OpenMP thread by default. The benchmark
driver runs four independent native chains concurrently through its explicit
ncores control and checks the actual worker count. BLAS remains at one thread.
The fixed Gaussian reference used one worker. These are
packed C++ engines; an optimized R BLAS alone does not imply native MKL
dispatch. Backend claims must follow the actual selected engine.

Use explicit external GPCT_DATA_DIR and GPCT_OUTPUT_DIR paths. R's home
directory can differ from USERPROFILE on Windows. The benchmark refuses
individual-data output paths inside the checkout. The monitored convenience
runner uses USERPROFILE/gpct-data and USERPROFILE/gpct-results, runs the two
datasets sequentially, disables BLAS logging and records whole-process peak
working set. This RAM measure includes package loading, preparation and output.

`run-glist-benchmark-plan.ps1` runs serial jobs, matched one/four-worker probes
and practical two/four-chain comparisons, then ten-fold CV with four concurrent
chains. Each chain has 500 burn-in and 1000 post-burn transitions. It temporarily
requests system execution availability while active, without preventing display
sleep or changing persistent power settings. It refreshes checked local pages
after each method completes both datasets, and performs no commit or push.

The local gbayes development build adds A/B/N through the existing scalar C++
engine. `build-cached-gbayes.ps1`, `finish-cache-default.ps1` and the private source
hashes/patches retain its rebuild identity. The package default cache is bounded
by min(2 GiB, 20% available physical RAM), shared across chains, with packed fallback.
The package version alone does not identify these unreleased local changes.
