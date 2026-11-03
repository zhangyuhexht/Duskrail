# Duskrail - build script
# 1) import assets  2) export the Windows release exe  3) optional Inno Setup installer
# ASCII only: the Windows PowerShell 5.1 console is GBK, and UTF-8 comments can break parsing.

param(
    [switch]$NoImport,
    [switch]$Installer,
    [string]$Version = "alpha1.10",
    [switch]$Dlss
)

$ErrorActionPreference = "Stop"

$Root       = Split-Path -Parent $PSScriptRoot
$Project    = Join-Path $Root "train-sim"
$Logs       = Join-Path $Project "build\logs"
$OutDir     = Join-Path $Project "build\windows"
$Exe        = Join-Path $OutDir "Duskrail.exe"
$ForkBin    = Join-Path $Root "godot-rtx\bin"
$Streamline = Join-Path $Root "streamline-sdk\bin\x64"
$Rcedit     = Join-Path $PSScriptRoot "rcedit-x64.exe"
$Icon       = Join-Path $PSScriptRoot "installer\assets\Duskrail.ico"

if ($Dlss) {
    $Godot  = Join-Path $ForkBin "godot.windows.editor.x86_64.console.exe"
    $Preset = "Windows Desktop (DLSS)"
} else {
    $Godot  = Join-Path $Root "tools\godot\godot.exe"
    $Preset = "Windows Desktop"
}

if (-not (Test-Path $Godot)) { throw "Godot not found: $Godot" }
if ($Dlss -and -not (Test-Path $Streamline)) { throw "Streamline SDK not found: $Streamline" }
New-Item -ItemType Directory -Force -Path $Logs, $OutDir | Out-Null

# godot.exe is a GUI-subsystem program: piped output does not guarantee that
# PowerShell waits for it, so always use Start-Process -Wait for both steps.
function Invoke-Godot([string[]]$GodotArgs, [string]$Log) {
    $err = "$Log.err"
    $p = Start-Process -FilePath $Godot -ArgumentList $GodotArgs -NoNewWindow -Wait -PassThru `
         -RedirectStandardOutput $Log -RedirectStandardError $err
    return $p.ExitCode
}

$scriptCount = (Get-ChildItem (Join-Path $Project "src") -Recurse -Filter *.gd | Measure-Object).Count
Write-Host "src scripts: $scriptCount"

if (-not $NoImport) {
    Write-Host "== import assets =="
    $code = Invoke-Godot @("--headless", "--path", $Project, "--import") (Join-Path $Logs "import.log")
    if ($code -ne 0) { throw "import failed (exit $code) - see $Logs\import.log" }
    Start-Sleep -Milliseconds 800
}

Write-Host "== export windows release =="
Write-Host "   engine: $Godot"
Write-Host "   preset: $Preset"
$ExportLog = Join-Path $Logs "export.log"
$PresetArg = '"' + $Preset + '"'
$ok = $false
for ($attempt = 1; $attempt -le 3; $attempt++) {
    if (Test-Path $Exe) { Remove-Item $Exe -Force }
    $code = Invoke-Godot @("--headless", "--path", $Project, "--export-release", $PresetArg, $Exe) $ExportLog
    $hasExe = Test-Path $Exe
    $size = 0
    if ($hasExe) { $size = (Get-Item $Exe).Length }
    $done = ((Select-String -Path $ExportLog -Pattern 'DONE' -Encoding UTF8 | Measure-Object).Count -gt 0)
    $packed = (Select-String -Path $ExportLog -Pattern '\.gdc' -Encoding UTF8 | Measure-Object).Count
    # every src script must be packed, the log must finish, and the exe must be full size
    if ($hasExe -and $done -and $size -gt 50MB -and $packed -ge $scriptCount) { $ok = $true; break }
    Write-Host ("attempt {0}: exit={1} exe={2} size={3} done={4} scripts={5}/{6}" -f $attempt, $code, $hasExe, $size, $done, $packed, $scriptCount)
    Start-Sleep -Seconds 2
}
if (-not $ok) { throw "export failed - see $ExportLog" }

# The fork template cannot be patched by Godot's own resource editor without
# corrupting the PE. Use rcedit instead, then smoke-test the final binary.
if ($Dlss -and (Test-Path $Rcedit) -and (Test-Path $Icon)) {
    Write-Host "== brand executable =="
    $FileVersion = $Version
    if ($Version -match '^alpha(\d+)\.(\d+)$') {
        $FileVersion = "0.$($Matches[1]).$($Matches[2]).0"
    }
    if ($FileVersion -notmatch '^\d+(\.\d+){1,3}$') { $FileVersion = "0.1.0" }
    & $Rcedit $Exe --set-icon $Icon `
        --set-file-version $FileVersion --set-product-version $FileVersion `
        --set-version-string "FileDescription" "Duskrail" `
        --set-version-string "ProductName" "Duskrail" `
        --set-version-string "CompanyName" "Duskrail Studio" `
        --set-version-string "LegalCopyright" "Copyright (C) 2026 Duskrail Studio"
    if ($LASTEXITCODE -ne 0) { throw "rcedit failed (exit $LASTEXITCODE)" }
    Write-Host "branded exe with Duskrail icon and version info"
}

# Catch broken binary patching early: a corrupt PE fails before it can print a version.
$VerLog = Join-Path $Logs "version.log"
$VerErr = Join-Path $Logs "version.err"
Remove-Item $VerLog, $VerErr -ErrorAction SilentlyContinue
$vp = Start-Process -FilePath $Exe -ArgumentList @("--version") -NoNewWindow -Wait -PassThru `
      -RedirectStandardOutput $VerLog -RedirectStandardError $VerErr
$ver = @()
if (Test-Path $VerLog) { $ver += Get-Content $VerLog }
if (Test-Path $VerErr) { $ver += Get-Content $VerErr }
if ($vp.ExitCode -ne 0 -or -not (($ver -join "`n") -match '4\.')) {
    throw "exported exe smoke test failed (exit $($vp.ExitCode)) - see $VerLog"
}

Write-Host ("OK: {0} ({1:N1} MB, {2} scripts packed)" -f $Exe, ($size / 1MB), $packed)

if ($Dlss) {
    Write-Host "== package Streamline runtime =="
    $required = @("sl.interposer.dll", "sl.common.dll", "sl.dlss.dll", "nvngx_dlss.dll")
    foreach ($name in $required) {
        if (-not (Test-Path (Join-Path $Streamline $name))) {
            throw "missing Streamline file: $name"
        }
    }
    Copy-Item (Join-Path $Streamline "*.dll") $OutDir -Force
    Copy-Item (Join-Path $Streamline "*.txt") $OutDir -Force
    $ThirdParty = Join-Path $Root "streamline-sdk\3rd-party-licenses.md"
    if (Test-Path $ThirdParty) { Copy-Item $ThirdParty $OutDir -Force }
    $ConsoleSrc = Join-Path $ForkBin "godot.windows.template_release.x86_64.console.exe"
    if (Test-Path $ConsoleSrc) {
        Copy-Item $ConsoleSrc (Join-Path $OutDir "Duskrail.console.exe") -Force
    }
    Write-Host "packaged Streamline runtime and licenses"
}

# attach the player readme
$Readme = Join-Path $Project "docs\README-zh.txt"
if (Test-Path $Readme) {
    Copy-Item $Readme (Join-Path $OutDir "README.txt") -Force
    Write-Host "copied README.txt"
}

Get-ChildItem $OutDir | Select-Object Name, Length

if ($Installer) {
    Write-Host "== build installer =="
    & (Join-Path $PSScriptRoot "install.ps1") -Version $Version
    $Setup = Join-Path $Root "dist\Duskrail-Setup-$Version.exe"
    if (-not (Test-Path $Setup)) { throw "installer not produced: $Setup" }
    Write-Host ("OK: {0} ({1:N1} MB)" -f $Setup, ((Get-Item $Setup).Length / 1MB))
    # portable zip (full game folder: exe, pck, console wrapper, DLLs, licenses, readme)
    $Zip = Join-Path $Root "dist\Duskrail-$Version-portable-win64.zip"
    $Stage = Join-Path $Logs "portable-stage"
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Stage | Out-Null
    Copy-Item (Join-Path $OutDir "*") $Stage -Recurse -Force
    if (Test-Path $Readme) { Copy-Item $Readme (Join-Path $Stage "README.txt") -Force }
    if (Test-Path $Zip) { Remove-Item $Zip -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($Stage, $Zip, [IO.Compression.CompressionLevel]::Optimal, $false)
    Remove-Item $Stage -Recurse -Force
    if (Test-Path $Zip) { Write-Host ("OK: {0} ({1:N1} MB)" -f $Zip, ((Get-Item $Zip).Length / 1MB)) }
}
