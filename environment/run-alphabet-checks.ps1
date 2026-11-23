# Fresh, serial, saved-fold checks. Public pages are generated only by the full-CV driver.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
 [string]$RunId='20261121-alphabet-check-1t')
$ErrorActionPreference='Stop'
& "$PSScriptRoot/activate.ps1" -EnvRoot $EnvRoot -BlasThreads 1
(Get-Process -Id $PID).ProcessorAffinity=[IntPtr]4
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:GPCT_RUN_ID=$RunId
$env:GPCT_MAX_FOLDS='1'
$env:GPCT_WORKERS='1'
$env:GPCT_MCMC_CHAINS='2'
$env:GPCT_GBAYES_LIBRARY="$EnvRoot/cache-library"
foreach($method in @('bayesN_mcmc','bayesA_mcmc','bayesB_mcmc')) {
 foreach($case in @('maize','cattle')) {
  $dest="$env:GPCT_OUTPUT_DIR/$RunId/$method/$case"
  if(Test-Path -LiteralPath "$dest/fold-results.csv") {
   $rows=@(Import-Csv -LiteralPath "$dest/fold-results.csv")
   if(@($rows|Where-Object {$_.fold -eq '1' -and $_.status -eq 'completed'}).Count -eq 1){continue}
  }
  $log="$EnvRoot/logs/$RunId-$method-$case-$(Get-Date -Format yyyyMMddTHHmmss).log"
  Write-Output "Starting $method / $case saved fold 1; $log"
  & "$EnvRoot/python/Scripts/python.exe" environment/measure_process.py "$dest/process-resources.json" `
    "$EnvRoot/R/bin/x64/Rscript.exe" --vanilla -e "source('scripts/run_gbayes.R')" $method $case *> $log
  if($LASTEXITCODE -ne 0){Get-Content -LiteralPath $log -Tail 15;throw "Failed $method / $case"}
  Get-Content -LiteralPath $log -Tail 4
 }
}
