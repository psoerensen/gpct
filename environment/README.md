# Reproducible gbayes benchmark environment

Use an isolated Windows R 4.4.3/OpenBLAS 0.3.29 environment, gbayes 0.1.16,
gbase 0.1.14 and the pinned Python/sklearn splitter. Sources and dependency
hashes are recorded in sources.csv, runtime.csv and the dependency manifests.
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

Activation requests one OpenBLAS, MKL and OpenMP thread by default. Every
gbayes fit requests ncores=1 and checks its actual worker count. These are
packed C++ engines; an optimized R BLAS alone does not imply native MKL
dispatch. Backend claims must follow the actual selected engine.

Use explicit external GPCT_DATA_DIR and GPCT_OUTPUT_DIR paths. R's home
directory can differ from USERPROFILE on Windows. The benchmark refuses
individual-data output paths inside the checkout. The monitored convenience
runner uses USERPROFILE/gpct-data and USERPROFILE/gpct-results, runs the two
datasets sequentially, disables BLAS logging and records whole-process peak
working set. This RAM measure includes package loading, preparation and output.
