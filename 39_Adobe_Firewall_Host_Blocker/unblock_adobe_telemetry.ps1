# ==============================================================================
# FOKUSKONTEN UTILITY â€” RESTORE ADOBE TELEMETRY SETTINGS
# ==============================================================================
#Requires -RunAsAdministrator
netsh advfirewall firewall delete rule name="Block_Adobe Desktop Service.exe" | Out-Null
netsh advfirewall firewall delete rule name="Block_AGSService.exe" | Out-Null
Write-Host "Aturan firewall Adobe dibersihkan." -ForegroundColor Green
