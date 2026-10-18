# ==============================================================================
# FOKUSKONTEN - SKETCHUP & V-RAY RESTORE / UNBLOCKER
# ==============================================================================

Write-Host "Memulihkan koneksi jaringan SketchUp & V-Ray..." -ForegroundColor Yellow

# 1. Hapus Aturan Firewall
netsh advfirewall firewall delete rule name="FokusKonten_Block_SketchUp" | Out-Null
netsh advfirewall firewall delete rule name="FokusKonten_Block_ChaosLicense" | Out-Null

# 2. Bersihkan Hosts File
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$domains = @(
    "accounts.sketchup.com",
    "identity.trimble.com",
    "license.chaosgroup.com",
    "ols.chaosgroup.com",
    "licensing.chaosgroup.com",
    "analytics.sketchup.com"
)

$lines = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
$filtered = $lines | Where-Object {
    $line = $_
    $keep = $true
    foreach ($d in $domains) {
        if ($line -match [regex]::Escape($d)) { $keep = $false; break }
    }
    if ($line -match "# FokusKonten SketchUp & Chaos License Blocker") { $keep = $false }
    $keep
}
$filtered | Set-Content -Path $hostsPath -Encoding ASCII
Clear-DnsClientCache -ErrorAction SilentlyContinue

Write-Host "Pemulihan selesai. Aturan blokir telah dicabut." -ForegroundColor Green
