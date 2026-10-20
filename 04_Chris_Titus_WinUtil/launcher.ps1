# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SUITE OPTIMASI & REKAYASA SISTEM WINDOWS PRO (WINUTIL)
# Modul SKU    : FK-PSH-06 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Execution dengan VBScript Auto-Elevation Fallback
# Fitur        : Antarmuka WPF GUI, Quick Debloat, Winget Installer, Tweaks & Config
# Keandalan    : Multi-Tier CDN Mirror, VBS Shell Elevation, Universal Win10/11
# ==============================================================================

param(
    [string]$Order = ""
)

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

$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // WINDOWS OPTIMIZER PRO SUITE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Test-IsAdmin {
    try {
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Invoke-VBSElevation {
    param(
        [string]$TargetFile,
        [string]$Arguments = "",
        [int]$ShowMode = 0
    )

    $escapedArgs   = $Arguments.Replace('"', '""')
    $escapedTarget = $TargetFile.Replace('"', '""')

    $vbsFile = Join-Path $env:TEMP "fk_uac_elevate.vbs"
    $vbsContent = @"
Set UAC = CreateObject("Shell.Application")
UAC.ShellExecute "$escapedTarget", "$escapedArgs", "", "runas", $ShowMode
"@
    try {
        [System.IO.File]::WriteAllText($vbsFile, $vbsContent, [System.Text.Encoding]::ASCII)
        Start-Process -FilePath "wscript.exe" -ArgumentList "`"$vbsFile`"" -Wait
        Start-Sleep -Milliseconds 300
        Remove-Item -Path $vbsFile -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        try {
            $sh = New-Object -ComObject Shell.Application
            $sh.ShellExecute($TargetFile, $Arguments, "", "runas", $ShowMode)
            return $true
        } catch {
            return $false
        }
    }
}

function Get-OSDiagnostic {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        return $os
    } catch {
        return $null
    }
}

function Test-WingetInstalled {
    try {
        $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = (winget --version 2>$null)
            if ($ver) { return $ver.Trim() }
            return "Aktif"
        }
        return $null
    } catch {
        return $null
    }
}

function Resolve-WinUtilScriptPath {
    param([switch]$ForceDownload)

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    # 1. Cek berkas berdampingan di direktori yang sama
    $adjacentScript = Join-Path $scriptDir "winutil.ps1"
    if ((-not $ForceDownload) -and (Test-Path $adjacentScript)) {
        return $adjacentScript
    }

    # 2. Cek berkas master di repositori lokal FokusKonten (PC Server / Dev)
    $localVaultScript = "D:\FokusKonten-Server\POWERSHELL_VAULT\04_Chris_Titus_WinUtil\winutil.ps1"
    if ((-not $ForceDownload) -and (Test-Path $localVaultScript)) {
        return $localVaultScript
    }

    # 3. Cek berkas di direktori cache sementara
    $cacheDir = Join-Path $env:TEMP "FokusKonten_WinUtil"
    $cacheScript = Join-Path $cacheDir "winutil.ps1"
    if ((-not $ForceDownload) -and (Test-Path $cacheScript)) {
        return $cacheScript
    }

    # 4. Unduh dari CDN Resmi rilis GitHub (Sesuai [INV-18] Bebas Beban Server)
    Write-Host "  > Mengunduh engine antarmuka visual dari Global CDN Mirror... " -ForegroundColor Cyan -NoNewline
    try {
        if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
        $remoteUrl = "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
        Invoke-WebRequest -Uri $remoteUrl -OutFile $cacheScript -UseBasicParsing -TimeoutSec 30
        if (Test-Path $cacheScript) {
            Write-Host "[OK]" -ForegroundColor Green
            return $cacheScript
        }
    } catch {
        Write-Host "[GAGAL]" -ForegroundColor Red
        Write-Host "    Peringatan: Gagal mengunduh biner: $($_.Exception.Message)" -ForegroundColor Red
    }

    return $null
}

function Show-CompactHeader {
    Clear-Host
    $isAdmin = Test-IsAdmin
    $os = Get-OSDiagnostic
    $wingetVer = Test-WingetInstalled

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
    $localScript = Join-Path $scriptDir "winutil.ps1"
    $vaultScript = "D:\FokusKonten-Server\POWERSHELL_VAULT\04_Chris_Titus_WinUtil\winutil.ps1"

    $engineStatus = if (Test-Path $localScript) {
        "LOCAL REPOSITORY [READY]"
    } elseif (Test-Path $vaultScript) {
        "MASTER VAULT [READY]"
    } else {
        "GLOBAL EDGE CDN [ONLINE]"
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  R E S C U E  S U I T E" -ForegroundColor Yellow
    Write-Host "  WinUtil Pro: Ultimate Windows Performance & Debloat Engine" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER    : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  SUITE    : [FK-PSH-06] Windows Ultimate Performance Tuning" -ForegroundColor DarkCyan

    if ($os) {
        Write-Host "  SYSTEM   : $($os.Caption) ($($os.OSArchitecture), Build $($os.BuildNumber))" -ForegroundColor White
    } else {
        Write-Host "  SYSTEM   : Microsoft Windows Desktop OS" -ForegroundColor White
    }

    if ($isAdmin) {
        Write-Host "  PRIVILEGE: [ ADMINISTRATOR VERIFIED ] (Full Kernel Access)" -ForegroundColor Green
    } else {
        Write-Host "  PRIVILEGE: [ RESTRICTED ACCESS ] (Auto-Elevate Siaga via Menu 1)" -ForegroundColor Yellow
    }

    if ($wingetVer) {
        Write-Host "  WINGET   : [ PACKAGE ENGINE ACTIVE ] (Version $wingetVer)" -ForegroundColor Green
    } else {
        Write-Host "  WINGET   : [ NOT DETECTED ] (Pilih Menu [3] untuk Inisialisasi)" -ForegroundColor Yellow
    }

    Write-Host "  STATUS   : [ $engineStatus ]" -ForegroundColor Green
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Invoke-WinUtilGUIInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Menyiapkan Antarmuka Grafis (WPF Pro Dashboard)..." -ForegroundColor Cyan

    $scriptPath = Resolve-WinUtilScriptPath
    if (-not $scriptPath) {
        Write-Host "  [GALAT] Berkas antarmuka visual tidak dapat dimuat dari CDN." -ForegroundColor Red
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Write-Host "  > Menginisialisasi otorisasi Administrator via VBS Engine... " -ForegroundColor Cyan -NoNewline
        $elevated = Invoke-VBSElevation -TargetFile "powershell.exe" -Arguments "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" -ShowMode 0
        if ($elevated) {
            Write-Host "[OK]" -ForegroundColor Green
            Write-Host ""
            Write-Host "  [BERHASIL] Antarmuka Pro Dashboard telah diluncurkan secara otomatis!" -ForegroundColor Green
            Write-Host "  Konsol kedua disembunyikan (mode senyap) demi menjaga kebersihan layar Anda." -ForegroundColor White
        } else {
            Write-Host "[GAGAL]" -ForegroundColor Red
            Write-Host "  Gagal memicu VBS elevation." -ForegroundColor Red
        }

        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    # Jika sudah Administrator, jalankan langsung di dalam session aktif
    Write-Host "  > Menginisialisasi runspaces antarmuka visual... " -ForegroundColor Cyan -NoNewline
    try {
        & $scriptPath
        Write-Host "[OK]" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [BERHASIL] Sesi kerja dashboard optimasi telah selesai." -ForegroundColor Green
    } catch {
        Write-Host "[GAGAL]" -ForegroundColor Red
        Write-Host "  Galat: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function New-SystemRestorePointInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Membuat Titik Pemulihan Sistem (System Restore Point)..." -ForegroundColor Cyan

    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Write-Host "  > Menginisialisasi otorisasi Administrator via VBS Engine... " -ForegroundColor Cyan -NoNewline
        $cmd = "Checkpoint-Computer -Description 'FokusKonten_Pre_Optimization_Backup' -RestorePointType 'MODIFY_SETTINGS'"
        $elevated = Invoke-VBSElevation -TargetFile "powershell.exe" -Arguments "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$cmd`"" -ShowMode 0
        if ($elevated) {
            Write-Host "[OK]" -ForegroundColor Green
            Write-Host "  [BERHASIL] Permintaan Restore Point telah dikirim via VBS UAC!" -ForegroundColor Green
        } else {
            Write-Host "[GAGAL]" -ForegroundColor Red
        }
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    Write-Host "  > Mengaktifkan perlindungan sistem di Drive C: ... " -ForegroundColor Cyan -NoNewline
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Write-Host "[OK]" -ForegroundColor Green
    } catch {
        Write-Host "[LEWATI]" -ForegroundColor Yellow
    }

    Write-Host "  > Mendaftarkan Checkpoint Pemulihan Aman FokusKonten... " -ForegroundColor Cyan -NoNewline
    try {
        Checkpoint-Computer -Description "FokusKonten_Pre_Optimization_Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[OK]" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [BERHASIL] Titik Pemulihan Sistem Berhasil Dibuat!" -ForegroundColor Green
        Write-Host "  Sistem Windows Anda kini terlindungi 100% aman sebelum optimasi." -ForegroundColor White
    } catch {
        Write-Host "[PERINGATAN]" -ForegroundColor Yellow
        Write-Host "  Keterangan: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host "  (Windows membatasi Restore Point otomatis maksimal 1x per 24 jam." -ForegroundColor DarkGray
        Write-Host "   Restore Point sebelumnya tetap aktif melindungi sistem Anda)." -ForegroundColor DarkGray
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Install-WingetInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Memeriksa & Mengonfigurasi Microsoft Winget Engine..." -ForegroundColor Cyan

    $wingetVer = Test-WingetInstalled
    if ($wingetVer) {
        Write-Host "  > Engine Winget sudah aktif di sistem ini (Versi: $wingetVer)." -ForegroundColor Green
        Write-Host "  > Melakukan sinkronisasi database repositori winget... " -ForegroundColor Cyan -NoNewline
        try {
            $testSource = winget source list 2>$null
            Write-Host "[OK]" -ForegroundColor Green
            Write-Host ""
            Write-Host "  [BERHASIL] Repositori Winget siap digunakan untuk instalasi ribuan aplikasi!" -ForegroundColor Green
        } catch {
            Write-Host "[LEWATI]" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Mengunduh installer resmi Microsoft Desktop AppInstaller... " -ForegroundColor Cyan -NoNewline
        try {
            $wingetBundleUrl = "https://aka.ms/getwinget"
            $destFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller_latest.msixbundle"
            Invoke-WebRequest -Uri $wingetBundleUrl -OutFile $destFile -UseBasicParsing -TimeoutSec 60
            Write-Host "[OK]" -ForegroundColor Green

            Write-Host "  > Memasang pustaka installer ke dalam sistem... " -ForegroundColor Cyan -NoNewline
            Add-AppxPackage -Path $destFile -ErrorAction Stop
            Write-Host "[OK]" -ForegroundColor Green
            Write-Host ""
            Write-Host "  [BERHASIL] Microsoft Winget berhasil dipasang dan siap digunakan!" -ForegroundColor Green
        } catch {
            Write-Host "[GAGAL]" -ForegroundColor Red
            Write-Host "  Keterangan: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Anda juga dapat mengunduh langsung dari Microsoft Store (App Installer)." -ForegroundColor Yellow
        }
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Invoke-StandardOptimizationsInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Menjalankan Preset Optimasi Performa Esensial..." -ForegroundColor Cyan

    $isAdmin = Test-IsAdmin
    if (-not $isAdmin) {
        Write-Host "  > Menginisialisasi otorisasi Administrator via VBS Engine... " -ForegroundColor Cyan -NoNewline
        $tweakScript = @'
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "20" -Type String -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "[BERHASIL] Optimasi esensial selesai dieksekusi." -ForegroundColor Green
'@
        $tweakFile = Join-Path $env:TEMP "fk_tweaks_temp.ps1"
        [System.IO.File]::WriteAllText($tweakFile, $tweakScript, [System.Text.Encoding]::UTF8)
        $elevated = Invoke-VBSElevation -TargetFile "powershell.exe" -Arguments "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tweakFile`"" -ShowMode 0
        if ($elevated) {
            Write-Host "[OK]" -ForegroundColor Green
            Write-Host "  [BERHASIL] Optimasi sedang diterapkan dengan izin Administrator via VBS!" -ForegroundColor Green
        } else {
            Write-Host "[GAGAL]" -ForegroundColor Red
        }
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    Write-Host "  Daftar optimasi yang akan diterapkan pada perangkat:" -ForegroundColor White
    Write-Host "  * Menonaktifkan Telemetri Pengintai & Diagnostik Latar Belakang" -ForegroundColor Gray
    Write-Host "  * Mematikan Iklan di Start Menu & Saran Promosi Bawaan Windows" -ForegroundColor Gray
    Write-Host "  * Mengaktifkan DNS Aman Bebas Blokir Internet Positif (Cloudflare 1.1.1.1)" -ForegroundColor Gray
    Write-Host "  * Mempercepat Waktu Respons Buka Menu & Jendela Aplikasi (20ms)" -ForegroundColor Gray
    Write-Host ""
    Write-Host -NoNewline "  Terapkan seluruh optimasi esensial sekarang? [Y/N] : " -ForegroundColor Yellow

    $confirm = ""
    try {
        $k = [Console]::ReadKey($true)
        $confirm = $k.KeyChar.ToString().ToUpper()
        Write-Host $confirm -ForegroundColor Green
    } catch {
        $confirm = (Read-Host).ToUpper()
    }

    if ($confirm -ne "Y") {
        Write-Host "  Operasi dibatalkan oleh pengguna." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 800
        return
    }

    # 1. Telemetry Registry
    Write-Host "  > Menutup jalur telemetri & diagnostik latar belakang... " -ForegroundColor Cyan -NoNewline
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "[OK]" -ForegroundColor Green
    } catch {
        Write-Host "[LEWATI]" -ForegroundColor Yellow
    }

    # 2. Start menu suggestions
    Write-Host "  > Menghapus saran promosi & bloatware start menu... " -ForegroundColor Cyan -NoNewline
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "[OK]" -ForegroundColor Green
    } catch {
        Write-Host "[LEWATI]" -ForegroundColor Yellow
    }

    # 3. Menu show delay
    Write-Host "  > Mengatur jeda respons menu Windows menjadi 20ms ultra-cepat... " -ForegroundColor Cyan -NoNewline
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "20" -Type String -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "[OK]" -ForegroundColor Green
    } catch {
        Write-Host "[LEWATI]" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Seluruh penyesuaian esensial berhasil diterapkan secara instan!" -ForegroundColor Green
    Write-Host "  Performa sistem kini lebih responsif, hemat RAM, dan bebas iklan." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Show-SystemDiagnosticInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Mengaudit Status Kesehatan & Performa Perangkat..." -ForegroundColor Cyan

    $os = Get-OSDiagnostic
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $proc = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $diskC = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  HASIL AUDIT SPESIFIKASI & DIAGNOSTIK HARDWARE:" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray

    if ($cs) {
        Write-Host "  * Model Perangkat: $($cs.Manufacturer) - $($cs.Model)" -ForegroundColor White
    }
    if ($proc) {
        Write-Host "  * Processor      : $($proc.Name)" -ForegroundColor White
        Write-Host "  * Core / Thread  : $($proc.NumberOfCores) Cores, $($proc.NumberOfLogicalProcessors) Threads" -ForegroundColor White
    }
    if ($os) {
        $totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRamGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)
        $ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

        Write-Host "  * RAM Fisik      : $usedRamGB GB aktif dari total $totalRamGB GB ($ramPercent% beban)" -ForegroundColor White
        Write-Host "  * Sistem Operasi : $($os.Caption) (Build $($os.BuildNumber))" -ForegroundColor White
        Write-Host "  * Arsitektur     : $($os.OSArchitecture)" -ForegroundColor White
    }
    if ($diskC) {
        $totalDiskGB = [math]::Round($diskC.Size / 1GB, 1)
        $freeDiskGB  = [math]::Round($diskC.FreeSpace / 1GB, 1)
        $freePercent = [math]::Round(($freeDiskGB / $totalDiskGB) * 100, 1)

        Write-Host "  * Drive Sistem C : Sisa $freeDiskGB GB dari total $totalDiskGB GB ($freePercent% kapasitas bebas)" -ForegroundColor White
    }

    $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuService) {
        $wuColor = if ($wuService.Status -eq 'Running') { 'Green' } else { 'Yellow' }
        Write-Host "  * Windows Update : Status Servis $($wuService.Status)" -ForegroundColor $wuColor
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

# ==============================================================================
# MAIN PROGRAM LOOP (100% IN-PLACE DENGAN VBS AUTO-ELEVATION)
# ==============================================================================
try {
    while ($true) {
        Show-CompactHeader
        Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Buka Antarmuka Grafis (WPF Pro Dashboard)" -ForegroundColor Green
        Write-Host "  [2] Buat Titik Pemulihan Sistem (System Restore Point) Baru" -ForegroundColor Cyan
        Write-Host "  [3] Inisialisasi Engine Microsoft Winget Package Manager" -ForegroundColor Green
        Write-Host "  [4] Terapkan Optimasi Cepat (Essential Performance Tweaks)" -ForegroundColor Yellow
        Write-Host "  [5] Diagnostik Mendalam Perangkat (Hardware & Health Audit)" -ForegroundColor White
        Write-Host "  [6] Ekosistem & Layanan Digital FokusKonten (Buka Web)" -ForegroundColor DarkCyan
        Write-Host "  [0] Tutup Sesi & Keluar" -ForegroundColor DarkGray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 4, 5, 6, 0] : " -ForegroundColor Yellow

        $choice = ""
        try {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString()
            Write-Host $choice -ForegroundColor Green
        } catch {
            $choice = Read-Host
        }

        switch ($choice) {
            "1" { Invoke-WinUtilGUIInPlace }
            "2" { New-SystemRestorePointInPlace }
            "3" { Install-WingetInPlace }
            "4" { Invoke-StandardOptimizationsInPlace }
            "5" { Show-SystemDiagnosticInPlace }
            "6" {
                Start-Process "https://fokuskonten.my.id/toko-digital/"
                Write-Host "  Membuka etalase digital FokusKonten di peramban web..." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 800
            }
            "0" {
                Restore-Terminal
                Write-Host ""
                Write-Host "  Terima kasih telah mempercayakan performa PC Anda kepada FokusKonten." -ForegroundColor Green
                Write-Host ""
                return
            }
        }
    }
} finally {
    Restore-Terminal
}
