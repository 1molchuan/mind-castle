# One-line installer for the brain-wave games (Windows 10/11). Run in PowerShell:
#   irm https://raw.githubusercontent.com/1molchuan/mind-castle/main/install.ps1 | iex
# or in cmd:
#   curl -fsSLo %TEMP%\mc.ps1 https://raw.githubusercontent.com/1molchuan/mind-castle/main/install.ps1 && powershell -ExecutionPolicy Bypass -File %TEMP%\mc.ps1
#
# It downloads the latest version into %LOCALAPPDATA%\MindCastle, puts a shortcut on the desktop and starts the game.
# Running it again updates the game. This file is kept ASCII-only so it works with both irm|iex and -File.
# Environment overrides: MC_REPO (owner/name), MC_BRANCH, MC_ZIP (a zip URL or local path, e.g. a mirror),
# MC_NOSTART=1 (install and create the shortcut only, e.g. when setting up a whole computer lab).
$ErrorActionPreference = 'Stop'
$repo = if ($env:MC_REPO) { $env:MC_REPO } else { '1molchuan/mind-castle' }
$branch = if ($env:MC_BRANCH) { $env:MC_BRANCH } else { 'main' }
$zip = if ($env:MC_ZIP) { $env:MC_ZIP } else { "https://github.com/$repo/archive/refs/heads/$branch.zip" }
$dir = Join-Path $env:LOCALAPPDATA 'MindCastle'
$tmpZip = Join-Path $env:TEMP "mind-castle-$PID.zip"
$tmpDir = Join-Path $env:TEMP "mind-castle-$PID"

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Write-Host "Downloading $zip"
if (Test-Path $zip) { Copy-Item $zip $tmpZip }
else {
  $ProgressPreference = 'SilentlyContinue'  # the progress bar makes Invoke-WebRequest very slow on Windows PowerShell 5.1
  Invoke-WebRequest $zip -OutFile $tmpZip -UseBasicParsing
}

Write-Host "Installing to $dir"
Expand-Archive $tmpZip $tmpDir -Force
# GitHub zips contain one top folder (repo-branch); a zip made by hand may not
$top = Get-ChildItem $tmpDir
$src = if ($top.Count -eq 1 -and $top[0].PSIsContainer) { $top[0].FullName } else { $tmpDir }
if (-not (Test-Path (Join-Path $src 'serve.ps1'))) { throw "serve.ps1 not found in $zip" }
if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
New-Item -ItemType Directory -Force (Split-Path $dir) | Out-Null
Move-Item $src $dir
Remove-Item $tmpZip, $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

$serve = Join-Path $dir 'serve.ps1'
& powershell -NoProfile -ExecutionPolicy Bypass -File $serve -Shortcut
if ($env:MC_NOSTART) { Write-Host "Done. Start the game with the desktop shortcut."; return }
Start-Process powershell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$serve`"" -WorkingDirectory $env:USERPROFILE
Write-Host 'Done. The game window will open in a moment; next time use the desktop shortcut.'
