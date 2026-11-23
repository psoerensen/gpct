# Six sequential fold-1 checks; no website generation or Git mutations.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
 [string]$RunId='20261121-cache-comparison',[int]$LogicalCpu=2)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$mask=[Int64]1 -shl $LogicalCpu
$taskProcess=Get-Process -Id $PID
if(($taskProcess.ProcessorAffinity.ToInt64() -band $mask) -eq 0){throw 'Selected CPU is unavailable.'}
$taskProcess.ProcessorAffinity=[IntPtr]$mask
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:GPCT_RUN_ID=$RunId
$env:GPCT_MAX_FOLDS='1'
$env:GPCT_GBAYES_LIBRARY="$EnvRoot/cache-library"
$env:GPCT_DECODED_CACHE_BYTES='2147483648'
$env:MKL_VERBOSE='0'
$rscript="$EnvRoot/R/bin/x64/Rscript.exe"
$python="$EnvRoot/python/Scripts/python.exe"
$jobs=@(
 @('bayesC_mcmc','maize'),@('bglr_bayesC_masked','maize'),
 @('bayesC_mcmc','cattle'),@('bglr_bayesC_masked','cattle'),
 @('bayesR_mcmc','maize'),@('bayesR_mcmc','cattle'))
foreach($job in $jobs) {
 $method,$case=$job
 $log="$EnvRoot/logs/$RunId-$method-$case.log"
 if(Test-Path -LiteralPath $log){throw "Preserve existing log: $log"}
 $report="$env:GPCT_OUTPUT_DIR/$RunId/$method/$case/process-resources.json"
 Write-Output "Running $method / ${case}: saved fold 1, one thread, CPU $LogicalCpu; $log"
 if($method -eq 'bglr_bayesC_masked') {
  $available=(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory*1024
  $dense=if($case -eq 'cattle'){5024*42373*8.0}else{1458*75304*8.0}
  if($available -lt 5*$dense+2GB){throw 'Insufficient available RAM for a safe BGLR dense-input comparison.'}
  & $python environment/measure_process.py $report $rscript --vanilla -e "source('scripts/run_bglr_comparison.R')" $case *> $log
 } else {
  & $python environment/measure_process.py $report $rscript --vanilla -e "source('scripts/run_gbayes.R')" $method $case *> $log
 }
 $code=$LASTEXITCODE
 Get-Content -LiteralPath $log -Tail 7
 if($code -ne 0){throw "$method / $case failed; inspect $log"}
}
Write-Output 'Finished six local checks; no full CV, website update, commit or push.'
