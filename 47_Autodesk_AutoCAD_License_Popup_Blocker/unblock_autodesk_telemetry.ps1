# ==============================================================================
# FOKUSKONTEN - AUTODESK RESTORE / UNBLOCKER
# Mengembalikan pengaturan jaringan Autodesk ke kondisi semula
# ==============================================================================

Write-Host "Memulihkan aturan jaringan Autodesk..." -ForegroundColor Yellow

# 1. Hapus Aturan Firewall
$rules = @("FokusKonten_Block_AutoCAD_Exe", "FokusKonten_Block_AdskLicensingAgent", "FokusKonten_Block_AdskLicensingAgent64", "FokusKonten_Block_AGS")
foreach ($r in $rules) {
    netsh advfirewall firewall delete rule name="$r" | Out-Null
}

# 2. Bersihkan Hosts File
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$domains = @(
    "genuine-software.autodesk.com",
    "genuine-software1.autodesk.com",
    "genuine-software2.autodesk.com",
    "clm.autodesk.com",
    "cur.autodesk.com",
    "ipm-provider.autodesk.com",
    "ase-cdn-stg.autodesk.com",
    "developer.api.autodesk.com"
)

$lines = Get-Content -Path $hostsPath -ErrorAction SilentlyContinue
$filtered = $lines | Where-Object {
    $line = $_
    $keep = $true
    foreach ($d in $domains) {
        if ($line -match [regex]::Escape($d)) { $keep = $false; break }
    }
    if ($line -match "# FokusKonten Autodesk License Blocker") { $keep = $false }
    $keep
}
$filtered | Set-Content -Path $hostsPath -Encoding ASCII
Clear-DnsClientCache -ErrorAction SilentlyContinue

Write-Host "Pemulihan selesai. Aturan blokir telah dicabut." -ForegroundColor Green
