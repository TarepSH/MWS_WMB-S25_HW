$ErrorActionPreference = "Stop"

$backendDir = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $backendDir ".backend.pid"
$outLog = Join-Path $backendDir "server.out.log"
$errLog = Join-Path $backendDir "server.err.log"

if (Test-Path $pidFile) {
  try {
    $existingPid = Get-Content $pidFile -ErrorAction Stop | Select-Object -First 1
    if ($existingPid -match '^\d+$') {
      $p = Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue
      if ($null -ne $p) {
        Write-Host "Backend already running (PID=$existingPid)."
        exit 0
      }
    }
  } catch {
    # ignore
  }
  Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

if (Test-Path $outLog) { Remove-Item $outLog -Force }
if (Test-Path $errLog) { Remove-Item $errLog -Force }

$p = Start-Process -FilePath node -ArgumentList "src/index.js" -WorkingDirectory $backendDir -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
$p.Id | Out-File -FilePath $pidFile -Encoding ascii

Write-Host "Started backend (PID=$($p.Id))"
Write-Host "Logs: $outLog"
Write-Host "Errors: $errLog"