param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas")
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:MKL_VERBOSE='0'
$runId='20261121-mcmc-learning-check'
foreach($method in @('bayesC_mcmc','bayesR_mcmc')) {
 foreach($case in @('maize','cattle')) {
  $result="$env:GPCT_OUTPUT_DIR/$runId/$method/$case/fold-results.csv"
  if(!(Test-Path -LiteralPath $result)){throw "Finish the native checkpoints first: $result"}
 }
}
foreach($case in @('maize','cattle')) {
 $log="$EnvRoot/logs/$runId-bglr_bayesC_masked-$case.log"
 if(Test-Path -LiteralPath $log){throw "Preserve the existing log: $log"}
 Write-Output "Comparing BGLR BayesC / ${case}: same fold 1, one thread; log: $log"
 & "$EnvRoot/R/bin/x64/Rscript.exe" --vanilla -e "source('scripts/run_bglr_comparison.R')" $case *> $log
 $code=$LASTEXITCODE
 Get-Content -LiteralPath $log -Tail 8
 if($code -ne 0){throw "BGLR / $case failed; inspect $log"}
}
