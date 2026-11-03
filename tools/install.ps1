# Duskrail - modern Inno Setup installer build script
# Usage: powershell -File tools\install.ps1 [-Version 0.1.0]
# ASCII only: Windows PowerShell 5.1 console is GBK.

param(
    [string]$Version = "alpha1.8",
    [string]$NumericVersion = ""
)

$ErrorActionPreference = "Stop"

if ($NumericVersion -eq "") {
    if ($Version -match '^alpha(\d+)\.(\d+)$') {
        $NumericVersion = "0.$($Matches[1]).$($Matches[2]).0"
    } else {
        $NumericVersion = "0.1.0.0"
    }
}

$Root  = Split-Path -Parent $PSScriptRoot
$Iscc  = Join-Path $PSScriptRoot "innosetup6\ISCC.exe"
if (-not (Test-Path $Iscc)) {
    $Iscc = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"
}
if (-not (Test-Path $Iscc)) {
    $Iscc = Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe"
}
$Iss   = Join-Path $PSScriptRoot "installer\Duskrail.iss"
$Src   = Join-Path $Root "train-sim\build\windows"
$Dist  = Join-Path $Root "dist"
$Logs  = Join-Path $Root "train-sim\build\logs"
$Out   = Join-Path $Dist "Duskrail-Setup-$Version.exe"
$Stable = Join-Path $Dist "Duskrail-Setup.exe"

if (-not (Test-Path $Iscc))  { throw "Inno Setup compiler not found: $Iscc" }
if (-not (Test-Path $Iss))   { throw "installer script not found: $Iss" }
if (-not (Test-Path (Join-Path $Src "Duskrail.exe"))) {
    throw "game exe not found in $Src - run tools\build.ps1 first"
}

New-Item -ItemType Directory -Force -Path $Dist, $Logs | Out-Null
if (Test-Path $Out) { Remove-Item $Out -Force }

$Log = Join-Path $Logs "installer.log"
$Err = Join-Path $Logs "installer.err"
Remove-Item $Log, $Err -ErrorAction SilentlyContinue

Write-Host "== build modern installer =="
Write-Host "   iscc : $Iscc"
Write-Host "   src  : $Src"
Write-Host "   out  : $Out"
$proc = Start-Process -FilePath $Iscc -ArgumentList @("/DAppVersion=$Version", "/DAppVersionNumeric=$NumericVersion", $Iss) `
    -NoNewWindow -Wait -PassThru -RedirectStandardOutput $Log -RedirectStandardError $Err
if ($proc.ExitCode -ne 0) {
    Get-Content $Log -Tail 30 -ErrorAction SilentlyContinue
    Get-Content $Err -Tail 30 -ErrorAction SilentlyContinue
    throw "ISCC failed (exit $($proc.ExitCode)) - see $Log"
}
if (-not (Test-Path $Out)) {
    throw "installer not produced: $Out - see $Log"
}

# Keep the friendly unversioned name used by the release page.
Copy-Item $Out $Stable -Force

$size = (Get-Item $Out).Length / 1MB
Write-Host ("OK: {0} ({1:N1} MB)" -f $Out, $size)
Write-Host ("OK: {0}" -f $Stable)
