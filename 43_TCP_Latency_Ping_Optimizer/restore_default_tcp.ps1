# ==============================================================================
# FOKUSKONTEN UTILITY â€” RESTORE DEFAULT TCP SETTINGS
# ==============================================================================
#Requires -RunAsAdministrator
$tcpInterfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem -Path $tcpInterfaces | ForEach-Object {
    Remove-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "Pengaturan TCP Windows dikembalikan ke standar." -ForegroundColor Green
