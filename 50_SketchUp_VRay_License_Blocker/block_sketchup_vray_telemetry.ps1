# ==============================================================================
# FOKUSKONTEN - SKETCHUP & V-RAY / ENSCAPE LICENSE TELEMETRY BLOCKER
# Solusi Lisensi Kadaluarsa, Pop-Up Langganan Habis, & Chaos License Offline
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " FOKUSKONTEN - SKETCHUP & V-RAY LICENSE TELEMETRY BLOCKER        " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Hentikan Proses Terkait
Write-Host "[1/4] Menghentikan proses SketchUp dan Chaos License Server..." -ForegroundColor Green
$processes = @("SketchUp", "vrol", "chaos_license_server", "ChaosCosmos")
foreach ($pr in $processes) {
    Get-Process -Name $pr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# 2. Firewall Outbound Isolation
Write-Host "[2/4] Mendaftarkan aturan isolasi outbound di Windows Defender Firewall..." -ForegroundColor Green
$rules = @(
    @{ Name = "FokusKonten_Block_SketchUp"; Path = "C:\Program Files\SketchUp\SketchUp *\SketchUp.exe" },
    @{ Name = "FokusKonten_Block_ChaosLicense"; Path = "C:\Program Files\Chaos*\Chaos*\vrol.exe" }
)

foreach ($r in $rules) {
    netsh advfirewall firewall delete rule name="$($r.Name)" | Out-Null
    $resolved = Resolve-Path -Path $r.Path -ErrorAction SilentlyContinue
    if ($resolved) {
        foreach ($item in $resolved) {
            netsh advfirewall firewall add rule name="$($r.Name)" dir=out action=block program="$($item.Path)" enable=yes | Out-Null
            Write-Host "   -> Terblokir Firewall: $($item.Path)" -ForegroundColor Gray
        }
    }
}

# 3. Null-Routing Domain Validasi Trimble & Chaos Group ke 0.0.0.0
Write-Host "[3/4] Memetakan domain telemetri ke 0.0.0.0 di berkas hosts..." -ForegroundColor Green
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$domains = @(
    "accounts.sketchup.com",
    "identity.trimble.com",
    "license.chaosgroup.com",
    "ols.chaosgroup.com",
    "licensing.chaosgroup.com",
    "analytics.sketchup.com"
)

$hostsContent = Get-Content -Path $hostsPath -Raw -ErrorAction SilentlyContinue
$newEntries = @()
foreach ($dom in $domains) {
    if ($hostsContent -notmatch [regex]::Escape($dom)) {
        $newEntries += "0.0.0.0 $dom"
    }
}

if ($newEntries.Count -gt 0) {
    Add-Content -Path $hostsPath -Value "`r`n# FokusKonten SketchUp & Chaos License Blocker`r`n$($newEntries -join "`r`n")"
    Write-Host "   -> $($newEntries.Count) domain telemetri berhasil diisolasi ke 0.0.0.0" -ForegroundColor Gray
}

# 4. Flush DNS Resolver
Clear-DnsClientCache -ErrorAction SilentlyContinue

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " SUKSES: Pop-up lisensi SketchUp & V-Ray berhasil diblokir!" -ForegroundColor Green
Write-Host " Anda dapat merender dan mendesain tanpa terganggu pemutusan lisensi." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
