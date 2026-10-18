# ==============================================================================
# FOKUSKONTEN UTILITY â€” DRIVER RESTORE ENGINE (PNPUTIL NATIVE)
# Pasang kembali seluruh driver cadangan 1-klik tanpa internet
# ==============================================================================
#Requires -RunAsAdministrator

param(
    [string]$Source = "D:\BackupDriver"
)

if (-not (Test-Path $Source)) {
    Write-Host "Folder cadangan $Source tidak ditemukan!" -ForegroundColor Red
    exit 1
}

Write-Host "Memasang kembali seluruh driver perangkat keras..." -ForegroundColor Cyan
& pnputil.exe /add-driver "$Source\*.inf" /subdirs /install
Write-Host "Seluruh driver berhasil dipulihkan tanpa butuh internet!" -ForegroundColor Green
