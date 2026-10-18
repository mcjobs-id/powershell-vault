# ==============================================================================
# FOKUSKONTEN UTILITY â€” DRIVER BACKUP ENGINE (NATIVE DISM)
# Cadangkan seluruh driver perangkat keras pihak ketiga dalam 30 detik
# ==============================================================================
#Requires -RunAsAdministrator

param(
    [string]$Destination = "D:\BackupDriver"
)

Write-Host "Memulai pencadangan driver Windows aktif..." -ForegroundColor Cyan
if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$drivers = Export-WindowsDriver -Online -Destination $Destination
Write-Host "Berhasil mencadangkan $($drivers.Count) driver pihak ketiga ke $Destination!" -ForegroundColor Green
