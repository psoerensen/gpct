# Private source is required. Preserve the reference installation and native objects.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas")
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$native=Join-Path $EnvRoot 'sources/gbayes'
$suite=Join-Path $EnvRoot 'sources/gsuite'
$build=Join-Path $EnvRoot 'qualification/cache-integration/build'
$package=Join-Path $build 'gbayes'
$library=Join-Path $EnvRoot 'cache-library'
$reference=Join-Path $EnvRoot 'reference-library/gbayes'
if(!(Test-Path -LiteralPath "$reference/DESCRIPTION")){$reference=Join-Path $EnvRoot 'library/gbayes'}
$tools='C:/rtools44/x86_64-w64-mingw32.static.posix/bin'
$rs=Join-Path $EnvRoot 'R/bin/x64/Rscript.exe'
$env:PATH="$tools;C:/rtools44/usr/bin;$env:PATH"
$env:BINPREF="$tools/"
$env:R_LIBS_USER="$EnvRoot/library"
$env:R_LIBS_SITE=$env:R_LIBS_USER
$env:R_LIBS=$env:R_LIBS_USER
$dirty=@(& git -C $native diff --name-only)
if($LASTEXITCODE -ne 0){throw 'Cannot inspect private native source.'}
$referenceMatches=(Select-String -LiteralPath "$reference/source-manifest.txt" -Pattern '^Source-gbayes: (.+)$').Matches
if($referenceMatches.Count -ne 1){throw 'Reference native revision is ambiguous.'}
$referenceRevision=$referenceMatches[0].Groups[1].Value
$sourceRevision=(& git -C $native rev-parse HEAD).Trim()
if($sourceRevision -ne $referenceRevision){throw 'Reference archive revision differs; use the canonical full source-package builder.'}
if(@($dirty | Where-Object {$_ -notin @('src/individual_bed.cpp','src/mixture.cpp','include/gbayes/individual_bed.hpp','tests/test_individual_bed.cpp','README.md','docs/development.md')}).Count){throw 'Unexpected native changes; cannot reuse reference objects.'}
New-Item -ItemType Directory -Force -Path $build,$package,$library,"$package/src","$package/inst/lib" | Out-Null
$stage=Join-Path $suite 'build/source-repository/stage/gbayes'
Get-ChildItem -LiteralPath $stage | Where-Object {$_.Name -notin @('src','R')} | ForEach-Object {
 Copy-Item -LiteralPath $_.FullName -Destination $package -Recurse -Force
}
Copy-Item -LiteralPath "$suite/packages/gbayes/R" -Destination $package -Recurse -Force
Copy-Item -LiteralPath "$suite/packages/gbayes/man" -Destination $package -Recurse -Force
Copy-Item -LiteralPath "$suite/packages/gbayes/README.md" -Destination $package -Force
Get-ChildItem -LiteralPath "$suite/packages/gbayes/src" -File | Where-Object {$_.Extension -in @('.cpp','.hpp')} | ForEach-Object {
 Copy-Item -LiteralPath $_.FullName -Destination "$package/src" -Force
}
Copy-Item -LiteralPath "$native/include/gbayes" -Destination "$package/inst/include" -Recurse -Force
foreach($unit in @('individual_bed','mixture')) {
& "$tools/g++.exe" -std=gnu++17 -O2 -Wall -mfpmath=sse -msse2 -mstackrealign -fopenmp `
 -DGBAYES_STATIC_DEFINE -DGBITS_STATIC_DEFINE -DGMAT_STATIC_DEFINE -DGSOLVE_STATIC_DEFINE `
 "-I$native/include" "-I$EnvRoot/library/gbase/include" "-B$tools/" `
 -c "$native/src/$unit.cpp" -o "$build/$unit.o"
if($LASTEXITCODE -ne 0){throw "Native $unit compilation failed."}
}
Copy-Item -LiteralPath "$reference/lib/libgbayes_core.a" -Destination "$build/libgbayes_core.a" -Force
& "$tools/ar.exe" r "$build/libgbayes_core.a" "$build/individual_bed.o" "$build/mixture.o"
if($LASTEXITCODE -ne 0){throw 'Native archive update failed.'}
Copy-Item -LiteralPath "$build/libgbayes_core.a" -Destination "$package/inst/lib/libgbayes_core.a" -Force
$nativeInclude=$native.Replace('\','/')+'/include'
$scoreInclude=($EnvRoot.Replace('\','/')+'/sources/gscore/include')
$core=($build.Replace('\','/')+'/libgbayes_core.a')
$baseCore=($EnvRoot.Replace('\','/')+'/library/gbase/lib/libgsuite_core.a')
$baseInclude=($EnvRoot.Replace('\','/')+'/library/gbase/include')
@"
CXX_STD = CXX17
PKG_CPPFLAGS = -I"$nativeInclude" -I"$scoreInclude" -I"$baseInclude" -DGBAYES_STATIC_DEFINE -DGBITS_STATIC_DEFINE -DGMAT_STATIC_DEFINE -DGSOLVE_STATIC_DEFINE -DGSCORE_STATIC_DEFINE
PKG_CXXFLAGS = -fopenmp -B$tools/ -Wno-ignored-attributes -Wno-maybe-uninitialized
PKG_LIBS = -fopenmp -Wl,--whole-archive "$core" -Wl,--no-whole-archive "$baseCore" `$(BLAS_LIBS) `$(FLIBS)
OBJECTS = RcppExports.o adaptive_factor.o co_data_gaussian.o factor_support.o gbayes.o streamed_prediction.o summary_mcmc.o
"@ | Set-Content -LiteralPath "$package/src/Makevars.win"
$nativeHash=(Get-FileHash -LiteralPath "$native/src/individual_bed.cpp" -Algorithm SHA256).Hash
$bridgeHash=(Get-FileHash -LiteralPath "$suite/packages/gbayes/src/gbayes.cpp" -Algorithm SHA256).Hash
Add-Content -LiteralPath "$package/inst/source-manifest.txt" -Value @(
 'Local-Variant: RAM-budgeted scalar Glist cache and A/B/N models; two reference native objects refreshed',
 "Cache-Source-SHA256: $nativeHash","Cache-Rcpp-SHA256: $bridgeHash")
$log=Join-Path $EnvRoot "logs/cache-integration-build-$(Get-Date -Format yyyyMMddTHHmmss).log"
& "$EnvRoot/R/bin/R.exe" CMD INSTALL --no-multiarch --library=$library $package *> $log
$code=$LASTEXITCODE
Get-Content -LiteralPath $log -Tail 12
if($code -ne 0){throw "Cached gbayes installation failed; inspect $log"}
Write-Output "Installed separate cached gbayes in $library. Reference library is unchanged."
