# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : JASA PASANG & KUSTOMISASI KOMPONEN OFFICE TOOL PLUS
# Modul SKU    : FK-PSH-37 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Single Terminal Execution (Zero Pop-Up Spam)
# Engine       : Yerong Official OTP Engine v10.30 & Dual-Tier Cloud Release CDN
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
    Write-Host "  [PROSES] Meluncurkan antarmuka resmi Office Tool Plus..." -ForegroundColor Cyan

    try {
        if (-not $isAdmin) {
            Write-Host "  [*] Meminta izin Administrator Windows (UAC)..." -ForegroundColor Yellow
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir -Verb RunAs
        } else {
            Start-Process -FilePath $OtpExe -WorkingDirectory $targetDir
        }
        Write-Host "  [OK] Aplikasi Office Tool Plus telah dibuka!" -ForegroundColor Green
        Write-Host "       Periksa taskbar jika jendela berada di belakang." -ForegroundColor Gray
    } catch {
        Write-Host "  [!] Membuka folder Office Tool Plus di File Explorer..." -ForegroundColor Yellow
        Start-Process explorer.exe -ArgumentList "`"$targetDir`""
    }
}

function Show-GuideInstallClean {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  PANDUAN HEMAT SSD 70%" -ForegroundColor Yellow
    Write-Host "  Pasang Khusus Word, Excel & PPT Tanpa Bloatware" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Pada aplikasi Office Tool Plus, klik menu 'Deploy' /" -ForegroundColor White
    Write-Host "     'Pemasangan' di bilah navigasi sebelah kiri." -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Klik 'Tambahkan Produk':" -ForegroundColor White
    Write-Host "     Pilih 'Office LTSC Professional Plus 2024' (atau 2021/365)." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Pada daftar aplikasi di bawahnya (Anti-Bloatware):" -ForegroundColor White
    Write-Host "     * Centang HANYA : Word, Excel, PowerPoint." -ForegroundColor Green
    Write-Host "     * HAPUS CENTANG : Access, Outlook, OneNote, Teams, OneDrive." -ForegroundColor Red
    Write-Host ""
    Write-Host "  4. Pilih Bahasa: 'id-id' (Indonesia) atau 'en-us' (English)." -ForegroundColor White
    Write-Host ""
    Write-Host "  5. Klik tombol 'Mulai Pemasangan' di sudut kanan atas!" -ForegroundColor Yellow
    Write-Host "     Paket resmi ditarik langsung dari CDN resmi Microsoft." -ForegroundColor Gray
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
}

function Show-GuideScrub {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  F O K U S K O N T E N  //  DEEP SCRUB ANTI-EROR" -ForegroundColor Yellow
    Write-Host "  Bersihkan Residu Rusak & Atasi Eror 30088 / 30125" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Jika instalasi macet karena sisa berkas registri korup:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Pada aplikasi Office Tool Plus, klik menu 'Kotak Alat' /" -ForegroundColor White
    Write-Host "     'Toolbox' di bilah navigasi sebelah kiri." -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Buka menu 'Copot Pemasangan Office' (Scrub Office)." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Klik tombol 'Hapus Instalasi' / 'Uninstall'." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  4. Sistem membersihkan registri korup & service macet ke akar." -ForegroundColor White
    Write-Host ""
    Write-Host "  5. Setelah selesai, komputer siap dipasang Office baru lancar!" -ForegroundColor Green
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
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
    Write-Host "  ENGINE : Office Tool Plus v$OtpVersion (Yerong Official Engine)" -ForegroundColor Cyan
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
    Write-Host "  Status  : Office Tool Plus Resmi Siap Digunakan" -ForegroundColor Cyan
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
        Write-Host "   [1] Buka / Unduh Office Tool Plus Resmi (1-Klik GUI)" -ForegroundColor Green
        Write-Host "   [2] Panduan 3 Langkah Pasang Word & Excel (Hemat SSD 70%)" -ForegroundColor Cyan
        Write-Host "   [3] Panduan Deep Scrub Pembersih Residu Rusak & Eror" -ForegroundColor Yellow
        Write-Host "   [4] Buka Folder Aplikasi di File Explorer" -ForegroundColor White
        Write-Host ""
        Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 0] : " -ForegroundColor Cyan
        $choice = [Console]::ReadLine()

        if ($choice -eq $null) { break }
        $choice = $choice.Trim()

        switch ($choice) {
            "1" {
                Launch-OtpGui
                Write-Host "`n  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
                try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
            }
            "2" {
                Show-GuideInstallClean
            }
            "3" {
                Show-GuideScrub
            }
            "4" {
                if (Test-Path -LiteralPath $WorkDir) {
                    Start-Process explorer.exe -ArgumentList "`"$WorkDir`""
                    Write-Host "`n  [OK] Folder Office Tool Plus dibuka di File Explorer." -ForegroundColor Green
                } else {
                    Write-Host "`n  [!] Aplikasi belum diunduh. Silakan pilih menu [1] terlebih dahulu." -ForegroundColor Yellow
                }
                Write-Host "`n  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
                try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
            }
            "0" {
                Show-ExitBanner
                exit 0
            }
            default {
                Write-Host "  [!] Pilihan tidak valid." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 800
            }
        }
    }
} finally {
    Restore-Terminal
}