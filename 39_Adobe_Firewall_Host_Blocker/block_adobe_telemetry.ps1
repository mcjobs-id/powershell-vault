# ==============================================================================
# FOKUSKONTEN UTILITY â€” ADOBE TELEMETRY & GENUINE SERVICE BLOCKER
# Menghilangkan notifikasi 'This unlicensed Adobe app will be disabled soon'
# ==============================================================================
#Requires -RunAsAdministrator

Write-Host "Menghentikan layanan Adobe Genuine Software Service..." -ForegroundColor Cyan
Get-Service -Name "AGSService", "AdobeUpdateService", "CCXProcess" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Set-Service -Name "AGSService" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "Menambahkan aturan Windows Defender Firewall..." -ForegroundColor Cyan
$adobeApps = @(
    "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Service\Adobe Desktop Service.exe",
    "C:\Program Files (x86)\Common Files\Adobe\Adobe Genuine Software Integrity Service\AGSService.exe",
    "C:\Program Files\Common Files\Adobe\Adobe Desktop Service\Adobe Desktop Service.exe"
)

foreach ($app in $adobeApps) {
    if (Test-Path $app) {
        $name = "Block_" + (Split-Path $app -Leaf)
        netsh advfirewall firewall delete rule name="$name" | Out-Null
        netsh advfirewall firewall add rule name="$name" dir=out action=block program="$app" enable=yes | Out-Null
        Write-Host "Blokir firewall aktif: $app" -ForegroundColor Green
    }
}

Write-Host "Menyuntikkan pemetaan host null (0.0.0.0)..." -ForegroundColor Cyan
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$domains = @(
    "lmlicenses.wip4.adobe.com",
    "lm.licenses.adobe.com",
    "na1r.services.adobe.com",
    "hlrcv.stage.adobe.com",
    "genuine.adobe.com",
    "prod.adobegenuine.com",
    "ic.adobe.io",
    "cc-api-data.adobe.io"
)

$hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
$appendContent = ""
foreach ($domain in $domains) {
    if ($hostsContent -notmatch [regex]::Escape($domain)) {
        $appendContent += "`r`n0.0.0.0 $domain"
    }
}

if ($appendContent -ne "") {
    Add-Content -Path $hostsPath -Value $appendContent
    Write-Host "Domain validasi Adobe berhasil dinonaktifkan." -ForegroundColor Green
}

Write-Host "Selesai! Pop-up lisensi Adobe telah dinonaktifkan permanen." -ForegroundColor Yellow
