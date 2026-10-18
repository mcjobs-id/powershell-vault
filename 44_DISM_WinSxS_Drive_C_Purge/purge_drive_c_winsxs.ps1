# ==============================================================================
# FOKUSKONTEN UTILITY â€” DEEP DRIVE C & WINSXS PURGER
# Membebaskan ruang SSD 10GB-30GB dari sisa update dan cache terkunci
# ==============================================================================
#Requires -RunAsAdministrator

Write-Host "Memulai Pembersihan Mendalam Windows Component Store (WinSxS)..." -ForegroundColor Cyan
& Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase

Write-Host "Membersihkan cache Windows Update SoftwareDistribution..." -ForegroundColor Cyan
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

Write-Host "Membersihkan seluruh file temporary sistem..." -ForegroundColor Cyan
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Selesai! Ruang kosong Drive C berhasil dipulihkan secara maksimal." -ForegroundColor Green
