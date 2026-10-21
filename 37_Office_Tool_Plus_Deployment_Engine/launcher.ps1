# ================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul [FK-PSH-37] : OFFICE TOOL PLUS & CUSTOM DEPLOYMENT SUITE
# Engine            : Official Office Tool Plus Engine (Yerong)
# Standard          : Ultra-Compact Golden 64 Layout // In-Place Terminal
# ================================================================
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // OFFICE TOOL PLUS RESCUE SUITE"
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
$OtpZipFile = "$WorkDir\Office_Tool_Plus.zip"
$OtpExe     = "$WorkDir\Office Tool\Office Tool Plus.exe"

# URL CDN Resmi FokusKonten (Sekoci Vault Mandiri) & Fallback Upstream (Yerong)
$OtpVersion  = "10.30.43.0"
$VaultCdnUrl = "https://github.com/mcjobs-id/powershell-vault/releases/download/v1.0.0/otp_engine.zip"
$OtpUrl_x64  = "https://github.com/YerongAI/Office-Tool/releases/download/v$OtpVersion/Office_Tool_v${OtpVersion}_x64.zip"
$OtpUrl_arm  = "https://github.com/YerongAI/Office-Tool/releases/download/v$OtpVersion/Office_Tool_v${OtpVersion}_arm64.zip"

function Get-SystemSensors {
    $cDrive = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq 'C:' }
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

    $os = Get-CimInstance Win32_OperatingSystem
    $arch = if ($os.OSArchitecture -match 'ARM') { "ARM64" } elseif ($os.OSArchitecture -match '64') { "x64" } else { "x86" }

    return [PSCustomObject]@{
        OSName   = $os.Caption.Trim()
        OSArch   = $arch
        FreeGB   = $freeGb
        Office   = $offStatus
    }
}

function Ensure-OtpPackage {
    if (Test-Path -LiteralPath $OtpExe) {
        return $true
    }

    if (-not (Test-Path -LiteralPath $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    }

    # Cek apakah ada di folder lokal atau Desktop
    $desktopOtp = "$([Environment]::GetFolderPath('Desktop'))\Office Tool\Office Tool Plus.exe"
    if (Test-Path -LiteralPath $desktopOtp) {
        $script:OtpExe = $desktopOtp
        return $true
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan paket resmi Office Tool Plus v$OtpVersion..." -ForegroundColor Cyan

    $sensor = Get-SystemSensors
    $targetFallbackUrl = if ($sensor.OSArch -eq "ARM64") { $OtpUrl_arm } else { $OtpUrl_x64 }
    $downloadUrls = @($VaultCdnUrl, $targetFallbackUrl)

    try {
        if (-not (Test-Path -LiteralPath $OtpZipFile) -or ((Get-Item -LiteralPath $OtpZipFile).Length -lt 5000000)) {
            $downloaded = $false
            foreach ($url in $downloadUrls) {
                Write-Host "  -> Mengunduh dari sekoci cloud: $url..." -ForegroundColor Gray
                try {
                    $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
                    if ($curlCmd) {
                        & curl.exe -L $url -o $OtpZipFile -#
                    } else {
                        Invoke-WebRequest -Uri $url -OutFile $OtpZipFile -UseBasicParsing
                    }
                    if ((Test-Path -LiteralPath $OtpZipFile) -and ((Get-Item -LiteralPath $OtpZipFile).Length -gt 5000000)) {
                        $downloaded = $true
                        break
                    }
                } catch {
                    Write-Host "  [!] Jalur unduhan sibuk, beralih ke sekoci cadangan..." -ForegroundColor Yellow
                }
            }

            if (-not $downloaded) {
                Write-Host "  [!] Seluruh sumber unduhan gagal dijangkau. Periksa koneksi internet." -ForegroundColor Red
                return $false
            }
        }

        Write-Host "  -> Mengekstrak berkas Office Tool Plus..." -ForegroundColor Cyan
        Expand-Archive -LiteralPath $OtpZipFile -DestinationPath $WorkDir -Force

        # Buka blokir Mark of the Web
        Get-ChildItem -Path $WorkDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

        if (Test-Path -LiteralPath $OtpExe) {
            Write-Host "     [================] 100% [OFFICE TOOL PLUS SIAP]" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  [!] Berkas Office Tool Plus.exe tidak ditemukan setelah ekstraksi." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  [!] Gagal menyiapkan Office Tool Plus: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Launch-OtpGui {
    if (-not (Ensure-OtpPackage)) { return }

    $targetDir = Split-Path -Parent $OtpExe
    Write-Host ""
    Write-Host "  -> Meluncurkan antarmuka grafis resmi Office Tool Plus..." -ForegroundColor Cyan

    try {
        if (-not $isAdmin) {
            Write-Host " [*] Meminta izin Administrator Windows (UAC) untuk akses penuh..." -ForegroundColor Yellow
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir -Verb RunAs
        } else {
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir
        }
        Write-Host "  [OK] Aplikasi Office Tool Plus telah diluncurkan di layar Anda!" -ForegroundColor Green
        Write-Host "       Silakan periksa taskbar Windows Anda jika jendela berada di belakang." -ForegroundColor Gray
    } catch {
        Write-Host "  [!] Membuka folder Office Tool Plus di File Explorer..." -ForegroundColor Yellow
        Start-Process explorer.exe -ArgumentList "`"$targetDir`""
    }
}

function Show-GuideInstallClean {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " PANDUAN CEPAT: PASANG HANYA WORD, EXCEL & PPT (HEMAT SSD 70%)  " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1. Pada antarmuka Office Tool Plus, klik menu 'Deploy' /       " -ForegroundColor White
    Write-Host "    'Pemasangan' di bilah navigasi sebelah kiri.                " -ForegroundColor White
    Write-Host ""
    Write-Host " 2. Pada kolom 'Produk', klik 'Tambahkan Produk':               " -ForegroundColor White
    Write-Host "    Pilih 'Office LTSC Professional Plus 2024' (atau 2021/365). " -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 3. Pada daftar aplikasi di bawahnya (Anti-Bloatware):          " -ForegroundColor White
    Write-Host "    * Tetap CENTANG : Word, Excel, PowerPoint.                  " -ForegroundColor Green
    Write-Host "    * HAPUS CENTANG : Access, Outlook, OneNote, Teams, OneDrive " -ForegroundColor Red
    Write-Host ""
    Write-Host " 4. Pilih Bahasa: 'id-id' (Indonesia) atau 'en-us' (English).   " -ForegroundColor White
    Write-Host ""
    Write-Host " 5. Klik tombol 'Mulai Pemasangan' di sudut kanan atas!         " -ForegroundColor Yellow
    Write-Host "    Proses unduh & pasang resmi Microsoft akan berjalan lancar. " -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Show-GuideScrub {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host " PANDUAN DEEP SCRUB: BERSIHKAN RESIDU OFFICE KORUP (ANTI EROR)  " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host " Jika Anda mengalami eror gagal pasang (30088-26 atau 30125-1011)" -ForegroundColor White
    Write-Host " akibat sisa-sisa Office lama yang rusak, ikuti langkah ini:    " -ForegroundColor White
    Write-Host ""
    Write-Host " 1. Pada aplikasi Office Tool Plus, klik menu 'Kotak Alat' /    " -ForegroundColor White
    Write-Host "    'Toolbox' di bilah navigasi sebelah kiri.                   " -ForegroundColor White
    Write-Host ""
    Write-Host " 2. Cari bagian 'Copot Pemasangan Office' (Scrub Office).       " -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 3. Klik tombol 'Hapus Instalasi' / 'Uninstall'.                " -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 4. Biarkan sistem membersihkan seluruh registri korup, service " -ForegroundColor White
    Write-Host "    macet, dan cache berkas lama hingga 100% bersih ke akar.    " -ForegroundColor White
    Write-Host ""
    Write-Host " 5. Setelah selesai, komputer siap dipasang Office baru lancar! " -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Red
}

function Show-Header {
    $sensor = Get-SystemSensors
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " FOKUSKONTEN // OFFICE TOOL PLUS & CUSTOM DEPLOYMENT SUITE      " -ForegroundColor White
    Write-Host " Kustomisasi Komponen Office, Anti-Bloatware & Deep Scrub       " -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " TIKET ORDER   : " -NoNewline -ForegroundColor Gray
    Write-Host "$($global:fkOrderNumber)" -ForegroundColor Yellow
    Write-Host " SISTEM OPERASI: " -NoNewline -ForegroundColor Gray
    Write-Host "$($sensor.OSName) ($($sensor.OSArch))" -ForegroundColor White
    Write-Host " STATUS OFFICE : " -NoNewline -ForegroundColor Gray
    Write-Host "$($sensor.Office)" -ForegroundColor Yellow
    Write-Host " DRIVE C: SISA : " -NoNewline -ForegroundColor Gray
    if ($sensor.FreeGB -gt 15) {
        Write-Host "$($sensor.FreeGB) GB Tersedia [SANGAT CUKUP]" -ForegroundColor Green
    } else {
        Write-Host "$($sensor.FreeGB) GB Tersedia [PERHATIAN: RUANG TERSISA SEDIKIT]" -ForegroundColor Red
    }
    Write-Host " MESIN RESMI   : " -NoNewline -ForegroundColor Gray
    Write-Host "Office Tool Plus v$OtpVersion (Built-in Yerong Engine)" -ForegroundColor White
    Write-Host " HAK AKSES     : " -NoNewline -ForegroundColor Gray
    if ($isAdmin) {
        Write-Host "ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "User Standar [UAC Elevasi Otomatis Siaga]" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host "   [1] Buka / Unduh Office Tool Plus Resmi (1-Klik GUI Lengkap) " -ForegroundColor Green
    Write-Host "   [2] Panduan 3 Langkah Pasang Word & Excel Saja (Hemat SSD 70%)" -ForegroundColor Cyan
    Write-Host "   [3] Panduan Deep Scrub Bersihkan Sisa Office Rusak / Eror    " -ForegroundColor Yellow
    Write-Host "   [4] Buka Folder Aplikasi Office Tool Plus di File Explorer   " -ForegroundColor White
    Write-Host "   [0] Selesai & Keluar                                         " -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

# Main Application Loop
try {
    while ($true) {
        Show-Header
        Write-Host -NoNewline " Pilihan Anda [1, 2, 3, 4, 0] : " -ForegroundColor Green
        $choice = (Read-Host).Trim()

        switch ($choice) {
            "1" { Launch-OtpGui }
            "2" { Show-GuideInstallClean }
            "3" { Show-GuideScrub }
            "4" {
                if (Test-Path -LiteralPath $WorkDir) {
                    Start-Process explorer.exe -ArgumentList "`"$WorkDir`""
                    Write-Host "`n [OK] Folder Office Tool Plus dibuka di File Explorer." -ForegroundColor Green
                } else {
                    Write-Host "`n [!] Aplikasi belum diunduh. Silakan pilih menu [1] terlebih dahulu." -ForegroundColor Yellow
                }
            }
            "0" {
                Write-Host "`n Terima kasih telah menggunakan layanan resmi FokusKonten.`n" -ForegroundColor Green
                Restore-Terminal
                exit 0
            }
            default {
                Write-Host " Pilihan tidak valid." -ForegroundColor Yellow
            }
        }

        Write-Host "`n Tekan Enter untuk kembali ke menu utama..." -ForegroundColor White
        Read-Host | Out-Null
    }
} finally {
    Restore-Terminal
}
