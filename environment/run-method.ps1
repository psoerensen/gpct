param([Parameter(Mandatory=$true)][ValidateSet('marker_gaussian','elastic_net','laplace_gaussian','bayesC_vb','bayesC_mcmc','bayesR_mcmc')][string]$Method,
 [string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas")
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$env:GPCT_DATA_DIR="$env:USERPROFILE/gpct-data"
$env:GPCT_OUTPUT_DIR="$env:USERPROFILE/gpct-results"
$env:GPCT_RUN_ID='20261121-gbayes-glist-1t'
$env:GPCT_MAX_FOLDS='10'
$env:MKL_VERBOSE='0'
foreach($case in @('maize','cattle')) {
 $destination="$env:GPCT_OUTPUT_DIR/$env:GPCT_RUN_ID/$Method/$case"
 $foldFile="$destination/fold-results.csv"
 $completedBefore=if(Test-Path -LiteralPath $foldFile){@(Import-Csv -LiteralPath $foldFile).Count}else{0}
 $phenotypeCached=Test-Path -LiteralPath "$env:GPCT_DATA_DIR/glist/20261121-maf001-miss005/$case/phenotype-only.rds"
 $cacheDirectory="$env:GPCT_OUTPUT_DIR/$env:GPCT_RUN_ID/glist-cache/$case"
 $cachedGlists=if(Test-Path -LiteralPath $cacheDirectory){@(Get-ChildItem -LiteralPath $cacheDirectory -Filter *.rds).Count}else{0}
 $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmss')
 $log="$EnvRoot/logs/gbayes-1t-$Method-$case-$stamp.log"
 $err="$EnvRoot/logs/gbayes-1t-$Method-$case-$stamp.stderr.log"
 Write-Output "Running $Method / $case with one worker; log: $log"
 $process=Start-Process -FilePath "$EnvRoot/R/bin/x64/Rscript.exe" `
  -ArgumentList @('--vanilla','scripts/run_gbayes.R',$Method,$case) `
  -WorkingDirectory (Split-Path $PSScriptRoot -Parent) -WindowStyle Hidden `
  -RedirectStandardOutput $log -RedirectStandardError $err -PassThru
 $peakBytes=0L
 while(-not $process.WaitForExit(250)) {
  $process.Refresh()
  if(-not $process.HasExited){$peakBytes=[Math]::Max($peakBytes,$process.PeakWorkingSet64)}
 }
 $process.WaitForExit();$process.Refresh()
 $destination="$env:GPCT_OUTPUT_DIR/$env:GPCT_RUN_ID/$Method/$case"
 if(Test-Path -LiteralPath $destination){
  [pscustomobject]@{process_peak_working_set_mib=[Math]::Round($peakBytes/1MB,2);
   scope='Whole dataset-method process, including package loading, preparation, fitting and prediction';
   polling_interval_ms=250;completed_folds_at_start=$completedBefore;
   phenotype_cache_preexisting=$phenotypeCached;training_glists_cached_at_start=$cachedGlists;
   stdout_log=$log;stderr_log=$err} |
   Export-Csv -LiteralPath "$destination/process-resources.csv" -NoTypeInformation
 }
 if($process.ExitCode -ne 0){Get-Content -LiteralPath $log -Tail 8;Get-Content -LiteralPath $err -Tail 8;throw "$Method / $case failed"}
 Get-Content -LiteralPath $log -Tail 2
}
Write-Output "Completed $Method on both datasets."
