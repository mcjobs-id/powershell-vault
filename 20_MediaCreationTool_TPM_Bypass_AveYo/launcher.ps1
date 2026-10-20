# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SUITE BYPASS SYARAT INSTALASI & UPDATE WINDOWS 11 (AVEYO)
# Modul SKU    : FK-PSH-05 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Execution (1 Terminal Mutlak, Bebas Pop-up Jendela)
# Engine       : AveYo Skip_TPM_Check v13 (WMI/IFEO Dynamic Update Bypass)
# Fitur        : Bypass TPM 2.0, Secure Boot, CPU Lawas, Undo 1-Klik, Diagnostik
# ==============================================================================

$Order = if ($args -and $args.Count -gt 0) { $args[0] } else { "" }

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

if (-not $global:fkOrderNumber) {
    if (![string]::IsNullOrWhiteSpace($Order)) {
        $global:fkOrderNumber = $Order
    } elseif ($env:FK_ORDER_ID) {
        $global:fkOrderNumber = $env:FK_ORDER_ID
    } else {
        $dt = Get-Date -Format "yyyyMMdd"
        $rnd = Get-Random -Minimum 1000 -Maximum 9999
        $global:fkOrderNumber = "FK-ORD-$dt-$rnd"
    }
}

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // WINDOWS 11 TPM & SECURE BOOT BYPASS SUITE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        try { [Console]::CursorVisible = $true } catch {}
    } catch {}
}

$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

# Deteksi Status Bypass di Registri Sistem (Before vs After)
function Get-BypassStatus {
    $ifeoKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SetupHost.exe\0"
    if (Test-Path $ifeoKey) {
        $dbg = (Get-ItemProperty -Path $ifeoKey -Name "Debugger" -ErrorAction SilentlyContinue).Debugger
        if ($dbg) { return "INSTALLED" }
    }
    return "NOT_INSTALLED"
}

function Get-SystemHardwareInfo {
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
    if ($cpu) { $cpu = $cpu.Trim() } else { $cpu = "Prosesor Terpasang" }
    
    $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if ($os) { $os = $os.Trim() } else { $os = "Microsoft Windows" }

    return @{ CPU = $cpu; OS = $os }
}

function Test-IsCpuSupported($name) {
    if ($name -match 'i[3579]-(?:[89]\d{3}|[1-9]\d{4})|Core\s+Ultra|Xeon.*(?:v[6-9]|\b[4-9]\d{3})') {
        return $true
    }
    if ($name -match 'Ryzen.*[3579].*(?:[2-9]\d{3}|[1-9]\d{4})|EPYC|Threadripper.*(?:2\d{3}|3\d{3}|5\d{3}|7\d{3})') {
        return $true
    }
    return $false
}

function Get-AccurateTpmInfo {
    # 1. PnpDevice (Bisa dibaca user biasa / non-admin)
    $pnp = Get-PnpDevice -Class 'SecurityDevices' -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'TPM|Trusted Platform' } | Select-Object -First 1
    if ($pnp) {
        $ver = if ($pnp.FriendlyName -match '2\.0') { '2.0' } else { '1.2' }
        return @{
            Present = $true
            Name    = $pnp.FriendlyName
            Status  = $pnp.Status
            Version = $ver
        }
    }

    # 2. Registri TPM WMI (Bisa dibaca user biasa / non-admin)
    $reg = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\TPM\WMI' -ErrorAction SilentlyContinue
    if ($reg -and $reg.TpmBackedDeviceID) {
        return @{
            Present = $true
            Name    = "Trusted Platform Module"
            Status  = "OK"
            Version = "2.0"
        }
    }

    # 3. Cmdlet Get-Tpm (Jika dijalankan dengan hak Administrator)
    $tpm = Get-Tpm -ErrorAction SilentlyContinue
    if ($tpm -and $tpm.TpmPresent) {
        return @{
            Present = $true
            Name    = "Trusted Platform Module"
            Status  = if ($tpm.TpmReady) { "OK" } else { "NotReady" }
            Version = "2.0"
        }
    }

    return @{
        Present = $false
        Name    = "Tidak Terdeteksi"
        Status  = "None"
        Version = "None"
    }
}

function Show-CompactHeader {
    Clear-Host
    $bStatus = Get-BypassStatus
    $hw      = Get-SystemHardwareInfo

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Layanan Jasa Pasang Windows 11 Bypass TPM & Secure Boot" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER    : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET    : [FK-PSH-05] Windows 11 TPM & Hardware Bypass Suite" -ForegroundColor Cyan
    Write-Host "  SISTEM   : [ $($hw.OS) ]" -ForegroundColor White
    Write-Host "  PROSESOR : [ $($hw.CPU) ]" -ForegroundColor Gray

    if ($bStatus -eq "INSTALLED") {
        Write-Host "  BYPASS   : [ TERPASANG / AKTIF ] (Bypass IFEO SetupHost Aktif)" -ForegroundColor Green
    } else {
        if ($hw.OS -match "Windows 11") {
            Write-Host "  BYPASS   : [ STANDAR SISTEM ] (Windows 11 Berjalan Asli)" -ForegroundColor Green
        } else {
            Write-Host "  BYPASS   : [ BELUM TERPASANG ] (Siap Dipasang Untuk Upgrade)" -ForegroundColor Yellow
        }
    }

    Write-Host "  DOKUMEN  : [ AMAN 100% ] (Upgrade Langsung Tanpa Format Ulang)" -ForegroundColor Green
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

$aveyoB64 = "QChzZXQgJyg9KXx8JyA8IyBsZWFuIGFuZCBtZWFuIGNtZCAvIHBvd2Vyc2hlbGwgaHlicmlkICM+IEAnDQoNCjo6IyBHZXQgMTEgb24gJ3Vuc3VwcG9ydGVkJyBQQyB2aWEgV2luZG93cyBVcGRhdGUgb3IgbW91bnRlZCBJU08gKG5vIHBhdGNoaW5nIG5lZWRlZCkNCjo6IyBpZiBXVSBpcyBzdHVjayB1c2Ugd2luZG93c191cGRhdGVfcmVmcmVzaC5iYXQ7IEJldGEvRGV2L0NhbmFyeSBuZWVkcyBPZmZsaW5lSW5zaWRlckVucm9sbA0KOjojIFYxMzogc2tpcCAybmQgdHBtIGNoZWNrIG9uIENhbmFyeSBpc287IG5vIFNlcnZlciBsYWJlbDsgZnV0dXJlIHByb29maW5nOyB0ZXN0ZWQgd2l0aCAyNjAxMCBpc28sIHd1IGFuZCB3dSByZXBhaXIgdmVyc2lvbg0KDQpAZWNobyBvZmYgJiB0aXRsZSBnZXQgMTEgb24gJ3Vuc3VwcG9ydGVkJyBQQyB8fCBBdmVZbyAyMDIzLjEyLjA3DQppZiAvaSAiJX5mMCIgbmVxICIlU3lzdGVtRHJpdmUlXFNjcmlwdHNcZ2V0MTEuY21kIiBnb3RvIHNldHVwDQpwb3dlcnNoZWxsIC13aW4gMSAtbm9wIC1jICI7Ig0Kc2V0IENMST0lKiYgc2V0IFNPVVJDRVM9JVN5c3RlbURyaXZlJVwkV0lORE9XUy5+QlRcU291cmNlcyYgc2V0IE1FRElBPS4mIHNldCBNT0Q9Q0xJJiBzZXQgUFJFPVdVQSYgc2V0IC9hIFZFUj0xMQ0KaWYgbm90IGRlZmluZWQgQ0xJIChleGl0IC9iKSBlbHNlIGlmIG5vdCBleGlzdCAlU09VUkNFUyVcU2V0dXBIb3N0LmV4ZSAoZXhpdCAvYikNCmlmIG5vdCBleGlzdCAlU09VUkNFUyVcV2luZG93c1VwZGF0ZUJveC5leGUgbWtsaW5rIC9oICVTT1VSQ0VTJVxXaW5kb3dzVXBkYXRlQm94LmV4ZSAlU09VUkNFUyVcU2V0dXBIb3N0LmV4ZQ0KcmVnIGFkZCBIS0xNXFNPRlRXQVJFXFBvbGljaWVzXE1pY3Jvc29mdFxXaW5kb3dzXFdpbmRvd3NVcGRhdGUgL2YgL3YgRGlzYWJsZVdVZkJTYWZlZ3VhcmRzIC9kIDEgL3QgcmVnX2R3b3JkDQpyZWcgYWRkIEhLTE1cU1lTVEVNXFNldHVwXE1vU2V0dXAgL2YgL3YgQWxsb3dVcGdyYWRlc1dpdGhVbnN1cHBvcnRlZFRQTW9yQ1BVIC9kIDEgL3QgcmVnX2R3b3JkDQpzZXQgT1BUPS9Db21wYXQgSWdub3JlV2FybmluZyAvTWlncmF0ZURyaXZlcnMgQWxsIC9UZWxlbWV0cnkgRGlzYWJsZQ0Kc2V0IC9hIHJlc3RhcnRfYXBwbGljYXRpb249MHg4MDA3MDVCQiAmIChjYWxsIHNldCBDTEk9JSVDTEk6JTEgPSUlKQ0Kc2V0IC9hIGluY29ycmVjdF9wYXJhbWV0ZXI9MHg4MDA3MDA1NyAmIChzZXQgU1JWPSVDTEk6L1Byb2R1Y3QgQ2xpZW50ID0lKQ0Kc2V0IC9hIGxhdW5jaF9vcHRpb25fZXJyb3I9MHhjMTkwMDEwYSAmIChzZXQgU1JWPSVTUlY6L1Byb2R1Y3QgU2VydmVyID0lKQ0KZm9yICUlVyBpbiAoJUNMSSUpIGRvIGlmIC9pICUlVyA9PSAvUHJlRG93bmxvYWQgKHNldCBNT0Q9U1JWKQ0KZm9yICUlVyBpbiAoJUNMSSUpIGRvIGlmIC9pICUlVyA9PSAvSW5zdGFsbEZpbGUgKHNldCBQUkU9SVNPJiBzZXQgIk1FRElBPSIpIGVsc2UgaWYgbm90IGRlZmluZWQgTUVESUEgc2V0ICJNRURJQT0lJX5kcFciDQppZiAlVkVSJSA9PSAxMSBmb3IgJSVXIGluICgiJU1FRElBJWFwcHJhaXNlcnJlcy5kbGwiKSBkbyBpZiBleGlzdCAlJVcgaWYgJSV+elcgPT0gMCBzZXQgQWxyZWFkeVBhdGNoZWQ9MSAmIHNldCAvYSBWRVI9MTANCmlmICVWRVIlID09IDExIGZpbmRzdHIgL3IgIlAuci5vLmQudS5jLnQuVi5lLnIucy5pLm8ubi4uLjEuMC5cLi4wLlwuLjIuWzItOV0iICVTT1VSQ0VTJVxTZXR1cEhvc3QuZXhlID5udWwgMj5udWwgfHwgc2V0IC9hIFZFUj0xMA0KaWYgJVZFUiUgPT0gMTEgaWYgbm90IGV4aXN0ICIlTUVESUElRUkuY2ZnIiAoZWNobztbQ2hhbm5lbF0+JVNPVVJDRVMlXEVJLmNmZyAmIGVjaG87X0RlZmF1bHQ+PiVTT1VSQ0VTJVxFSS5jZmcpDQppZiAlVkVSJV8lUFJFJSA9PSAxMV9JU08gKCVTT1VSQ0VTJVxXaW5kb3dzVXBkYXRlQm94LmV4ZSAvUHJvZHVjdCBTZXJ2ZXIgL1ByZURvd25sb2FkIC9RdWlldCAlT1BUJSkNCmlmICVWRVIlXyVQUkUlID09IDExX0lTTyAoZGVsIC9mIC9xICVTT1VSQ0VTJVxhcHByYWlzZXJyZXMuZGxsIDI+bnVsICYgY2QuPiVTT1VSQ0VTJVxhcHByYWlzZXJyZXMuZGxsICYgY2FsbCA6Y2FuYXJ5KQ0KaWYgJVZFUiVfJU1PRCUgPT0gMTFfU1JWIChzZXQgQVJHPSVPUFQlICVTUlYlIC9Qcm9kdWN0IFNlcnZlcikNCmlmICVWRVIlXyVNT0QlID09IDExX0NMSSAoc2V0IEFSRz0lT1BUJSAlQ0xJJSkNCiVTT1VSQ0VTJVxXaW5kb3dzVXBkYXRlQm94LmV4ZSAlQVJHJQ0KaWYgJWVycm9ybGV2ZWwlID09ICVyZXN0YXJ0X2FwcGxpY2F0aW9uJSAoY2FsbCA6Y2FuYXJ5ICYgJVNPVVJDRVMlXFdpbmRvd3NVcGRhdGVCb3guZXhlICVBUkclKQ0KZXhpdCAvYg0KDQo6Y2FuYXJ5IGlzbyBza2lwIDJuZCB0cG0gY2hlY2sgYnkgQXZlWW8gIA0Kc2V0IEM9ICAkWD0nJVNPVVJDRVMlXGh3cmVxY2hrLmRsbCc7ICRZPSdTUV9UcG1WZXJzaW9uIEdURSAxJzsgJFo9J1NRX1RwbVZlcnNpb24gR1RFIDAnOyBpZiAodGVzdC1wYXRoICRYKSB7IA0Kc2V0IEM9JUMlICB0cnkgeyB0YWtlb3duLmV4ZSAvZiAkWCAvYTsgaWNhY2xzLmV4ZSAkWCAvZ3JhbnQgKlMtMS01LTMyLTU0NDpmOyBhdHRyaWIgLVIgLVMgJFg7IFtpby5maWxlXTo6T3BlbldyaXRlKCRYKS5jbG9zZSgpIH0NCnNldCBDPSVDJSAgY2F0Y2ggeyByZXR1cm4gfTsgJFI9W1RleHQuRW5jb2RpbmddOjpVVEY4LkdldEJ5dGVzKCRaKTsgJGw9JFIuTGVuZ3RoOyAkaT0yOyAkdz0hMTsNCnNldCBDPSVDJSAgJEI9W2lvLmZpbGVdOjpSZWFkQWxsQnl0ZXMoJFgpOyAkSD1bQml0Q29udmVydGVyXTo6VG9TdHJpbmcoJEIpIC1yZXBsYWNlICctJzsNCnNldCBDPSVDJSAgJFM9W0JpdENvbnZlcnRlcl06OlRvU3RyaW5nKFtUZXh0LkVuY29kaW5nXTo6VVRGOC5HZXRCeXRlcygkWSkpIC1yZXBsYWNlICctJzsNCnNldCBDPSVDJSAgZG8geyAkaT0kSC5JbmRleE9mKCRTLCAkaSArIDIpOyBpZiAoJGkgLWd0IDApIHsgJHc9ITA7IGZvciAoJGs9MDsgJGsgLWx0ICRsOyAkaysrKSB7ICRCWyRrICsgJGkgLyAyXT0kUlska10gfSB9IH0NCnNldCBDPSVDJSAgdW50aWwgKCRpIC1sdCAxKTsgaWYgKCR3KSB7IFtpby5maWxlXTo6V3JpdGVBbGxCeXRlcygkWCwgJEIpOyBbR0NdOjpDb2xsZWN0KCkgfSB9DQppZiAlVkVSJV8lUFJFJSA9PSAxMV9JU08gcG93ZXJzaGVsbCAtbm9wIC1jIGlleCgkZW52OkMpID5udWwgMj5udWwNCmV4aXQgL2INCg0KOnNldHVwDQo6OiMgZWxldmF0ZSB3aXRoIG5hdGl2ZSBzaGVsbCBieSBBdmVZbw0KPm51bCByZWcgYWRkIGhrY3Vcc29mdHdhcmVcY2xhc3Nlc1wuQWRtaW5cc2hlbGxccnVuYXNcY29tbWFuZCAvZiAvdmUgL2QgImNtZCAveCAvZCAvciBzZXQgXCJmMD0lJTJcIiYgY2FsbCBcIiUlMlwiICUlMyImIHNldCBfPSAlKg0KPm51bCBmbHRtY3x8IGlmICIlZjAlIiBuZXEgIiV+ZjAiIChjZC4+IiV0ZW1wJVxydW5hcy5BZG1pbiIgJiBzdGFydCAiJX5uMCIgL2hpZ2ggIiV0ZW1wJVxydW5hcy5BZG1pbiIgIiV+ZjAiICIlXzoiPSIiJSIgJiBleGl0IC9iKQ0KDQo6OiMgbGVhbiB4cCsgY29sb3IgbWFjcm9zIGJ5IEF2ZVlvOiAgJTwlOmFmICIgaGVsbG8gIiU+PiUgICYgICU8JTpjZiAiIHdcIm9yXCJsZCAiJT4lICAgZm9yIHNpbmdsZSBcIC8gIiB1c2UgLiV8JVwgIC4lfCUvICBcIiV8JVwiDQpmb3IgL2YgImRlbGltcz06IiAlJXMgaW4gKCdlY2hvO3Byb21wdCAkaCRzJGg6XnxjbWQgL2QnKSBkbyBzZXQgInw9JSVzIiZzZXQgIj4+PVwuLlxjIG51bCZzZXQgL3Agcz0lJXMlJXMlJXMlJXMlJXMlJXMlJXM8bnVsJnBvcGQiDQpzZXQgIjw9cHVzaGQgIiVhcHBkYXRhJSImMj5udWwgZmluZHN0ciAvYzpcIC9hIiAmc2V0ICI+PSU+PiUmZWNobzsiICZzZXQgInw9JXw6fjAsMSUiICZzZXQgL3Agcz1cPG51bD4iJWFwcGRhdGElXGMiDQoNCjo6IyB0b2dnbGUgd2hlbiBsYXVuY2hlZCB3aXRob3V0IGFyZ3VtZW50cywgZWxzZSBqdW1wIHRvIGFyZ3VtZW50czogImluc3RhbGwiIG9yICJyZW1vdmUiDQpzZXQgQ0xJPSUqJiAoc2V0IElGRU89SEtMTVxTT0ZUV0FSRVxNaWNyb3NvZnRcV2luZG93cyBOVFxDdXJyZW50VmVyc2lvblxJbWFnZSBGaWxlIEV4ZWN1dGlvbiBPcHRpb25zKQ0Kd21pYyAvbmFtZXNwYWNlOiJcXHJvb3Rcc3Vic2NyaXB0aW9uIiBwYXRoIF9fRXZlbnRGaWx0ZXIgd2hlcmUgTmFtZT0iU2tpcCBUUE0gQ2hlY2sgb24gRHluYW1pYyBVcGRhdGUiIGRlbGV0ZSA+bnVsIDI+bnVsICYgcmVtIHYxDQpyZWcgZGVsZXRlICIlSUZFTyVcdmRzbGRyLmV4ZSIgL2YgMj5udWwgJiByZW0gdjIgLSB2NQ0KaWYgL2kgIiVDTEklIj09IiIgcmVnIHF1ZXJ5ICIlSUZFTyVcU2V0dXBIb3N0LmV4ZVwwIiAvdiBEZWJ1Z2dlciA+bnVsIDI+bnVsICYmIGdvdG8gcmVtb3ZlIHx8IGdvdG8gaW5zdGFsbA0KaWYgL2kgIiV+MSI9PSJpbnN0YWxsIiAoZ290byBpbnN0YWxsKSBlbHNlIGlmIC9pICIlfjEiPT0icmVtb3ZlIiBnb3RvIHJlbW92ZQ0KDQo6aW5zdGFsbA0KbWtkaXIgJVN5c3RlbURyaXZlJVxTY3JpcHRzID5udWwgMj5udWwgJiBjb3B5IC95ICIlfmYwIiAiJVN5c3RlbURyaXZlJVxTY3JpcHRzXGdldDExLmNtZCIgPm51bCAyPm51bA0KcmVnIGFkZCAiJUlGRU8lXFNldHVwSG9zdC5leGUiIC9mIC92IFVzZUZpbHRlciAvZCAxIC90IHJlZ19kd29yZCA+bnVsDQpyZWcgYWRkICIlSUZFTyVcU2V0dXBIb3N0LmV4ZVwwIiAvZiAvdiBGaWx0ZXJGdWxsUGF0aCAvZCAiJVN5c3RlbURyaXZlJVwkV0lORE9XUy5+QlRcU291cmNlc1xTZXR1cEhvc3QuZXhlIiA+bnVsDQpyZWcgYWRkICIlSUZFTyVcU2V0dXBIb3N0LmV4ZVwwIiAvZiAvdiBEZWJ1Z2dlciAvZCAiJVN5c3RlbURyaXZlJVxTY3JpcHRzXGdldDExLmNtZCIgPm51bA0KZWNobzsNCiU8JTpmMCAiIFNraXAgVFBNIENoZWNrIG9uIER5bmFtaWMgVXBkYXRlIFYxMyAiJT4+JSAmICU8JToyZiAiIElOU1RBTExFRCAiJT4+JSAmICU8JTpmMCAiIHJ1biBhZ2FpbiB0byByZW1vdmUgIiU+JQ0KaWYgL2kgIiVDTEklIj09IiIgdGltZW91dCAvdCA3DQpleGl0IC9iDQoNCjpyZW1vdmUNCmRlbCAvZiAvcSAiJVN5c3RlbURyaXZlJVxTY3JpcHRzXGdldDExLmNtZCIgIiVQdWJsaWMlXGdldDExLmNtZCIgIiVQcm9ncmFtRGF0YSVcZ2V0MTEuY21kIiA+bnVsIDI+bnVsDQpyZWcgZGVsZXRlICIlSUZFTyVcU2V0dXBIb3N0LmV4ZSIgL2YgPm51bCAyPm51bA0KZWNobzsNCiU8JTpmMCAiIFNraXAgVFBNIENoZWNrIG9uIER5bmFtaWMgVXBkYXRlIFYxMyAiJT4+JSAmICU8JTpkZiAiIFJFTU9WRUQgIiU+PiUgJiAlPCU6ZjAgIiBydW4gYWdhaW4gdG8gaW5zdGFsbCAiJT4lDQppZiAvaSAiJUNMSSUiPT0iIiB0aW1lb3V0IC90IDcNCmV4aXQgL2INCg0KJ0ApOyAkMCA9ICIkZW52OnRlbXBcU2tpcF9UUE1fQ2hlY2tfb25fRHluYW1pY19VcGRhdGUuY21kIjsgJHsoPSl8fH0gLXNwbGl0ICJccj9cbiIgfCBvdXQtZmlsZSAkMCAtZW5jb2RpbmcgZGVmYXVsdCAtZm9yY2U7ICYgJDANCiMgcHJlc3MgZW50ZXINCg=="

function Invoke-SilentElevation {
    param(
        [string]$EncodedCommand
    )

    $workerVbs = Join-Path $env:TEMP ("fk_worker_" + [Guid]::NewGuid().ToString('N').Substring(0,8) + ".vbs")
    $vbsContent = @"
Set Wsh = CreateObject("WScript.Shell")
Wsh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedCommand", 0, True
"@
    try {
        [System.IO.File]::WriteAllText($workerVbs, $vbsContent, [System.Text.Encoding]::ASCII)
        $p = Start-Process -FilePath "wscript.exe" -ArgumentList ('"' + $workerVbs + '"') -Verb RunAs -Wait -PassThru
        Start-Sleep -Milliseconds 600
        return ($p.ExitCode -eq 0)
    } catch {
        try {
            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $EncodedCommand" -Verb RunAs -Wait -PassThru
            return ($p.ExitCode -eq 0)
        } catch {
            return $false
        }
    } finally {
        Remove-Item -Path $workerVbs -Force -ErrorAction SilentlyContinue
    }
}

function Apply-BypassAction {
    Write-Host ""
    Write-Host "  [PROSES] Memasang Bypass Syarat Perangkat Keras Windows 11..." -ForegroundColor Cyan

    $workerScript = {
        param($b64Data)

        # 1. Pastikan berkas engine AveYo terpasang di Scripts
        $scriptsDir = "$env:SystemDrive\Scripts"
        if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null }
        $get11Cmd = "$scriptsDir\get11.cmd"
        [System.IO.File]::WriteAllBytes($get11Cmd, [Convert]::FromBase64String($b64Data))

        # 2. Pemasangan Hook IFEO pada SetupHost.exe
        $ifeoBase = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SetupHost.exe"
        if (-not (Test-Path $ifeoBase)) { New-Item -Path $ifeoBase -Force | Out-Null }
        Set-ItemProperty -Path $ifeoBase -Name "UseFilter" -Value 1 -Type DWord -Force | Out-Null

        $ifeoSub = "$ifeoBase\0"
        if (-not (Test-Path $ifeoSub)) { New-Item -Path $ifeoSub -Force | Out-Null }
        Set-ItemProperty -Path $ifeoSub -Name "FilterFullPath" -Value "$env:SystemDrive\`$WINDOWS.~BT\Sources\SetupHost.exe" -Type String -Force | Out-Null
        Set-ItemProperty -Path $ifeoSub -Name "Debugger" -Value $get11Cmd -Type String -Force | Out-Null

        # 3. Kebijakan Resmi Microsoft MoSetup & Windows Update
        $moSetup = "HKLM:\SYSTEM\Setup\MoSetup"
        if (-not (Test-Path $moSetup)) { New-Item -Path $moSetup -Force | Out-Null }
        Set-ItemProperty -Path $moSetup -Name "AllowUpgradesWithUnsupportedTPMorCPU" -Value 1 -Type DWord -Force | Out-Null

        $wuPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (-not (Test-Path $wuPolicies)) { New-Item -Path $wuPolicies -Force | Out-Null }
        Set-ItemProperty -Path $wuPolicies -Name "DisableWUfBSafeguards" -Value 1 -Type DWord -Force | Out-Null
    }

    if ($isAdmin) {
        Write-Host "  > Mengonfigurasi kebijakan resmi Microsoft MoSetup... " -ForegroundColor Cyan -NoNewline
        & $workerScript -b64Data $aveyoB64
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Mendaftarkan hook IFEO pembungkus SetupHost.exe... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Membuka proteksi Windows Update Safeguards... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green
    } else {
        Write-Host "  > Mengalihkan tugas ke worker senyap berizin sistem (UAC)... " -ForegroundColor Yellow
        $code = '& {' + $workerScript.ToString() + "} '$aveyoB64'"
        $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        Invoke-SilentElevation -EncodedCommand $b64
        if ((Get-BypassStatus) -eq "INSTALLED") {
            Write-Host "  [OK] Seluruh protokol bypass berhasil diterapkan ke sistem." -ForegroundColor Green
        } else {
            Write-Host "  [!] Izin Administrator dibatalkan oleh pengguna (UAC ditolak)." -ForegroundColor Red
            return
        }
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Bypass Syarat Windows 11 Telah Aktif!" -ForegroundColor Green
    Write-Host "  * PC Anda kini siap upgrade ke Windows 11 via Windows Update / ISO." -ForegroundColor White
    Write-Host "  * Melewati syarat chip TPM 2.0, Secure Boot, & CPU generasi lama." -ForegroundColor White
    Write-Host "  * Seluruh dokumen, foto, dan aplikasi Anda aman tanpa format ulang." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Remove-BypassAction {
    Write-Host ""
    Write-Host "  [PROSES] Mencabut Bypass Syarat Windows 11 (Undo / Restore)..." -ForegroundColor Yellow

    $workerScript = {
        # 1. Hapus IFEO SetupHost.exe
        $ifeoSub = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SetupHost.exe\0"
        if (Test-Path $ifeoSub) { Remove-Item -Path $ifeoSub -Recurse -Force -ErrorAction SilentlyContinue }

        $ifeoBase = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SetupHost.exe"
        if (Test-Path $ifeoBase) { Remove-ItemProperty -Path $ifeoBase -Name "UseFilter" -Force -ErrorAction SilentlyContinue }

        # 2. Hapus Kebijakan MoSetup & Safeguards
        $moSetup = "HKLM:\SYSTEM\Setup\MoSetup"
        if (Test-Path $moSetup) { Remove-ItemProperty -Path $moSetup -Name "AllowUpgradesWithUnsupportedTPMorCPU" -Force -ErrorAction SilentlyContinue }

        $wuPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (Test-Path $wuPolicies) { Remove-ItemProperty -Path $wuPolicies -Name "DisableWUfBSafeguards" -Force -ErrorAction SilentlyContinue }

        # 3. Bersihkan berkas get11.cmd
        $targets = @(
            "$env:SystemDrive\Scripts\get11.cmd",
            "$env:Public\get11.cmd",
            "$env:ProgramData\get11.cmd"
        )
        foreach ($t in $targets) {
            if (Test-Path $t) { Remove-Item -LiteralPath $t -Force -ErrorAction SilentlyContinue }
        }
    }

    if ($isAdmin) {
        Write-Host "  > Menghapus hook IFEO pembungkus SetupHost.exe... " -ForegroundColor Cyan -NoNewline
        & $workerScript
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Menghapus kebijakan MoSetup & Update Safeguards... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Membersihkan modul get11.cmd dari sistem... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green
    } else {
        Write-Host "  > Mengalihkan tugas pencabutan ke worker senyap (UAC)... " -ForegroundColor Yellow
        $code = '& {' + $workerScript.ToString() + '}'
        $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        Invoke-SilentElevation -EncodedCommand $b64
        if ((Get-BypassStatus) -eq "NOT_INSTALLED") {
            Write-Host "  [OK] Seluruh protokol bypass berhasil dicabut dari sistem." -ForegroundColor Green
        } else {
            Write-Host "  [!] Pencabutan dibatalkan oleh pengguna (UAC ditolak)." -ForegroundColor Red
            return
        }
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Sistem Berhasil Dikembalikan ke Standar Microsoft!" -ForegroundColor Green
    Write-Host "  * Seluruh konfigurasi bypass telah dicabut bersih tanpa sisa." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Check-DiagnosticStatus {
    Write-Host ""
    Write-Host "  [DIAGNOSTIK] Memeriksa Kesiapan Perangkat Keras Komputer..." -ForegroundColor Cyan

    $hw = Get-SystemHardwareInfo
    Write-Host "  * Sistem Operasi     : $($hw.OS)" -ForegroundColor White
    Write-Host "  * Prosesor Terpasang : $($hw.CPU)" -ForegroundColor White

    # 1. Kesesuaian CPU
    $cpuSup = Test-IsCpuSupported $hw.CPU
    Write-Host "  * Kesesuaian CPU     : " -ForegroundColor White -NoNewline
    if ($cpuSup) {
        Write-Host "DIDUKUNG RESMI [GEN 8+ / RYZEN 2+]" -ForegroundColor Green
    } else {
        Write-Host "GENERASI LAWAS [DIBYPASS OLEH SUITE INI]" -ForegroundColor Yellow
    }

    # 2. Cek TPM (Non-Admin Resilient)
    Write-Host "  * Modul TPM Hardware : " -ForegroundColor White -NoNewline
    $tpm = Get-AccurateTpmInfo
    if ($tpm.Present -and ($tpm.Version -eq "2.0" -or $tpm.Status -eq "OK")) {
        Write-Host "$($tpm.Name) [TERDETEKSI / AKTIF]" -ForegroundColor Green
    } elseif ($tpm.Present) {
        Write-Host "$($tpm.Name) [TERDETEKSI / PERLU BYPASS]" -ForegroundColor Yellow
    } else {
        Write-Host "TIDAK TERDETEKSI / LAWAS [DIBYPASS]" -ForegroundColor Yellow
    }

    # 3. Cek UEFI & Secure Boot (Non-Admin Resilient)
    Write-Host "  * Firmware & Boot    : " -ForegroundColor White -NoNewline
    $fw = [Environment]::GetEnvironmentVariable('firmware_type')
    if (-not $fw) { $fw = if (Test-Path "$env:SystemDrive\EFI") { "UEFI" } else { "BIOS" } }

    $sb = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction SilentlyContinue).UEFISecureBootEnabled

    if ($fw -eq "UEFI") {
        if ($sb -eq 1) {
            Write-Host "UEFI [SECURE BOOT AKTIF]" -ForegroundColor Green
        } else {
            Write-Host "UEFI [SECURE BOOT NONAKTIF / DIBYPASS]" -ForegroundColor Yellow
        }
    } else {
        Write-Host "LEGACY BIOS [DIBYPASS OLEH SUITE INI]" -ForegroundColor Yellow
    }

    # 4. Status Hook IFEO
    Write-Host "  * Status Hook IFEO   : " -ForegroundColor White -NoNewline
    $bStatus = Get-BypassStatus
    if ($bStatus -eq "INSTALLED") {
        Write-Host "TERPASANG [SIAP UPGRADE TANPA SYARAT]" -ForegroundColor Green
    } else {
        Write-Host "STANDAR (BELUM ADA HOOK BYPASS)" -ForegroundColor Gray
    }

    # 5. Kebijakan MoSetup
    Write-Host "  * Kebijakan MoSetup  : " -ForegroundColor White -NoNewline
    $mo = (Get-ItemProperty "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMorCPU" -ErrorAction SilentlyContinue).AllowUpgradesWithUnsupportedTPMorCPU
    if ($mo -eq 1) {
        Write-Host "ALLOW UPGRADES [AKTIF]" -ForegroundColor Green
    } else {
        Write-Host "STANDAR WINDOWS" -ForegroundColor Gray
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Launch-WindowsUpdate {
    Write-Host ""
    Write-Host "  Membuka Pengaturan Windows Update di layar..." -ForegroundColor Cyan
    Start-Process "ms-settings:windowsupdate"
    Write-Host "  [OK] Halaman Windows Update berhasil dibuka." -ForegroundColor Green
    Write-Host "  Silakan klik tombol 'Check for updates' untuk memulai pembaruan." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

# Main Interactive Loop
try {
    while ($true) {
        Show-CompactHeader
        Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Pasang Bypass Syarat Windows 11 (Buka Blokir TPM & CPU)" -ForegroundColor Green
        Write-Host "  [2] Cabut / Lepas Bypass (Kembalikan ke Setelan Bawaan / Undo)" -ForegroundColor Yellow
        Write-Host "  [3] Cek Diagnostik Kesiapan Perangkat Keras PC" -ForegroundColor Cyan
        Write-Host "  [4] Buka Windows Update di Layar (Mulai Update)" -ForegroundColor White
        Write-Host "  [5] Toko Digital FokusKonten (Buka Web)" -ForegroundColor Cyan
        Write-Host "  [0] Selesai & Keluar" -ForegroundColor Gray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 4, 5, 0] : " -ForegroundColor Yellow

        $choice = ""
        try {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString()
            Write-Host $choice -ForegroundColor Green
        } catch {
            $choice = Read-Host
        }

        switch ($choice) {
            "1" { Apply-BypassAction }
            "2" { Remove-BypassAction }
            "3" { Check-DiagnosticStatus }
            "4" { Launch-WindowsUpdate }
            "5" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
            "0" {
                Restore-Terminal
                Write-Host ""
                Write-Host "================================================================" -ForegroundColor Cyan
                Write-Host "        TERIMA KASIH TELAH MENGGUNAKAN LAYANAN RESMI            " -ForegroundColor Yellow
                Write-Host "                  THANKS ORDER BY FOKUSKONTEN                   " -ForegroundColor Green
                Write-Host "================================================================" -ForegroundColor Cyan
                Write-Host ""
                return
            }
        }
    }
} finally {
    Restore-Terminal
}
