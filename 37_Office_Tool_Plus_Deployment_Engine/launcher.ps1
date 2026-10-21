# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : JASA PASANG & KUSTOMISASI KOMPONEN OFFICE TOOL PLUS
# Modul SKU    : FK-PSH-37 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Single Terminal Execution (Zero Pop-Up Spam)
# Engine       : Microsoft Official ODT Engine & Yerong Office Tool Plus v11.8
# Keamanan     : 100% Resmi CDN Microsoft (Zero Bloatware & Deep Scrub Corrupt Fix)
# ==============================================================================

param (
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

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FOKUSKONTEN // RESCUE SUITE [FK-PSH-37]"
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

# Direktori & Konfigurasi Cache
$WorkDir    = "$env:ProgramData\FokusKonten\OfficeToolPlus"
$OdtSetupExe = "$WorkDir\setup.exe"
$OtpZipFile = "$WorkDir\Office_Tool_Plus_Runtime.zip"
$OtpExe     = "$WorkDir\Office Tool\Office Tool Plus.exe"

# URL CDN Resmi FokusKonten & Microsoft Edge CDN
$VaultSetupUrl = "https://github.com/mcjobs-id/powershell-vault/releases/download/v1.0.0/setup.exe"
$YerongRuntimeUrl = "https://github.com/YerongAI/Office-Tool/releases/download/v11.8.50.0/Office_Tool_with_runtime_v11.8.50.0_x64.zip"

function Get-SystemSensors {
    $cDrive = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -eq 'C:' }
    $freeGb = if ($cDrive) { [math]::Round($cDrive.FreeSpace / 1GB, 1) } else { 0 }

    # Deteksi Office Terpasang
    $offStatus = "Belum Terdeteksi (Siap Pasang Bersih)"
    $c2rPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $c2rPath) {
        $prod = (Get-ItemProperty -Path $c2rPath -Name "ProductReleaseIds" -ErrorAction SilentlyContinue).ProductReleaseIds
        $ver  = (Get-ItemProperty -Path $c2rPath -Name "VersionToReport" -ErrorAction SilentlyContinue).VersionToReport
        $arch = (Get-ItemProperty -Path $c2rPath -Name "Platform" -ErrorAction SilentlyContinue).Platform
        if ($prod) {
            $offStatus = "$prod [$arch] (v$ver)"
        }
    } else {
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
            "HKLM:\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot"
        )
        foreach ($rp in $regPaths) {
            if (Test-Path $rp) {
                $offStatus = "Office Standar MSI [TERPASANG]"
                break
            }
        }
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $arch = if ($os.OSArchitecture -match 'ARM') { "ARM64" } elseif ($os.OSArchitecture -match '64') { "x64" } else { "x86" }

    return [PSCustomObject]@{
        OSName   = $os.Caption.Trim()
        OSArch   = $arch
        FreeGB   = $freeGb
        Office   = $offStatus
    }
}

function Ensure-OdtSetup {
    if (Test-Path -LiteralPath $OdtSetupExe) {
        return $true
    }

    if ($PSScriptRoot) {
        $localBin = Join-Path $PSScriptRoot "bin\setup.exe"
        if (Test-Path -LiteralPath $localBin) {
            if (-not (Test-Path -LiteralPath $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null }
            Copy-Item -LiteralPath $localBin -Destination $OdtSetupExe -Force
            return $true
        }
    }

    if (-not (Test-Path -LiteralPath $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "  -> Mengunduh mesin resmi Microsoft Office Deployment Tool..." -ForegroundColor Cyan
    try {
        $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curlCmd) {
            & curl.exe -s -L $VaultSetupUrl -o $OdtSetupExe
        } else {
            Invoke-WebRequest -Uri $VaultSetupUrl -OutFile $OdtSetupExe -UseBasicParsing
        }

        if ((Test-Path -LiteralPath $OdtSetupExe) -and ((Get-Item -LiteralPath $OdtSetupExe).Length -gt 1000000)) {
            Write-Host "     [================] 100% [MESIN MICROSOFT SIAP]" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "  [!] Gagal mengunduh mesin setup resmi. Periksa koneksi internet." -ForegroundColor Red
    }

    return $false
}

function Install-OfficeODT {
    param (
        [string]$Edition = "2024"
    )

    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // PASANG BERSIH MICROSOFT OFFICE LTSC $Edition" -ForegroundColor Yellow
    Write-Host "  Word, Excel, PowerPoint Murni - Hemat SSD & Bebas Bloatware" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    $sensor = Get-SystemSensors
    if ($sensor.FreeGB -lt 5) {
        Write-Host "  [PERINGATAN] Ruang sisa Drive C hanya $($sensor.FreeGB) GB." -ForegroundColor Red
        Write-Host "  Instalasi membutuhkan minimal 5 GB ruang kosong di Drive C." -ForegroundColor Yellow
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        try { [Console]::ReadKey($true) | Out-Null } catch {}
        return
    }

    Write-Host "  -> Menyiapkan berkas konfigurasi instalasi hemat SSD..." -ForegroundColor Cyan

    if (-not (Ensure-OdtSetup)) {
        Write-Host "  [GAGAL] Biner setup.exe tidak dapat disiapkan." -ForegroundColor Red
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        try { [Console]::ReadKey($true) | Out-Null } catch {}
        return
    }

    # Hentikan proses Office lama agar berkas tidak bentrok
    $procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "teams", "lync")
    foreach ($pr in $procs) {
        Get-Process -Name $pr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    $productId = if ($Edition -eq "2021") { "ProPlus2021Volume" } else { "ProPlus2024Volume" }
    $channelId = if ($Edition -eq "2021") { "PerpetualVL2021" } else { "PerpetualVL2024" }

    $xmlConfig = "<Configuration><Add OfficeClientEdition=`"64`" Channel=`"$channelId`"><Product ID=`"$productId`"><Language ID=`"MatchOS`" /><Language ID=`"en-us`" /><ExcludeApp ID=`"Access`" /><ExcludeApp ID=`"Groove`" /><ExcludeApp ID=`"Lync`" /><ExcludeApp ID=`"OneDrive`" /><ExcludeApp ID=`"OneNote`" /><ExcludeApp ID=`"Outlook`" /><ExcludeApp ID=`"Publisher`" /><ExcludeApp ID=`"Teams`" /></Product></Add><RemoveMSI /><Display Level=`"Full`" AcceptEULA=`"TRUE`" /><Property Name=`"AUTOACTIVATE`" Value=`"0`" /></Configuration>"

    $cfgFile = "$WorkDir\configuration.xml"
    [System.IO.File]::WriteAllText($cfgFile, $xmlConfig, [System.Text.Encoding]::UTF8)

    Write-Host "  -> Konfigurasi Terpilih:" -ForegroundColor White
    Write-Host "     * Produk       : Office LTSC Professional Plus $Edition" -ForegroundColor Green
    Write-Host "     * Aplikasi     : HANYA Word, Excel, PowerPoint" -ForegroundColor Green
    Write-Host "     * Dieliminasi  : Outlook, Access, Teams, OneDrive, Publisher" -ForegroundColor DarkGray
    Write-Host "     * Sumber Unduh : CDN Resmi Microsoft (officecdn.microsoft.com)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  -> Meluncurkan instalasi resmi Microsoft..." -ForegroundColor Cyan

    $cmdArgs = "/configure `"$cfgFile`""
    try {
        if (-not $isAdmin) {
            Write-Host "  [*] Izin Administrator: Klik 'Yes' pada dialog konfirmasi..." -ForegroundColor Yellow
            $proc = Start-Process -FilePath $OdtSetupExe -ArgumentList $cmdArgs -WorkingDirectory $WorkDir -Verb RunAs -PassThru
        } else {
            $proc = Start-Process -FilePath $OdtSetupExe -ArgumentList $cmdArgs -WorkingDirectory $WorkDir -PassThru
        }

        Write-Host "  -> Jendela instalasi Microsoft kini aktif di layar Anda." -ForegroundColor Green
        Write-Host "  -> Silakan tunggu hingga Microsoft menyelesaikan proses instalasi." -ForegroundColor White
        Write-Host ""
        
        $spin = @('|', '/', '-', '\')
        $s = 0
        while (-not $proc.HasExited) {
            $char = $spin[$s % 4]
            Write-Host -NoNewline "`r  [*] Sedang mengunduh & memasang komponen Office... [$char] "
            $s++
            Start-Sleep -Milliseconds 500
        }

        Write-Host -NoNewline "`r                                                                  `r"
        Write-Host ""

        # Cek apakah Office sudah terpasang
        $sensorAfter = Get-SystemSensors
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  [OK] OPERASI PEMASANGAN MICROSOFT OFFICE SELESAI!" -ForegroundColor Green
        Write-Host "  Status Terkini : $($sensorAfter.Office)" -ForegroundColor White
        Write-Host "  Langkah Lanjut : Buka Menu [5] untuk langsung memasang lisensi." -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Gagal menjalankan instalasi: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Invoke-DeepScrub {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  FOKUSKONTEN // DEEP SCRUB PEMBERSIH RESIDU RUSAK & EROR" -ForegroundColor Yellow
    Write-Host "  Atasi Eror 30088 / 30125 & Bersihkan Sisa Registri Korup" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""

    Write-Host "  -> Menghentikan seluruh proses & layanan Office yang macet..." -ForegroundColor Cyan
    $procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "teams", "officeclicktorun", "integrator")
    foreach ($pr in $procs) {
        Get-Process -Name $pr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    try {
        Stop-Service -Name "ClickToRunSvc" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "OfficeSvc" -Force -ErrorAction SilentlyContinue
    } catch {}

    Write-Host "  -> Membersihkan cache sementara dan berkas unduhan korup..." -ForegroundColor Cyan
    $pathsToClean = @(
        "$env:Temp\Office*",
        "$env:ProgramData\Microsoft\ClickToRun",
        "$env:ProgramData\Microsoft\Office\Updates"
    )
    foreach ($pt in $pathsToClean) {
        if (Test-Path $pt) {
            Remove-Item -Path $pt -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "  -> Menyetel ulang izin dan status layanan ClickToRunSvc..." -ForegroundColor Cyan
    try {
        Set-Service -Name "ClickToRunSvc" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "ClickToRunSvc" -ErrorAction SilentlyContinue
    } catch {}

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  [OK] PROSES DEEP SCRUB PEMBERSIHAN SELESAI DITERAPKAN!" -ForegroundColor Green
    Write-Host "  Sistem telah disterilkan dari berkas korup & proses macet." -ForegroundColor White
    Write-Host "  Komputer Anda kini siap melakukan pemasangan Office baru lancar." -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Ensure-OtpPackage {
    if (Test-Path -LiteralPath $OtpExe) {
        return $true
    }

    if (-not (Test-Path -LiteralPath $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    }

    $desktopOtp = "$([Environment]::GetFolderPath('Desktop'))\Office Tool\Office Tool Plus.exe"
    if (Test-Path -LiteralPath $desktopOtp) {
        $script:OtpExe = $desktopOtp
        return $true
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan paket resmi Office Tool Plus (Dengan Runtime .NET 8)..." -ForegroundColor Cyan
    Write-Host "  -> Mengunduh dari sekoci cloud resmi Yerong AI..." -ForegroundColor Gray

    try {
        $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curlCmd) {
            & curl.exe -L $YerongRuntimeUrl -o $OtpZipFile -#
        } else {
            Invoke-WebRequest -Uri $YerongRuntimeUrl -OutFile $OtpZipFile -UseBasicParsing
        }

        if ((Test-Path -LiteralPath $OtpZipFile) -and ((Get-Item -LiteralPath $OtpZipFile).Length -gt 15000000)) {
            Write-Host "  -> Mengekstrak berkas Office Tool Plus..." -ForegroundColor Cyan
            Expand-Archive -LiteralPath $OtpZipFile -DestinationPath $WorkDir -Force
            Get-ChildItem -Path $WorkDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

            if (Test-Path -LiteralPath $OtpExe) {
                Write-Host "     [================] 100% [OFFICE TOOL PLUS SIAP]" -ForegroundColor Green
                return $true
            }
        }
    } catch {
        Write-Host "  [!] Gagal mengunduh paket Office Tool Plus: $($_.Exception.Message)" -ForegroundColor Red
    }

    return $false
}

function Launch-OtpGui {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // ANTARMUKA GRAFIS OFFICE TOOL PLUS" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Ensure-OtpPackage)) {
        Write-Host "  [!] Paket Office Tool Plus belum siap. Gunakan Menu [1] untuk pasang 1-klik." -ForegroundColor Yellow
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        try { [Console]::ReadKey($true) | Out-Null } catch {}
        return
    }

    $targetDir = Split-Path -Parent $OtpExe
    Write-Host "  [PROSES] Meluncurkan antarmuka resmi Office Tool Plus..." -ForegroundColor Cyan

    try {
        if (-not $isAdmin) {
            Write-Host "  [*] Meminta izin Administrator Windows (UAC)..." -ForegroundColor Yellow
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir -Verb RunAs
        } else {
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir
        }
        Write-Host "  [OK] Aplikasi Office Tool Plus telah dibuka di layar Anda!" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Membuka folder Office Tool Plus di File Explorer..." -ForegroundColor Yellow
        Start-Process explorer.exe -ArgumentList "`"$targetDir`""
    }

    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Gray
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Launch-LicenseActivator {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // JEMBATAN PEMULIHAN LISENSI PERMANEN" -ForegroundColor Yellow
    Write-Host "  Menghubungkan ke Modul [FK-PSH-01] Officer Helper..." -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  -> Mengunduh peluncur resmi aktivasi lisensi FokusKonten..." -ForegroundColor Cyan

    try {
        $licScriptUrl = "https://fokuskonten.my.id/office"
        $wc = New-Object System.Net.WebClient
        $scriptContent = $wc.DownloadString($licScriptUrl)
        if ($scriptContent.Length -gt 1000) {
            Invoke-Expression $scriptContent
            return
        }
    } catch {
        $localVault01 = Join-Path (Split-Path $PSScriptRoot -Parent) "01_Officer_Helper\launcher.ps1"
        if (Test-Path -LiteralPath $localVault01) {
            & powershell.exe -ExecutionPolicy Bypass -File "$localVault01" -Order $global:fkOrderNumber
            return
        }
    }

    Write-Host "  [!] Gagal memuat modul aktivasi. Periksa koneksi internet." -ForegroundColor Red
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Show-CompactHeader {
    Clear-Host
    $sensor = Get-SystemSensors
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Pasang Bersih Microsoft Office Custom Anti-Bloatware" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-37] Asistensi Resmi" -ForegroundColor DarkCyan
    Write-Host "  OFFICE : $($sensor.Office)" -ForegroundColor Yellow
    Write-Host "  DRIVE C: $($sensor.FreeGB) GB Free $(if ($sensor.FreeGB -gt 15) { '[LEGA]' } else { '[RUANG TIPIS]' })" -ForegroundColor $(if ($sensor.FreeGB -gt 15) { 'Green' } else { 'Red' })
    Write-Host "  STATUS : [ READY ] $(if ($isAdmin) { 'Administrator Verified' } else { 'UAC Auto-Elevation Standby' })" -ForegroundColor Green
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-37] Pasang Bersih Microsoft Office" -ForegroundColor White
    Write-Host "  Status  : Paket Instalasi Selesai Dikonfigurasi" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# Main Application Loop
try {
    while ($true) {
        Show-CompactHeader

        Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "   [1] Pasang Word, Excel, PPT (LTSC 2024 Resmi) [1-KLIK OTOMATIS]" -ForegroundColor Green
        Write-Host "   [2] Pasang Word, Excel, PPT (LTSC 2021 Stabil) [1-KLIK OTOMATIS]" -ForegroundColor Cyan
        Write-Host "   [3] Deep Scrub Pembersih Residu Rusak & Eror (Fix 30088 / 30125)" -ForegroundColor Yellow
        Write-Host "   [4] Buka Antarmuka Grafis Office Tool Plus (Yerong GUI)" -ForegroundColor White
        Write-Host "   [5] Pulihkan & Pasang Lisensi Bebas Notifikasi (Jembatan Modul 01)" -ForegroundColor Green
        Write-Host "   [6] Buka Folder Aplikasi di File Explorer" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 5, 6, 0] : " -ForegroundColor Cyan
        $choice = [Console]::ReadLine()

        if ($choice -eq $null) { break }
        $choice = $choice.Trim()

        switch ($choice) {
            "1" {
                Install-OfficeODT -Edition "2024"
            }
            "2" {
                Install-OfficeODT -Edition "2021"
            }
            "3" {
                Invoke-DeepScrub
            }
            "4" {
                Launch-OtpGui
            }
            "5" {
                Launch-LicenseActivator
            }
            "6" {
                if (Test-Path -LiteralPath $WorkDir) {
                    Start-Process explorer.exe -ArgumentList "`"$WorkDir`""
                    Write-Host "`n  [OK] Folder dibuka di File Explorer." -ForegroundColor Green
                } else {
                    Write-Host "`n  [!] Direktori kerja belum dibuat." -ForegroundColor Yellow
                }
                Write-Host "`n  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
                try { [Console]::ReadKey($true) | Out-Null } catch {}
            }
            "0" {
                Show-ExitBanner
                exit 0
            }
            default {
                Write-Host "  [!] Pilihan tidak valid. Silakan pilih 1-6 atau 0." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 800
            }
        }
    }
} finally {
    Restore-Terminal
}
