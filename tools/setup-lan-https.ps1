param([string]$LanAddress)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$stateDir = Join-Path $repoRoot '.local\https'
$python = Join-Path $repoRoot 'backend\.venv\Scripts\python.exe'
if (-not $LanAddress) {
    $wifi = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -match 'WLAN|Wi-Fi|Wireless|无线' -and $_.IPAddress -notlike '169.254*'
    })
    if ($wifi.Count -ne 1) { throw 'Specify -LanAddress with the computer Wi-Fi IPv4 address.' }
    $LanAddress = $wifi[0].IPAddress
}
$interface = Get-NetIPAddress -AddressFamily IPv4 -IPAddress $LanAddress
if (-not $interface) { throw 'The requested address is not assigned to this computer.' }
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$subnet = & $python -c "import ipaddress,sys; address=ipaddress.ip_address(sys.argv[1]); assert address.is_private and not address.is_loopback and not address.is_unspecified; print(ipaddress.ip_network(sys.argv[1]+'/'+sys.argv[2],strict=False))" $LanAddress $interface.PrefixLength
if ($LASTEXITCODE -ne 0) { throw 'Use a private Wi-Fi IPv4 address.' }
$mkcert = Join-Path $stateDir 'mkcert.exe'
if (-not (Test-Path -LiteralPath $mkcert)) {
    # Official pinned portable binary; no PATH or package manager changes.
    Invoke-WebRequest 'https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe' -OutFile $mkcert
}
$previousCaRoot = $env:CAROOT
try {
    $env:CAROOT = Join-Path $stateDir 'ca'
    # Issue with an isolated local CA; iPhone trust is installed manually.
    # No Windows root-store confirmation dialog is needed for serving HTTPS.
    & $mkcert -cert-file (Join-Path $stateDir 'server.pem') -key-file (Join-Path $stateDir 'server-key.pem') $LanAddress localhost 127.0.0.1
    if ($LASTEXITCODE -ne 0) { throw 'Could not issue the LAN server certificate.' }
    & $python -c "import pathlib,ssl,sys; d=pathlib.Path(sys.argv[1]); (d/'rootCA.cer').write_bytes(ssl.PEM_cert_to_DER_cert((d/'ca'/'rootCA.pem').read_text()))" $stateDir
    if ($LASTEXITCODE -ne 0) { throw 'Could not export the public CA certificate.' }
} finally {
    $env:CAROOT = $previousCaRoot
}
$ruleName = 'IdeaCapture-LAN-HTTPS'
$existing = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($existing) { Remove-NetFirewallRule -Name $ruleName }
# The current Wi-Fi profile may be Public: keep it, scope the rule to this interface/subnet.
New-NetFirewallRule -Name $ruleName -DisplayName 'Idea Capture Wi-Fi HTTPS preview' -Direction Inbound -Action Allow -Profile Any -Protocol TCP -LocalAddress $LanAddress -LocalPort 8443,8081 -RemoteAddress $subnet -InterfaceAlias $interface.InterfaceAlias | Out-Null
@{address=$LanAddress; subnet=$subnet; https_port=8443; certificate_port=8081} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stateDir 'config.json') -Encoding UTF8
Write-Host "Configured HTTPS: https://${LanAddress}:8443/"
Write-Host "Public iPhone certificate: http://${LanAddress}:8081/rootCA.cer"
Write-Host 'The CA/server private keys remain inside .local/https and are never served.'
