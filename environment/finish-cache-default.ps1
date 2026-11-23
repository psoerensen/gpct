# Install the qualified package behavior, preserving the original reference package.
param([string]$EnvRoot="$env:USERPROFILE/gpct-environments/windows-r443-openblas")
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'activate.ps1') -EnvRoot $EnvRoot -BlasThreads 1
$active=@(Get-CimInstance Win32_Process -Filter "Name='Rscript.exe'" | Where-Object {
 $_.CommandLine -like '*run_gbayes.R*' -or $_.CommandLine -like '*run_bglr_comparison.R*'
})
if($active.Count){throw 'Finish the active benchmark processes before refreshing the package.'}
$package=Join-Path $EnvRoot 'qualification/cache-integration/build/gbayes'
$suite=Join-Path $EnvRoot 'sources/gsuite'
$referenceLibrary=Join-Path $EnvRoot 'reference-library'
if(!(Test-Path -LiteralPath "$referenceLibrary/gbayes/DESCRIPTION")) {
 New-Item -ItemType Directory -Path $referenceLibrary -Force | Out-Null
 Copy-Item -LiteralPath "$EnvRoot/library/gbayes" -Destination $referenceLibrary -Recurse
}
Get-ChildItem -LiteralPath "$suite/packages/gbayes/R" -File | ForEach-Object {
 Copy-Item -LiteralPath $_.FullName -Destination "$package/R" -Force
}
Get-ChildItem -LiteralPath "$suite/packages/gbayes/man" -File | ForEach-Object {
 Copy-Item -LiteralPath $_.FullName -Destination "$package/man" -Force
}
Copy-Item -LiteralPath "$suite/packages/gbayes/README.md" -Destination $package -Force
$manifest=Get-Content -LiteralPath "$package/inst/source-manifest.txt"
$manifest=$manifest -replace '^Local-Variant:.*$','Local-Variant: package-default RAM-budgeted scalar Glist cache; native A/B/N additions'
$manifest | Set-Content -LiteralPath "$package/inst/source-manifest.txt"
foreach($source in @('gbayes/src/mixture.cpp','gbayes/include/gbayes/alphabet.hpp','gbayes/src/individual_bed.cpp','gsuite/packages/gbayes/src/gbayes.cpp')) {
 $hash=(Get-FileHash -LiteralPath "$EnvRoot/sources/$source" -Algorithm SHA256).Hash
 Add-Content -LiteralPath "$package/inst/source-manifest.txt" -Value "Local-source-SHA256: $source $hash"
}
$rs="$EnvRoot/R/bin/x64/Rscript.exe"
$rexe="$EnvRoot/R/bin/R.exe"
$env:PATH="C:/rtools44/x86_64-w64-mingw32.static.posix/bin;C:/rtools44/usr/bin;$env:PATH"
$env:BINPREF='C:/rtools44/x86_64-w64-mingw32.static.posix/bin/'
$env:R_LIBS_USER="$EnvRoot/library"
$env:R_LIBS_SITE=$env:R_LIBS_USER
$env:R_LIBS=$env:R_LIBS_USER
$stamp=Get-Date -Format yyyyMMddTHHmmss
$log="$EnvRoot/logs/cache-default-validation-install-$stamp.log"
& $rexe CMD INSTALL --no-multiarch --library="$EnvRoot/cache-library" $package *> $log
if($LASTEXITCODE -ne 0){throw "Cache-default installation failed; inspect $log"}
& $rs --vanilla scripts/validate_cached_glist.R candidate
if($LASTEXITCODE -ne 0){throw 'Cache-default fixture fits failed.'}
& $rs --vanilla scripts/validate_cached_glist.R compare
if($LASTEXITCODE -ne 0){throw 'Cache-default regression checks failed.'}
$normalLog="$EnvRoot/logs/cache-default-normal-install-$stamp.log"
& $rexe CMD INSTALL --no-multiarch --library="$EnvRoot/library" $package *> $normalLog
if($LASTEXITCODE -ne 0){throw "Normal local gbayes installation failed; inspect $normalLog"}
$normalHash=(Get-FileHash -LiteralPath "$EnvRoot/library/gbayes/libs/x64/gbayes.dll" -Algorithm SHA256).Hash
$testedHash=(Get-FileHash -LiteralPath "$EnvRoot/cache-library/gbayes/libs/x64/gbayes.dll" -Algorithm SHA256).Hash
if($normalHash -ne $testedHash){throw 'Normal and tested native binaries differ.'}
& $rs --vanilla scripts/validate_cached_glist.R normal
if($LASTEXITCODE -ne 0){throw 'Normal package default checks failed.'}
& $rs --vanilla scripts/validate_cached_glist.R compare
if($LASTEXITCODE -ne 0){throw 'Normal package parity checks failed.'}
[PSCustomObject]@{binary_sha256=$normalHash;library="$EnvRoot/library";reference_library=$referenceLibrary;
 policy='Package default for scalar individual-level Glist A/B/C/N/R: min(2 GiB, 20% available RAM), packed fallback';
 qualified_utc=[DateTime]::UtcNow.ToString('o')} |
 ConvertTo-Json | Set-Content -LiteralPath "$EnvRoot/qualification/cache-integration/default-qualified.json"
Write-Output 'Updated the normal local gbayes package. No activation override, website update, commit or push.'
