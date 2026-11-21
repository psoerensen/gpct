param(
  [string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
  [ValidateSet('Check','PackageOnly')][string]$Action='Check',
  [Parameter(Mandatory=$true)][string]$PrerequisiteRoot
)
$ErrorActionPreference='Stop'
# Maintainer-only build. No implementation files or binaries enter gpct.
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot
# Keep the integration build target out of the canonical normal-library guard.
$env:R_LIBS_USER=(Join-Path $EnvRoot 'library').Replace('\','/')
$env:R_LIBS_SITE=$env:R_LIBS_USER
$env:R_LIBS=$env:R_LIBS_USER
$suite=Join-Path $EnvRoot 'sources/gsuite'
$PrerequisiteRoot=(Resolve-Path -LiteralPath $PrerequisiteRoot).Path.Replace('\','/')
$prefix=Join-Path $suite 'build/prefix'
New-Item -ItemType Directory -Force -Path $prefix,(Join-Path $EnvRoot 'logs') | Out-Null
# Preserve the complete qualified SuiteSparse closure (including CAMD/CCOLAMD).
Get-ChildItem -LiteralPath (Join-Path $PrerequisiteRoot 'suitesparse-prefix') |
  Copy-Item -Destination $prefix -Recurse -Force
$env:GSUITE_QUALIFICATION_ROOT=$suite.Replace('\','/')
$env:GSUITE_SUITESPARSE_PREFIX="$PrerequisiteRoot/suitesparse-prefix"
$env:GSUITE_NATIVE_PREFIX=$prefix.Replace('\','/')
$env:GSUITE_MKL_RUNTIME_DIR="$PrerequisiteRoot/intel/Library/bin"
$env:GSUITE_INTEL_OPENMP_RUNTIME_DIR=$env:GSUITE_MKL_RUNTIME_DIR
$env:MKLROOT="$PrerequisiteRoot/intel/Library"
$env:MKL_DIR="$PrerequisiteRoot/intel/Library/lib/cmake/mkl"
$env:CMAKE_PREFIX_PATH="$PrerequisiteRoot/intel/Library;$PrerequisiteRoot/suitesparse-prefix"
$env:MKL_INTERFACE_LAYER='ILP64'
$env:MKL_THREADING_LAYER='INTEL'
$env:GSUITE_WINDOWS_SYSTEM_LIBRARIES="-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 $PrerequisiteRoot/windows-sdk-x64-10.0.26100.7705/c/um/x64/BufferOverflowU.lib"
$env:CMAKE_BUILD_PARALLEL_LEVEL='2'
[pscustomobject]@{native_prefix=$prefix.Replace('\','/');mkl_runtime=$env:GSUITE_MKL_RUNTIME_DIR;
  intel_runtime=$env:GSUITE_INTEL_OPENMP_RUNTIME_DIR} |
  ConvertTo-Json | Set-Content -LiteralPath (Join-Path $EnvRoot 'private-runtime.json')
$log=Join-Path $EnvRoot 'logs/gsuite-private-build.log'
if (Test-Path -LiteralPath $log) { Copy-Item -LiteralPath $log -Destination ($log+'.'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')+'.log') }
try {
  & (Join-Path $suite 'tools/build/build_workflow.ps1') -Action $Action *> $log
  if ($LASTEXITCODE -ne 0) { throw 'Canonical integration command failed; inspect the private build log.' }
} catch {
  # The pinned owner verifier requires a legacy reference R at a hard-coded path.
  # It is not applicable to this copied R/OpenBLAS runtime. Do not patch owner code
  # or claim its Windows binary-release qualification passed.
  if ($_.Exception.Message -notmatch 'Required qualification program is unavailable:.*R-4[.]4[.]1' -or
      !(Test-Path -LiteralPath (Join-Path $suite 'build/r-library/gsuite/DESCRIPTION'))) { throw }
  Write-Warning 'Package compiled/installed; legacy R-4.4.1 release verifier unavailable. Running the current benchmark checks instead.'
}
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot
& (Join-Path $EnvRoot 'R/bin/x64/Rscript.exe') --vanilla tests/check_interfaces.R
if ($LASTEXITCODE -ne 0) { throw 'Private benchmark interface checks failed' }
$dllRoot=Join-Path $suite 'build/r-library/gsuite/libs/x64'
$runtimeHashes=foreach ($file in @('gsuite.dll','libgsolve.dll','libgreml.dll','libcholmod.dll','mkl_rt.3.dll','mkl_core.3.dll','mkl_intel_thread.3.dll','libiomp5md.dll')) {
  $dll=Join-Path $dllRoot $file
  [pscustomobject]@{component=$file;sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLower()}
}
$runtimeHashes | Export-Csv -LiteralPath (Join-Path $EnvRoot 'native-runtime-checksums.csv') -NoTypeInformation
Write-Output "Private benchmark integration passed. Full release qualification is not implied: $suite/build/r-library"
