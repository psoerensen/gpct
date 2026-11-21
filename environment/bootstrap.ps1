# Rebuild existing packages using their canonical source-package builder.
# All writes go to EnvRoot/DownloadCache; owner checkouts are read-only inputs.
param(
  [string]$RHome = '',
  [string]$RtoolsHome = 'C:/rtools44',
  [string]$SourceRoot = '',
  [string]$Python = '',
  [string]$EnvRoot = "$env:USERPROFILE/gpct-environments/windows-r443-openblas",
  [string]$DownloadCache = '',
  [ValidateRange(1,64)][int]$BlasThreads = 4,
  [ValidateSet('gbase','gbayes','gcorr','glma','gmap','gscore','gsea')]
  [string[]]$Packages = @('gbase')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path $PSScriptRoot -Parent
$pins = @{}
Import-Csv (Join-Path $PSScriptRoot 'runtime.csv') | ForEach-Object { $pins[$_.key] = $_.value }
$EnvRoot = [IO.Path]::GetFullPath($EnvRoot)
$repoFull = [IO.Path]::GetFullPath($repo)
if ($EnvRoot.Equals($repoFull,[StringComparison]::OrdinalIgnoreCase) -or
    $EnvRoot.StartsWith($repoFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
  throw 'EnvRoot must be outside the gpct checkout.'
}
if (!$RHome) {
  foreach ($key in @('HKCU:\Software\R-core\R','HKLM:\Software\R-core\R')) {
    $entry = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
    if ($entry -and $entry.PSObject.Properties['InstallPath']) { $RHome=$entry.InstallPath; break }
  }
}
if (!$RHome) { throw "Supply -RHome pointing to R $($pins.r_version). See environment/README.md." }
$RHome = (Resolve-Path -LiteralPath $RHome).Path
$donorScript = Join-Path $RHome 'bin/x64/Rscript.exe'
if (!(Test-Path -LiteralPath $donorScript)) { throw "Missing Rscript: $donorScript" }
$env:LC_ALL='C'
$version = (& $donorScript --vanilla -e 'cat(as.character(getRversion()))').Trim()
if ($LASTEXITCODE -ne 0 -or $version -ne $pins.r_version) { throw "Requires R $($pins.r_version); found $version" }
$toolBin = Join-Path $RtoolsHome 'x86_64-w64-mingw32.static.posix/bin'
$gfortran = Join-Path $toolBin 'gfortran.exe'
$compiler = (& $gfortran --version | Select-Object -First 1)
if ($LASTEXITCODE -ne 0 -or $compiler -notmatch [regex]::Escape($pins.compiler_version)) {
  throw "Compiler does not match pinned GCC $($pins.compiler_version)"
}
$openblas = Join-Path $RtoolsHome 'x86_64-w64-mingw32.static.posix/lib/libopenblas.a'
if ((Get-FileHash -LiteralPath $openblas -Algorithm SHA256).Hash.ToLower() -ne $pins.openblas_archive_sha256) {
  throw 'Rtools OpenBLAS archive differs from the pinned build. Review/update the lock deliberately.'
}
New-Item -ItemType Directory -Force -Path $EnvRoot | Out-Null
if (!$DownloadCache) { $DownloadCache=Join-Path $EnvRoot 'cache' }
New-Item -ItemType Directory -Force -Path $DownloadCache | Out-Null
$DownloadCache = (Resolve-Path -LiteralPath $DownloadCache).Path
function Checked([string]$Program,[string[]]$Arguments,[string]$Directory,[string]$LogPath='') {
  Push-Location $Directory
  try {
    if ($LogPath) { & $Program @Arguments 2>&1 | Tee-Object -FilePath $LogPath -Append }
    else { & $Program @Arguments }
    if ($LASTEXITCODE -ne 0) { throw "Command failed ($LASTEXITCODE): $Program" }
  }
  finally { Pop-Location }
}
function Cached([string]$Url,[string]$Hash,[string]$Name) {
  $path=Join-Path $DownloadCache $Name
  if (!(Test-Path -LiteralPath $path)) { Invoke-WebRequest $Url -OutFile $path }
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower() -ne $Hash.ToLower()) {
    throw "SHA-256 mismatch: $Name"
  }
  return $path
}
$runtime=Join-Path $EnvRoot 'R'
Write-Output 'Preparing the isolated R runtime and OpenBLAS.'
if (!(Test-Path -LiteralPath (Join-Path $runtime 'bin/x64/Rscript.exe'))) {
  Copy-Item -LiteralPath $RHome -Destination $runtime -Recurse
}
$r=Join-Path $runtime 'bin/x64/R.exe'
$rs=Join-Path $runtime 'bin/x64/Rscript.exe'
$library=Join-Path $EnvRoot 'library'
$probe=Join-Path $EnvRoot 'probe'
$build=Join-Path $EnvRoot 'blas-build'
New-Item -ItemType Directory -Force -Path $library,$probe,$build | Out-Null
$env:GPCT_ENV_DIR=$EnvRoot.Replace('\','/')
$env:R_HOME=$runtime.Replace('\','/')
$env:R_LIBS_USER=$library.Replace('\','/')
$env:R_LIBS_SITE=$library.Replace('\','/')
$env:R_LIBS=$library.Replace('\','/')
$env:RTOOLS44_HOME=$RtoolsHome.Replace('\','/')
$env:OMP_NUM_THREADS="$BlasThreads"
$env:OPENBLAS_NUM_THREADS="$BlasThreads"
$env:MKL_NUM_THREADS="$BlasThreads"
$env:PATH="$toolBin;$(Join-Path $RtoolsHome 'usr/bin');$(Join-Path $runtime 'bin/x64');$env:PATH"
$definition=Cached $pins.blas_def_url $pins.blas_def_sha256 'Rblas.def'
$exportFile=Join-Path $build 'Rblas-openblas.def'
$exports=[IO.File]::ReadAllText($definition)+"`n openblas_get_config`n openblas_get_corename`n openblas_get_num_threads`n openblas_set_num_threads`n"
[IO.File]::WriteAllText($exportFile,$exports,[Text.UTF8Encoding]::new($false))
$blasOutput=Join-Path $build 'Rblas.dll'
# Follows R's Rblas.def + OpenBLAS link recipe, with explicit inspection exports.
Checked $gfortran @('-shared','-s','-o',$blasOutput,$exportFile,
  ('-L'+(Join-Path $runtime 'bin/x64')),'-lR',
  ('-L'+(Split-Path $openblas -Parent)),'-lopenblas','-fopenmp','-lpthread',
  '-static-libgcc','-static-libgfortran') $build
Copy-Item -LiteralPath $blasOutput -Destination (Join-Path $runtime 'bin/x64/Rblas.dll') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'blas_probe.c') -Destination (Join-Path $probe 'blas_probe.c') -Force
Checked $r @('CMD','SHLIB','-o','blas_probe.dll','blas_probe.c') $probe
Checked $rs @('--vanilla','-e',('dyn.load("'+$probe.Replace('\','/')+'/blas_probe.dll");print(.Call("gpct_blas_info"))')) $repo
$cran=Import-Csv (Join-Path $PSScriptRoot 'cran-windows-4.4.csv')
Write-Output 'Installing the pinned CRAN dependencies into the private library.'
foreach ($item in $cran) {
  $null=Cached $item.url $item.sha256 ($item.package+'_'+$item.version+'.zip')
}
Checked $rs @('--vanilla',(Join-Path $PSScriptRoot 'install_dependencies.R'),$library,$DownloadCache,
  (Join-Path $PSScriptRoot 'cran-windows-4.4.csv')) $repo
$sourcePins=Import-Csv (Join-Path $PSScriptRoot 'sources.csv')
$snapshots=Join-Path $EnvRoot 'sources'
New-Item -ItemType Directory -Force -Path $snapshots | Out-Null
foreach ($item in $sourcePins) {
  Write-Output ('Preparing pinned source snapshot: '+$item.repository)
  $target=Join-Path $snapshots $item.repository
  if (!(Test-Path -LiteralPath (Join-Path $target '.git'))) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Checked git @('init','--quiet') $target
    Checked git @('remote','add','origin',$item.url) $target
    $from=$item.url
    if ($SourceRoot) {
      $candidate=Join-Path $SourceRoot $item.repository
      if (Test-Path -LiteralPath (Join-Path $candidate '.git')) {
        $hasCommit=$false
        try {
          & git -C $candidate cat-file -e ($item.revision+'^{commit}') 2>$null
          $hasCommit=($LASTEXITCODE -eq 0)
        } catch { $hasCommit=$false }
        if ($hasCommit) { $from=$candidate }
      }
    }
    Checked git @('fetch','--quiet','--depth','1',$from,$item.revision) $target
    Checked git @('checkout','--quiet','--detach',$item.revision) $target
  }
  $actual=(& git -C $target rev-parse HEAD).Trim()
  $dirty=@(& git -C $target status --porcelain --untracked-files=no)
  if ($dirty.Count) { throw "Source snapshot has tracked edits: $target" }
  if ($actual -ne $item.revision) {
    Checked git @('fetch','--quiet','--depth','1','origin',$item.revision) $target
    Checked git @('checkout','--quiet','--detach',$item.revision) $target
  }
}
$selected=@('gbase')+@($Packages)
if (@($selected | Where-Object {$_ -ne 'gbase'}).Count) { $selected+= 'gbayes' }
if ($selected -contains 'gsea') { $selected+='glma' }
$builder=Join-Path $snapshots 'gsuite/tools/build/build_source_repository.R'
$logs=Join-Path $EnvRoot 'logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
foreach ($package in @('gbase','gbayes','gcorr','glma','gmap','gscore','gsea')) {
  if ($selected -notcontains $package) { continue }
  Write-Output ('Building with the canonical source-package recipe: '+$package)
  Checked $rs @('--vanilla',$builder,('--only='+$package),'--skip-check','--local-only',('--library='+$library)) $repo (Join-Path $logs ($package+'-build.log'))
}
Checked $rs @('--vanilla',(Join-Path $PSScriptRoot 'smoke_test.R')) $repo (Join-Path $logs 'smoke-test.log')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sources.csv') -Destination (Join-Path $EnvRoot 'sources.lock.csv') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'runtime.csv') -Destination (Join-Path $EnvRoot 'runtime.lock.csv') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'cran-windows-4.4.csv') -Destination (Join-Path $EnvRoot 'cran.lock.csv') -Force
$manifest=@(
  [pscustomobject]@{component='R.dll';sha256=(Get-FileHash (Join-Path $runtime 'bin/x64/R.dll')).Hash.ToLower()},
  [pscustomobject]@{component='Rblas.dll';sha256=(Get-FileHash (Join-Path $runtime 'bin/x64/Rblas.dll')).Hash.ToLower()},
  [pscustomobject]@{component='OpenBLAS static input';sha256=$pins.openblas_archive_sha256}
)
$manifest | Export-Csv -LiteralPath (Join-Path $EnvRoot 'runtime-checksums.csv') -NoTypeInformation
Write-Output "GPCT environment build and smoke checks passed: $EnvRoot"
if ($Python) {
  $pythonVersion=& $Python -c 'import sys; print("%d.%d" % sys.version_info[:2])'
  if ($LASTEXITCODE -ne 0 -or $pythonVersion -ne '3.12') { throw 'Supply Python 3.12 for the pinned wheel set.' }
  $pythonRoot=Join-Path $EnvRoot 'python'
  if (!(Test-Path -LiteralPath (Join-Path $pythonRoot 'Scripts/python.exe'))) {
    Checked $Python @('-m','venv',$pythonRoot) $repo
  }
  $pythonExe=Join-Path $pythonRoot 'Scripts/python.exe'
  Checked $pythonExe @('-m','pip','--isolated','install','--require-hashes','-r',
    (Join-Path $PSScriptRoot 'requirements-windows-3.12.txt')) $repo
}
