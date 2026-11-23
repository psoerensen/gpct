# Serial measurements avoid cross-job CPU/RAM contention. No commit or push.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas",
 [switch]$ThreadProbeOnly,
 [string[]]$Methods=@('bayesC_mcmc','bayesR_mcmc','bayesN_mcmc','bayesA_mcmc','bayesB_mcmc'))
$ErrorActionPreference='Stop'
& "$PSScriptRoot/activate.ps1" -EnvRoot $EnvRoot -BlasThreads 1
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:GPCT_GBAYES_LIBRARY="$EnvRoot/cache-library"
$python="$EnvRoot/python/Scripts/python.exe"
$rs="$EnvRoot/R/bin/x64/Rscript.exe"
$study="$env:GPCT_OUTPUT_DIR/20261122-gbayes-glist-4t"
New-Item -ItemType Directory -Force -Path $study | Out-Null
$qualifiedBinary=(Get-FileHash -LiteralPath "$EnvRoot/cache-library/gbayes/libs/x64/gbayes.dll" -Algorithm SHA256).Hash
$fitRecipeHash=(Get-FileHash -LiteralPath scripts/run_gbayes.R -Algorithm SHA256).Hash
$methodRecipeHash=(Get-FileHash -LiteralPath benchmarks/methods.R -Algorithm SHA256).Hash
$baseAffinity=(Get-Process -Id $PID).ProcessorAffinity.ToInt64()
if(($baseAffinity -band 15) -ne 15){throw 'Logical CPUs 0/1/2/3 are unavailable; choose and document four available CPUs.'}
Add-Type -Namespace Gpct -Name OvernightExecution -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint flags);
'@
function Record-Stage([string]$stage,[string]$method,[string]$dataset='') {
 @{stage=$stage;method=$method;dataset=$dataset;updated_utc=[DateTime]::UtcNow.ToString('o')} |
  ConvertTo-Json | Set-Content -LiteralPath "$study/study-progress.json"
 Write-Output "$stage / $method / $dataset"
}
function Invoke-Fit([string]$batch,[string]$method,[string]$dataset,[int]$workers,[int]$folds,[int]$chains,[int]$burnin,[int]$draws) {
 if((Get-FileHash -LiteralPath "$EnvRoot/cache-library/gbayes/libs/x64/gbayes.dll" -Algorithm SHA256).Hash -ne $qualifiedBinary -or
    (Get-FileHash -LiteralPath scripts/run_gbayes.R -Algorithm SHA256).Hash -ne $fitRecipeHash -or
    (Get-FileHash -LiteralPath benchmarks/methods.R -Algorithm SHA256).Hash -ne $methodRecipeHash) {
  throw 'The benchmark binary or fitting recipe changed during this study; preserve the evidence and review before continuing.'
 }
 $env:GPCT_RUN_ID=$batch;$env:GPCT_WORKERS="$workers";$env:GPCT_MAX_FOLDS="$folds"
 $env:GPCT_MCMC_CHAINS="$chains";$env:GPCT_MCMC_BURNIN="$burnin";$env:GPCT_MCMC_NIT="$draws"
 $dest="$env:GPCT_OUTPUT_DIR/$batch/$method/$dataset"
 $status="$dest/status.csv"
 if(Test-Path -LiteralPath $status) {
  $state=Import-Csv -LiteralPath $status
  if(($folds -eq 10 -and $state.status -eq 'completed') -or
     ($folds -eq 1 -and (Test-Path -LiteralPath "$dest/process-resources.json"))) {
   $resource=Get-Content -LiteralPath "$dest/process-resources.json" -Raw | ConvertFrom-Json
   if($resource.exit_code -eq 0){return}
  }
 }
 # Fresh processes; cached training Glist metadata are shared across methods.
 (Get-Process -Id $PID).ProcessorAffinity=[IntPtr]$(if($workers -eq 1){4}else{15})
 $log="$EnvRoot/logs/$batch-$method-$dataset-$(Get-Date -Format yyyyMMddTHHmmss).log"
 $completedBefore=if(Test-Path -LiteralPath "$dest/fold-results.csv"){
  @((Import-Csv -LiteralPath "$dest/fold-results.csv")|Where-Object {$_.status -eq 'completed'}).Count
 }else{0}
 if(Test-Path -LiteralPath "$dest/process-resources.json") {
  $resourcePath=(Resolve-Path -LiteralPath "$dest/process-resources.json").Path
  $resourceRoot=(Resolve-Path -LiteralPath $dest).Path
  $archivePath=[IO.Path]::GetFullPath("$dest/process-resources-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')).json")
  if(!$resourcePath.StartsWith($resourceRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or
     !$archivePath.StartsWith($resourceRoot+'\',[StringComparison]::OrdinalIgnoreCase)) {
   throw 'Resource archive paths left the measured run directory.'
  }
  Move-Item -LiteralPath $resourcePath -Destination $archivePath
 }
 Record-Stage $(if($folds -eq 1){"thread-probe-${workers}t"}else{'ten-fold-run'}) $method $dataset
 & $python environment/measure_process.py "$dest/process-resources.json" $rs --vanilla `
   -e "source('scripts/run_gbayes.R')" $method $dataset *> $log
 $code=$LASTEXITCODE
 if(Test-Path -LiteralPath "$dest/process-resources.json") {
  $measurement=Get-Content -LiteralPath "$dest/process-resources.json" -Raw | ConvertFrom-Json
  $measurement | Add-Member -NotePropertyName completed_folds_at_start -NotePropertyValue $completedBefore -Force
  $measurement | Add-Member -NotePropertyName requested_workers -NotePropertyValue $workers -Force
  $measurement | Add-Member -NotePropertyName logical_chains -NotePropertyValue $chains -Force
  $measurement | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath "$dest/process-resources.json"
 }
 Get-Content -LiteralPath $log -Tail 5
 if($code -ne 0){throw "Fit failed; retained evidence: $log"}
}
try {
 # Prevent automatic system sleep only while this queue is active; allow display sleep.
 $awakeState=[Gpct.OvernightExecution]::SetThreadExecutionState([uint32]2147483649)
 if($awakeState -eq 0){Write-Warning 'The process could not request overnight execution availability.'}
 & $rs --vanilla environment/preflight.R
 if($LASTEXITCODE -ne 0){throw 'Pinned runtime/BLAS preflight failed.'}
 # Rebuild the reference when starting on a new machine; old run files are not required.
 foreach($dataset in @('maize','cattle')) {
  $referenceDir="$env:GPCT_OUTPUT_DIR/20261121-gbayes-glist-1t/marker_gaussian/$dataset"
  $referenceReady=$false
  if((Test-Path -LiteralPath "$referenceDir/status.csv") -and (Test-Path -LiteralPath "$referenceDir/fold-results.csv")) {
   $referenceReady=(Import-Csv -LiteralPath "$referenceDir/status.csv").status -eq 'completed' -and
    @((Import-Csv -LiteralPath "$referenceDir/fold-results.csv")|Where-Object {$_.status -eq 'completed'}).Count -eq 10
  }
  if(!$referenceReady){Invoke-Fit '20261121-gbayes-glist-1t' 'marker_gaussian' $dataset 1 10 2 500 1000}
 }
 foreach($method in $Methods) {
  foreach($dataset in @('maize','cattle')) {
   & $rs --vanilla scripts/select_chain_reference.R $method $dataset
   if($LASTEXITCODE -ne 0){throw 'Reference identity inspection failed.'}
   $reference=Get-Content -LiteralPath "$env:GPCT_OUTPUT_DIR/20261122-chain-comparison-summary/references/$method-$dataset.json" -Raw | ConvertFrom-Json
   if(!$reference.ready) {
    Invoke-Fit '20261122-chain-comparison-1t' $method $dataset 1 1 2 500 1000
    & $rs --vanilla scripts/select_chain_reference.R $method $dataset
    if($LASTEXITCODE -ne 0){throw 'New matched-binary reference inspection failed.'}
   }
  }
  foreach($workers in @(1,4)) {
   foreach($dataset in @('maize','cattle')) {
    Invoke-Fit "20261122-thread-probe-${workers}t" $method $dataset $workers 1 4 100 200
   }
  }
  & $rs --vanilla scripts/summarise_thread_probe.R $method
  if($LASTEXITCODE -ne 0){throw 'Thread-probe parity/measurement check failed.'}
  foreach($dataset in @('maize','cattle')) {
   Invoke-Fit '20261122-gbayes-glist-4t' $method $dataset 4 1 4 500 1000
  }
  & $rs --vanilla scripts/summarise_chain_comparison.R $method
  if($LASTEXITCODE -ne 0){throw 'Two/four-chain comparison check failed.'}
  if($ThreadProbeOnly){continue}
  foreach($dataset in @('maize','cattle')) {
   Invoke-Fit '20261122-gbayes-glist-4t' $method $dataset 4 10 4 500 1000
  }
  Record-Stage 'updating-local-website' $method
  $env:GPCT_RUN_ID='20261122-gbayes-glist-4t'
  & $rs --vanilla scripts/publish_gbayes.R
  if($LASTEXITCODE -ne 0){throw 'Aggregate website generation failed.'}
  & $python tests/check_website.py
  if($LASTEXITCODE -ne 0){throw 'Website validation failed.'}
  Write-Output "Updated and checked local website after $method completed both datasets. No Git mutations."
 }
 Record-Stage $(if($ThreadProbeOnly){'thread probes completed; full CV pending'}else{'completed'}) 'BayesA/B/C/N/R'
} catch {
 Record-Stage 'failed; evidence retained' $method
 throw
} finally {
 [Gpct.OvernightExecution]::SetThreadExecutionState([uint32]2147483648) | Out-Null
 (Get-Process -Id $PID).ProcessorAffinity=[IntPtr]$baseAffinity
}
