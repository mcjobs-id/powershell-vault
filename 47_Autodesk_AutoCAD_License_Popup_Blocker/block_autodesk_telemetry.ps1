# ==============================================================================
# FOKUSKONTEN - AUTODESK & AUTOCAD LICENSE POP-UP BLOCKER
# Solusi Permanen Pop-Up: "Your AutoCAD license is not valid. Access will be blocked."
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " FOKUSKONTEN - AUTODESK & AUTOCAD LICENSE TELEMETRY BLOCKER       " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Hentikan Seluruh Daemon Lisensi Autodesk yang Sedang Berjalan
Write-Host "[1/4] Menghentikan daemon latar belakang Autodesk..." -ForegroundColor Green
$daemons = @("AdskLicensingService", "AdskLicensingAgent", "AutodeskGenuineService", "AGS")
foreach ($d in $daemons) {
    Get-Process -Name $d -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# 2. Nonaktifkan Service Autodesk Genuine Service jika Terdaftar
Write-Host "[2/4] Mengisolasi layanan Autodesk Genuine Service..." -ForegroundColor Green
$services = @("AdskLicensingService", "AGSService")
foreach ($s in $services) {
    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
    }
}

# 3. Konfigurasi Firewall Windows Defender Outbound Block
Write-Host "[3/4] Mendaftarkan aturan blokir outbound di Windows Defender Firewall..." -ForegroundColor Green
$firewallRules = @(
    @{ Name = "FokusKonten_Block_AutoCAD_Exe"; Path = "C:\Program Files\Autodesk\AutoCAD*\acad.exe" },
    @{ Name = "FokusKonten_Block_AdskLicensingAgent"; Path = "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\*\AdskLicensingAgent\AdskLicensingAgent.exe" },
    @{ Name = "FokusKonten_Block_AdskLicensingAgent64"; Path = "C:\Program Files\Common Files\Autodesk Shared\AdskLicensing\*\AdskLicensingAgent\AdskLicensingAgent.exe" },
    @{ Name = "FokusKonten_Block_AGS"; Path = "C:\Program Files\Autodesk\Autodesk Genuine Service\AGS.exe" }
)

foreach ($r in $firewallRules) {
    # Hapus aturan lama jika ada
    netsh advfirewall firewall delete rule name="$($r.Name)" | Out-Null
    
    # Cari path file yang cocok secara dinamis
    $resolvedPaths = Resolve-Path -Path $r.Path -ErrorAction SilentlyContinue
    if ($resolvedPaths) {
        foreach ($p in $resolvedPaths) {
            netsh advfirewall firewall add rule name="$($r.Name)" dir=out action=block program="$($p.Path)" enable=yes | Out-Null
            Write-Host "   -> Terblokir Firewall: $($p.Path)" -ForegroundColor Gray
        }
    }
}

# 4. Null-Routing Domain Validasi Lisensi Autodesk ke 0.0.0.0
Write-Host "[4/4] Memetakan domain telemetri Autodesk ke 0.0.0.0 di hosts file..." -ForegroundColor Green
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

$hostsContent = Get-Content -Path $hostsPath -Raw -ErrorAction SilentlyContinue
$newEntries = @()
foreach ($dom in $domains) {
    if ($hostsContent -notmatch [regex]::Escape($dom)) {
        $newEntries += "0.0.0.0 $dom"
    }
}

if ($newEntries.Count -gt 0) {
    Add-Content -Path $hostsPath -Value "`r`n# FokusKonten Autodesk License Blocker`r`n$($newEntries -join "`r`n")"
    Write-Host "   -> $($newEntries.Count) domain telemetri berhasil diisolasi ke 0.0.0.0" -ForegroundColor Gray
} else {
    Write-Host "   -> Seluruh domain sudah terdaftar di hosts file." -ForegroundColor Gray
}

# Flush DNS Resolver Cache
Clear-DnsClientCache -ErrorAction SilentlyContinue

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " SUKSES: Pop-up lisensi palsu Autodesk AutoCAD berhasil diblokir!" -ForegroundColor Green
Write-Host " AutoCAD Anda kini dapat digunakan tanpa gangguan jendela penutup." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
