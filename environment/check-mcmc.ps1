param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
 [string]$RunId='20261121-mcmc-learning-check')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:GPCT_RUN_ID=$RunId
$env:GPCT_MAX_FOLDS='1'
$env:MKL_VERBOSE='0'
foreach($method in @('bayesC_mcmc','bayesR_mcmc')) {
 foreach($case in @('maize','cattle')) {
  $log="$EnvRoot/logs/$RunId-$method-$case.log"
  if(Test-Path -LiteralPath $log){throw "Preserve the existing log; choose another RunId: $log"}
  Write-Output "Checking $method / ${case}: fold 1, one worker; log: $log"
  # source() parses the complete recipe before evaluation; no live file stream.
  & "$EnvRoot/R/bin/x64/Rscript.exe" --vanilla -e "source('scripts/run_gbayes.R')" $method $case *> $log
  $code=$LASTEXITCODE
  Get-Content -LiteralPath $log -Tail 6
  if($code -ne 0){throw "$method / $case checkpoint failed; inspect $log"}
 }
}
Write-Output 'Finished four one-fold MCMC checks; no full-CV run or publication was started.'
