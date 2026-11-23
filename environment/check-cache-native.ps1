# Focused canonical CMake target; preserve and reuse the existing build cache/prefix.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas")
$ErrorActionPreference='Stop'
$tools='C:/rtools44/x86_64-w64-mingw32.static.posix/bin'
$env:PATH="$tools;C:/rtools44/usr/bin;$EnvRoot/sources/gsuite/build/prefix/bin;$env:PATH"
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$build="$EnvRoot/sources/gsuite/build/gbayes"
$source="$EnvRoot/sources/gbayes"
$stamp=Get-Date -Format yyyyMMddTHHmmss
$log="$EnvRoot/logs/cache-native-check-$stamp.log"
$env:CMAKE_BUILD_PARALLEL_LEVEL='2'
$workflow="$EnvRoot/sources/gsuite/tools/build/build_workflow.ps1"
& $workflow -Action NativeOnly -NativeComponents gbayes -NativeTests *> $log
if($LASTEXITCODE -ne 0){throw "Canonical gbayes native refresh failed; inspect $log"}
& "$tools/cmake.exe" --build $build --target test_individual_bed --parallel 2 *>> $log
if($LASTEXITCODE -ne 0){throw "Native BED test build failed; inspect $log"}
& "$tools/ctest.exe" --test-dir $build -R '^gbayes.individual_bed$' --output-on-failure *>> $log
$code=$LASTEXITCODE
Get-Content -LiteralPath $log -Tail 15
if($code -ne 0){throw "Native BED regression failed; inspect $log"}
