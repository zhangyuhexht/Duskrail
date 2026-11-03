# Duskrail - render one frame and save a PNG (visual self-check)
# Requires an interactive desktop session with a working GPU driver.
# Examples:
#   tools\shot.ps1 -Name chase -Frames 120
#   tools\shot.ps1 -Name front34 -CamPos "18,9,18" -CamTarget "-622,20,-17"
# (CamPos / CamTarget are absolute world coordinates; omit for the in-game camera)

param(
    [string]$Name = "shot",
    [int]$Frames = 90,
    [string]$CamPos = "",
    [string]$CamTarget = "",
    [string]$CamMode = "",
    [string]$Time = "",
    [string[]]$Extra = @(),
    [switch]$Fullscreen
)

$ErrorActionPreference = "Stop"

$Root    = Split-Path -Parent $PSScriptRoot
$Godot   = Join-Path $Root "tools\godot\godot.exe"
$Project = Join-Path $Root "train-sim"
$OutDir  = Join-Path $Project "build\shots"
$Out     = Join-Path $OutDir "$Name.png"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if (Test-Path $Out) { Remove-Item $Out -Force }

$gameArgs = @("--shot=$Out", "--shot-frames=$Frames", "--mute")
if ($CamPos -ne "")    { $gameArgs += "--cam-pos=$CamPos" }
if ($CamTarget -ne "") { $gameArgs += "--cam-look=$CamTarget" }
if ($CamMode -ne "")   { $gameArgs += "--cam-mode=$CamMode" }
if ($Time -ne "")      { $gameArgs += "--time=$Time" }
if ($Fullscreen)       { $gameArgs += "--fullscreen" }
foreach ($e in $Extra) { $gameArgs += $e }

$godotArgs = @("--path", $Project, "--") + $gameArgs
Write-Host ("run: godot " + ($gameArgs -join " "))
# godot.exe is a GUI-subsystem program: piped output is what makes PowerShell wait.
# Godot warnings on stderr must not abort this script, so relax the policy here.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $Godot @godotArgs 2>&1 | ForEach-Object { $null = $_ }
$ErrorActionPreference = $prevEap
if (-not (Test-Path $Out)) { throw "screenshot failed: $Out" }
Write-Host ("shot: {0} ({1:N0} KB)" -f $Out, ((Get-Item $Out).Length / 1KB))
