param(
  [string]$EnvRoot = "$env:USERPROFILE/gpct-environments/windows-r443-openblas",
  [ValidateRange(1,64)][int]$BlasThreads = 1
)
$ErrorActionPreference='Stop'
$EnvRoot=(Resolve-Path -LiteralPath $EnvRoot).Path
$rs=Join-Path $EnvRoot 'R/bin/x64/Rscript.exe'
if (!(Test-Path -LiteralPath $rs)) { throw 'Run environment/bootstrap.ps1 first.' }
$env:GPCT_ENV_DIR=$EnvRoot.Replace('\','/')
$env:R_HOME=(Join-Path $EnvRoot 'R').Replace('\','/')
$env:R_LIBS_USER=(Join-Path $EnvRoot 'library').Replace('\','/')
$privateLibrary=(Join-Path $EnvRoot 'sources/gsuite/build/r-library').Replace('\','/')
if (Test-Path -LiteralPath (Join-Path $privateLibrary 'gsuite/DESCRIPTION')) {
  $env:R_LIBS_USER="$privateLibrary;$env:R_LIBS_USER"
}
$env:R_LIBS_SITE=$env:R_LIBS_USER
$env:R_LIBS=$env:R_LIBS_USER
$env:PATH="$(Join-Path $EnvRoot 'R/bin/x64');$env:PATH"
$runtimeConfig=Join-Path $EnvRoot 'private-runtime.json'
if (Test-Path -LiteralPath $runtimeConfig) {
  $nativeRuntime=Get-Content -LiteralPath $runtimeConfig -Raw | ConvertFrom-Json
  $env:PATH="$($nativeRuntime.native_prefix)/bin;$($nativeRuntime.mkl_runtime);$($nativeRuntime.intel_runtime);$env:PATH"
  $env:GSUITE_MKL_RUNTIME_DIR=$nativeRuntime.mkl_runtime
  $env:GSUITE_INTEL_OPENMP_RUNTIME_DIR=$nativeRuntime.intel_runtime
  $env:MKL_INTERFACE_LAYER='ILP64'
  $env:MKL_THREADING_LAYER='INTEL'
}
$env:LC_ALL='C'
$env:OMP_NUM_THREADS="$BlasThreads"
$env:OPENBLAS_NUM_THREADS="$BlasThreads"
$env:MKL_NUM_THREADS="$BlasThreads"
$env:GPCT_PYTHON=(Join-Path $EnvRoot 'python/Scripts/python.exe').Replace('\','/')
$env:RETICULATE_PYTHON=$env:GPCT_PYTHON
$env:GPCT_CPU_MODEL='not recorded'
$env:GPCT_LOGICAL_PROCESSORS='not recorded'
$env:GPCT_INSTALLED_RAM_GIB='not recorded'
try {
  $cpu=Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
  $env:GPCT_CPU_MODEL=$cpu.Name.Trim()
  $env:GPCT_LOGICAL_PROCESSORS="$($cpu.NumberOfLogicalProcessors)"
  $ram=Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop | Measure-Object Capacity -Sum
  $env:GPCT_INSTALLED_RAM_GIB="$([Math]::Round($ram.Sum/1GB,1))"
} catch { Write-Warning 'Hardware inventory unavailable; metadata will say not recorded.' }
Write-Output "Activated gpct environment; requested BLAS runtime threads: $BlasThreads"
