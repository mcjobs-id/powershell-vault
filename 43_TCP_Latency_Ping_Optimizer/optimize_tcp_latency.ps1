# ==============================================================================
# FOKUSKONTEN UTILITY â€” TCP STACK & PING OPTIMIZER
# Meminimalkan latency, jitter, dan packet delay untuk game online
# ==============================================================================
#Requires -RunAsAdministrator

Write-Host "Mengoptimalkan Stack TCP/IP Windows untuk Latensi Rendah..." -ForegroundColor Cyan

# 1. Atur Global TCP
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set global rsc=disabled | Out-Null
netsh int tcp set global timestamps=disabled | Out-Null

# 2. Modifikasi Registri Nagle's Algorithm di Seluruh Interface Aktif
$tcpInterfaces = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem -Path $tcpInterfaces | ForEach-Object {
    $guid = $_.PSChildName
    New-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks" -Value 0 -PropertyType DWord -Force | Out-Null
}

# 3. Optimasi Multimedia System Profile (Non-Throttling)
$sysProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
New-ItemProperty -Path $sysProfile -Name "NetworkThrottlingIndex" -Value 0xffffffff -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $sysProfile -Name "SystemResponsiveness" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "Optimasi selesai! Nagle's Algorithm dinonaktifkan, latency game kini minimal." -ForegroundColor Green
