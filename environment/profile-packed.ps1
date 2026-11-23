# Diagnostic event replays only; no model fitting, installation or publication.
param(
 [string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
 [string]$Name="packed-kernels-$(Get-Date -Format yyyyMMddTHHmmss)",
 [ValidateRange(0,62)][int]$LogicalCpu=2,
 [bool]$BothModels=$true,
 [bool]$Cache=$true
)
$ErrorActionPreference='Stop'
if($Name -notmatch '^[A-Za-z0-9_-]+$'){throw 'Use a simple profile name.'}
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$taskProfileProcess=Get-Process -Id $PID
$taskAffinity=[Int64]1 -shl $LogicalCpu
if(($taskProfileProcess.ProcessorAffinity.ToInt64() -band $taskAffinity) -eq 0){throw 'Requested CPU is not available.'}
$taskProfileProcess.ProcessorAffinity=[IntPtr]$taskAffinity
$env:GPCT_PROFILE_AFFINITY_MASK="$taskAffinity"
$env:GPCT_KERNEL_PROFILE_NAME=$Name
$env:GPCT_KERNEL_PROFILE_MODE='paired'
$env:GPCT_PROFILE_BOTH_MODELS=if($BothModels){'1'}else{'0'}
$env:GPCT_PROFILE_CACHE=if($Cache){'1'}else{'0'}
$log=Join-Path $EnvRoot "logs/$Name.log"
if(Test-Path -LiteralPath $log){throw "Preserve the existing log: $log"}
& "$EnvRoot/R/bin/x64/Rscript.exe" --vanilla -e "source('scripts/profile_packed_kernels.R')" *> $log
$code=$LASTEXITCODE
Get-Content -LiteralPath $log -Tail 35
if($code -ne 0){throw "Kernel replay failed; inspect $log"}
