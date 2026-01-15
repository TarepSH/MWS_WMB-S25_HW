$ErrorActionPreference = "Stop"

$backendDir = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $backendDir ".backend.pid"

if (!(Test-Path $pidFile)) {
  Write-Host "No PID file found ($pidFile). Backend may not be running."
  exit 0
}

$pidText = Get-Content $pidFile | Select-Object -First 1
Remove-Item $pidFile -Force -ErrorAction SilentlyContinue

if (!($pidText -match '^\d+$')) {
  Write-Host "Invalid PID file contents."
  exit 1
}

$pid = [int]$pidText
$p = Get-Process -Id $pid -ErrorAction SilentlyContinue
if ($null -eq $p) {
  Write-Host "Backend process PID=$pid is not running."
  exit 0
}

Stop-Process -Id $pid -Force
Write-Host "Stopped backend (PID=$pid)"