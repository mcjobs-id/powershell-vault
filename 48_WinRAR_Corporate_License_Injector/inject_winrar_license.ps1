# ==============================================================================
# FOKUSKONTEN - WINRAR LIFETIME CORPORATE LICENSE INJECTOR
# Aktivasi WinRAR Permanen Tanpa Pop-up Evaluasi 40 Hari Tanpa Crack Biner
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " FOKUSKONTEN - WINRAR PERMANENT CORPORATE LICENSE INJECTOR       " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceKey = Join-Path $scriptDir "rarreg.key"

if (-not (Test-Path $sourceKey)) {
    Write-Host "[ERROR] Berkas lisensi rarreg.key tidak ditemukan di direktori skrip!" -ForegroundColor Red
    exit 1
}

$targetPaths = @(
    "$env:ProgramFiles\WinRAR",
    "${env:ProgramFiles(x86)}\WinRAR",
    "$env:APPDATA\WinRAR"
)

$injectedCount = 0

foreach ($p in $targetPaths) {
    if (Test-Path $p) {
        $destFile = Join-Path $p "rarreg.key"
        Copy-Item -Path $sourceKey -Destination $destFile -Force
        Write-Host "   -> Lisensi berhasil disuntikkan ke: $destFile" -ForegroundColor Green
        $injectedCount++
    }
}

if ($injectedCount -eq 0) {
    # Buat direktori di AppData jika WinRAR portabel
    $appDataWinrar = "$env:APPDATA\WinRAR"
    New-Item -ItemType Directory -Force -Path $appDataWinrar | Out-Null
    Copy-Item -Path $sourceKey -Destination (Join-Path $appDataWinrar "rarreg.key") -Force
    Write-Host "   -> WinRAR instalasi standar tidak ditemukan. Lisensi disimpan di profil AppData pengguna: $appDataWinrar\rarreg.key" -ForegroundColor Yellow
    $injectedCount++
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " SUKSES: WinRAR Anda kini berstatus Unlimited Company License!" -ForegroundColor Green
Write-Host " Seluruh kotak dialog evaluasi 40 hari telah dinonaktifkan selamanya." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
