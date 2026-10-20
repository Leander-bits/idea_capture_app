param([switch]$SkipBuild, [string]$Flutter = 'C:\Temp\idea_capture_flutter_sdk\bin\flutter.bat')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot '.local\https\config.json'
if (-not (Test-Path -LiteralPath $configPath)) { throw 'Run tools/setup-lan-https.ps1 first in an administrator PowerShell.' }
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if (-not (Get-NetIPAddress -AddressFamily IPv4 -IPAddress $config.address -ErrorAction SilentlyContinue)) {
    throw 'Wi-Fi address changed. Run setup-lan-https.ps1 again to update the certificate and firewall.'
}
foreach ($port in 8000,11434) {
    $listeners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
    if ($listeners.Count -eq 0) { throw "Start the existing local service on port $port first." }
    if ($listeners | Where-Object {$_.LocalAddress -notin '127.0.0.1','::1'}) {
        throw "Port $port must remain loopback-only. Do not expose backend or Ollama to Wi-Fi."
    }
}
Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 5 | Out-Null
if (-not $SkipBuild) {
    Push-Location (Join-Path $repoRoot 'app')
    try {
        & $Flutter build web --release --no-web-resources-cdn --dart-define=TRANSCRIPTION_BASE_URL=same-origin
        if ($LASTEXITCODE -ne 0) { throw 'Flutter Web build failed.' }
    } finally { Pop-Location }
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'app\build\web\index.html'))) { throw 'No Web build. Run without -SkipBuild.' }
& (Join-Path $repoRoot 'backend\.venv\Scripts\python.exe') (Join-Path $PSScriptRoot 'lan_gateway.py') --config $configPath
