param(
  [string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
  [Parameter(Mandatory=$true)][string]$PrerequisiteRoot
)
$ErrorActionPreference='Stop'
# Run after bootstrap.ps1 and build-private.ps1. Numerical source stays private.
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot
$EnvRoot=(Resolve-Path -LiteralPath $EnvRoot).Path.Replace('\','/')
$PrerequisiteRoot=(Resolve-Path -LiteralPath $PrerequisiteRoot).Path.Replace('\','/')
$suite="$EnvRoot/sources/gsuite"
$pins=Import-Csv (Join-Path $PSScriptRoot 'sources.csv')
foreach($owner in @('gsuite','glma')) {
  $revision=(& git -C "$EnvRoot/sources/$owner" rev-parse HEAD).Trim()
  if($LASTEXITCODE -ne 0 -or $revision -ne ($pins | Where-Object repository -EQ $owner).revision) {
    throw "The isolated $owner source must match environment/sources.csv"
  }
}
$env:R_LIBS_USER="$EnvRoot/library"
$env:R_LIBS_SITE=$env:R_LIBS_USER
$env:R_LIBS=$env:R_LIBS_USER
$env:GSUITE_QUALIFICATION_ROOT=$suite
$env:GSUITE_NATIVE_PREFIX="$suite/build/prefix"
$env:GSUITE_SUITESPARSE_PREFIX="$PrerequisiteRoot/suitesparse-prefix"
$env:MKLROOT="$PrerequisiteRoot/intel/Library"
$env:MKL_DIR="$env:MKLROOT/lib/cmake/mkl"
$env:CMAKE_PREFIX_PATH="$env:MKLROOT;$env:GSUITE_SUITESPARSE_PREFIX"
$env:GSUITE_WINDOWS_SYSTEM_LIBRARIES="-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 $PrerequisiteRoot/windows-sdk-x64-10.0.26100.7705/c/um/x64/BufferOverflowU.lib"
$env:CMAKE_BUILD_PARALLEL_LEVEL='2'
$stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')
$log="$EnvRoot/logs/glma-mkl-build-$stamp.log"
& "$suite/tools/build/build_workflow.ps1" -Action NativeOnly -NativeComponents glma -NativeTests *> $log
if($LASTEXITCODE -ne 0){throw "Native GLMA build failed: $log"}
# The full-prefix manifest currently omits GLMA; verify installed artifacts first.
$version=Get-Content "$suite/build/prefix/lib/cmake/glma/glmaConfigVersion.cmake" -Raw
$header=Get-Content "$suite/build/prefix/include/glma/version.hpp" -Raw
if($version -notmatch 'set\(PACKAGE_VERSION "0.1.2"\)' -or
   $header -notmatch 'experimental_abi = 0;'){throw 'Unexpected GLMA version/ABI'}
$env:GLMA_VERSION='0.1.2'
$env:GLMA_ABI='0'
$env:GLMA_ALLOW_SUITE_FULL_MKL='1'
$env:GLMA_QUALIFIED_RUNTIME_DIR="$suite/build/r-library/gsuite/libs/x64"
$env:PATH="C:/rtools44/usr/bin;C:/rtools44/x86_64-w64-mingw32.static.posix/bin;$env:PATH"
& "$EnvRoot/R/bin/x64/R.exe" CMD INSTALL --preclean --no-multiarch `
  --library="$suite/build/r-library" "$suite/packages/glma" *>> $log
if($LASTEXITCODE -ne 0){throw "GLMA R installation failed: $log"}
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot
$env:MKL_VERBOSE='1'
$checkLog="$EnvRoot/logs/glma-mkl-prediction-check-$stamp.log"
try {
  & "$EnvRoot/R/bin/x64/Rscript.exe" --vanilla tests/check_glma_prediction.R *> $checkLog
  if($LASTEXITCODE -ne 0){throw "GLMA prediction checks failed: $checkLog"}
  if(!(Select-String -LiteralPath $checkLog -Pattern 'MKL_VERBOSE DGEMM' -Quiet)) {
    throw "No actual MKL DGEMM dispatch was observed: $checkLog"
  }
} finally { $env:MKL_VERBOSE='0' }
$destination="$EnvRoot/qualification/glma-mkl"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Get-ChildItem -LiteralPath "$suite/build/r-library/glma/libs/x64" -Filter *.dll |
  ForEach-Object {[pscustomobject]@{component=$_.Name;
    sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()}} |
  Export-Csv -LiteralPath "$destination/prediction-runtime-checksums.csv" -NoTypeInformation
Write-Output "GLMA full-marker prediction and MKL dispatch checks passed; this is not full release qualification. Logs: $log; $checkLog"
