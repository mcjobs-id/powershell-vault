# ==============================================================================
# FOKUSKONTEN UTILITY â€” MASS FONT INSTALLER ENGINE
# Memasang ribuan font desain grafis 1-klik tanpa membuka pratinjau
# ==============================================================================
#Requires -RunAsAdministrator

param(
    [string]$FontDirectory = "D:\KoleksiFont"
)

if (-not (Test-Path $FontDirectory)) {
    Write-Host "Direktori font $FontDirectory tidak ditemukan!" -ForegroundColor Red
    exit 1
}

$fonts = Get-ChildItem -Path $FontDirectory -Include *.ttf, *.otf, *.fon -Recurse
Write-Host "Ditemukan $($fonts.Count) file font. Memulai instalasi massal..." -ForegroundColor Cyan

$fontsFolder = "C:\Windows\Fonts"
$fontRegistry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

$installed = 0
foreach ($font in $fonts) {
    $targetPath = Join-Path $fontsFolder $font.Name
    if (-not (Test-Path $targetPath)) {
        Copy-Item -Path $font.FullName -Destination $targetPath -Force
    }
    
    $regName = $font.BaseName
    if ($font.Extension -eq ".ttf") { $regName += " (TrueType)" }
    elseif ($font.Extension -eq ".otf") { $regName += " (OpenType)" }
    
    New-ItemProperty -Path $fontRegistry -Name $regName -Value $font.Name -PropertyType String -Force | Out-Null
    $installed++
}

Write-Host "Berhasil memasang $installed font ke sistem Windows tanpa macet!" -ForegroundColor Green
