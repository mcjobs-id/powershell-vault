# ==============================================================================
# FOKUSKONTEN UTILITY â€” CORELDRAW ANTI BLOKIR AKUN & POP-UP ILEGAL
# Mengembalikan fungsi Save, Export, Print yang terkunci
# ==============================================================================
#Requires -RunAsAdministrator

Write-Host "Mematikan layanan Corel License Validation Service..." -ForegroundColor Cyan
Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "Menambahkan aturan blokir Firewall untuk CorelDraw..." -ForegroundColor Cyan
$corelPaths = @(
    "C:\Program Files\Corel\*\Programs64\CorelDRW.exe",
    "C:\Program Files\Corel\*\Programs64\Cap.exe",
    "C:\Program Files\Corel\*\Programs64\CorelPP.exe"
)

Get-ChildItem -Path $corelPaths -ErrorAction SilentlyContinue | ForEach-Object {
    $exe = $_.FullName
    $ruleName = "Block_Corel_" + $_.Name
    netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
    netsh advfirewall firewall add rule name="$ruleName" dir=out action=block program="$exe" enable=yes | Out-Null
    Write-Host "Blokir aktif: $exe" -ForegroundColor Green
}

Write-Host "Menyuntikkan pemetaan host null Corel..." -ForegroundColor Cyan
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$corelDomains = @(
    "mc.corel.com",
    "apps.corel.com",
    "origin-mc.corel.com",
    "iws.corel.com",
    "corel.com"
)

$hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
$append = ""
foreach ($d in $corelDomains) {
    if ($hostsContent -notmatch [regex]::Escape($d)) {
        $append += "`r`n0.0.0.0 $d"
    }
}
if ($append -ne "") {
    Add-Content -Path $hostsPath -Value $append
    Write-Host "Domain pelacak Corel berhasil dinonaktifkan." -ForegroundColor Green
}

Write-Host "Selesai! CorelDraw kini bebas blokir dan fitur simpan aktif normal." -ForegroundColor Yellow
