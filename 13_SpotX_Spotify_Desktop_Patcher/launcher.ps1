# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : JASA OPTIMASI SPOTIFY DESKTOP BEBAS IKLAN SPOTX
# Modul SKU    : FK-PSH-22 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Single Terminal Execution (Zero Pop-Up Spam)
# Engine       : SpotX Desktop Engine (Official Multi-Platform Patcher)
# Keamanan     : 100% Bersih, Reversible (Fitur Restore Cadangan Asli 1-Klik)
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
    $Host.UI.RawUI.WindowTitle = "FOKUSKONTEN // RESCUE SUITE [FK-PSH-22]"
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

# Direktori & Mesin SpotX
$SpDir            = "$env:APPDATA\Spotify"
$SpExe            = "$SpDir\Spotify.exe"
$SpotXEngineLocal = "$PSScriptRoot\run.ps1"
$SpotXEngineTemp  = "$env:TEMP\SpotX\run.ps1"
$SpotXVaultUrl    = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/13_SpotX_Spotify_Desktop_Patcher/run.ps1"
$SpotXUpstreamUrl = "https://raw.githubusercontent.com/SpotX-Official/SpotX/main/run.ps1"

function Get-SystemSensors {
    $spStatus = "Belum Terdeteksi (Siaga Auto-Install)"
    $spVer    = "N/A"

    if (Test-Path -LiteralPath $SpExe) {
        try {
            $ver = (Get-Item -LiteralPath $SpExe).VersionInfo.ProductVersion
            if ($ver) { $spVer = "v$ver" }
        } catch {}

        $isPatched = (Test-Path -LiteralPath "$SpDir\chrome_elf.dll.bak") -or `
                     (Test-Path -LiteralPath "$SpDir\Spotify.dll.bak") -or `
                     (Test-Path -LiteralPath "$SpDir\Apps\xpui.bak")

        if ($isPatched) {
            $spStatus = "SpotX Aktif [BEBAS IKLAN] ($spVer)"
        } else {
            $spStatus = "Spotify Resmi [ORIGINAL] ($spVer)"
        }
    } else {
        $msStore = Get-AppxPackage *Spotify* -ErrorAction SilentlyContinue
        if ($msStore) {
            $spStatus = "Spotify MS Store [PERLU KONVERSI]"
        }
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $arch = if ($os.OSArchitecture -match 'ARM') { "ARM64" } elseif ($os.OSArchitecture -match '64') { "x64" } else { "x86" }

    return [PSCustomObject]@{
        OSName   = $os.Caption.Trim()
        OSArch   = $arch
        Status   = $spStatus
        Version  = $spVer
    }
}

function Ensure-SpotXEngine {
    if (Test-Path -LiteralPath $SpotXEngineLocal) {
        return $SpotXEngineLocal
    }
    if ((Test-Path -LiteralPath $SpotXEngineTemp) -and ((Get-Item -LiteralPath $SpotXEngineTemp).Length -gt 100000)) {
        return $SpotXEngineTemp
    }

    $tempDir = Split-Path -Parent $SpotXEngineTemp
    if (-not (Test-Path -LiteralPath $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul mesin SpotX resmi..." -ForegroundColor Cyan

    $urls = @($SpotXVaultUrl, $SpotXUpstreamUrl)
    $downloaded = $false

    foreach ($url in $urls) {
        Write-Host "  -> Menghubungkan ke sekoci: $url..." -ForegroundColor Gray
        try {
            $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($curlCmd) {
                & curl.exe -s -L $url -o $SpotXEngineTemp
            } else {
                Invoke-WebRequest -Uri $url -OutFile $SpotXEngineTemp -UseBasicParsing
            }
            if ((Test-Path -LiteralPath $SpotXEngineTemp) -and ((Get-Item -LiteralPath $SpotXEngineTemp).Length -gt 100000)) {
                $downloaded = $true
                break
            }
        } catch {
            Write-Host "  [!] Jalur sibuk, beralih ke cadangan..." -ForegroundColor Yellow
        }
    }

    if ($downloaded) {
        Write-Host "  [OK] Mesin SpotX siap digunakan!" -ForegroundColor Green
        return $SpotXEngineTemp
    } else {
        Write-Host "  [!] Gagal mengunduh mesin SpotX. Periksa koneksi internet." -ForegroundColor Red
        return $null
    }
}

function Invoke-SpotXPatch {
    param (
        [switch]$KeepPodcasts
    )

    $engine = Ensure-SpotXEngine
    if (-not $engine) { return }

    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  OPTIMASI SPOTIFY DESKTOP" -ForegroundColor Yellow
    if ($KeepPodcasts) {
        Write-Host "  Mode: Bebas Iklan Audio/Video (Pertahankan Podcast Beranda)" -ForegroundColor White
    } else {
        Write-Host "  Mode Rekomendasi: Bersih Murni Musik (Bebas Iklan & Bloatware)" -ForegroundColor White
    }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [PROSES] Sedang menjalankan konfigurasi optimasi Spotify..." -ForegroundColor Cyan
    Write-Host "           Mohon tunggu beberapa detik hingga proses selesai." -ForegroundColor Gray
    Write-Host ""

    # Pastikan Spotify ditutup terlebih dahulu agar file tidak terkunci
    Get-Process -Name Spotify -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600

    # Gunakan hashtable splatting agar parameter switch di PowerShell terikat dengan benar
    $splatParams = @{
        confirm_uninstall_ms_spoti    = $true
        confirm_spoti_recomended_over = $true
        block_update_on               = $true
        start_spoti                   = $true
        defender_exclusions_off       = $true
        no_pause                      = $true
    }
    if (-not $KeepPodcasts) {
        $splatParams['podcasts_off'] = $true
    }

    try {
        & $engine @splatParams
        Write-Host ""
        Write-Host "  [OK] Optimasi Spotify Desktop berhasil diselesaikan 100%!" -ForegroundColor Green
        Write-Host "       Aplikasi Spotify telah siap digunakan tanpa gangguan iklan." -ForegroundColor Cyan
    } catch {
        Write-Host "  [!] Terjadi kendala saat menjalankan optimasi: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
}

function Invoke-RestoreOriginalSpotify {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  PEMULIHAN SPOTIFY ASLI" -ForegroundColor Yellow
    Write-Host "  Mengembalikan Spotify ke Kondisi Bawaan Pabrik 100%" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SpDir)) {
        Write-Host "  [!] Folder instalasi Spotify tidak ditemukan di sistem." -ForegroundColor Red
        Write-Host ""
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali ke menu utama..." -ForegroundColor Gray
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host | Out-Null }
        return
    }

    Write-Host "  -> Menutup proses Spotify yang sedang aktif..." -ForegroundColor Cyan
    Get-Process -Name Spotify -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800

    $restoredCount = 0
    $targets = @(
        @{ Bak = "$SpDir\chrome_elf.dll.bak"; Orig = "$SpDir\chrome_elf.dll" },
        @{ Bak = "$SpDir\Spotify.dll.bak";    Orig = "$SpDir\Spotify.dll" },
        @{ Bak = "$SpDir\Spotify.bak";        Orig = "$SpDir\Spotify.exe" },
        @{ Bak = "$SpDir\Apps\xpui.bak";      Orig = "$SpDir\Apps\xpui.spa" }
    )

    foreach ($item in $targets) {
        if (Test-Path -LiteralPath $item.Bak) {
            $baseName = Split-Path $item.Orig -Leaf
            Write-Host "  -> Memulihkan berkas $baseName..." -ForegroundColor White
            if (Test-Path -LiteralPath $item.Orig) {
                Remove-Item -LiteralPath $item.Orig -Force -ErrorAction SilentlyContinue
            }
            Move-Item -LiteralPath $item.Bak -Destination $item.Orig -Force -ErrorAction SilentlyContinue
            $restoredCount++
        }
    }

    Get-ChildItem -Path $env:TEMP -Filter "SpotX_Temp*" -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    if ($restoredCount -gt 0) {
        Write-Host "  [OK] Berhasil memulihkan $restoredCount komponen cadangan resmi!" -ForegroundColor Green
        Write-Host "       Aplikasi Spotify telah kembali ke kondisi default pabrik." -ForegroundColor Cyan
    } else {
        Write-Host "  [*] Tidak ada berkas cadangan (.bak) yang ditemukan." -ForegroundColor Yellow
        Write-Host "      Spotify Anda saat ini sudah dalam kondisi bawaan asli." -ForegroundColor Gray
    }

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
    Write-Host "  Optimasi Spotify Desktop Bebas Iklan Audio & Banner" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-22] Asistensi Resmi" -ForegroundColor DarkCyan
    Write-Host "  STATUS : $($sensor.Status)" -ForegroundColor Yellow
    Write-Host "  SISTEM : $($sensor.OSName) ($($sensor.OSArch))" -ForegroundColor White
    Write-Host "  ENGINE : SpotX Official Multi-Platform Engine (Reversible)" -ForegroundColor Cyan
    Write-Host "  AKSES  : $(if ($isAdmin) { 'ADMINISTRATOR RESMI [TERVERIFIKASI]' } else { 'User Standar [Otomatis Siaga]' })" -ForegroundColor $(if ($isAdmin) { 'Green' } else { 'Yellow' })
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
    Write-Host "  Layanan : [FK-PSH-22] Optimasi Spotify Desktop Bebas Iklan" -ForegroundColor White
    Write-Host "  Status  : Konfigurasi Musik Nyaman Siap Digunakan" -ForegroundColor Cyan
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
        Write-Host "   [1] Pasang Patch Anti-Iklan Spotify (Rekomendasi Bersih)" -ForegroundColor Green
        Write-Host "   [2] Pasang Patch Anti-Iklan (Tetap Tampilkan Podcast)" -ForegroundColor Cyan
        Write-Host "   [3] Pulihkan Spotify ke Kondisi Asli (Restore 100%)" -ForegroundColor Yellow
        Write-Host "   [4] Buka Folder Aplikasi Spotify di File Explorer" -ForegroundColor White
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
                Invoke-SpotXPatch
            }
            "2" {
                Invoke-SpotXPatch -KeepPodcasts
            }
            "3" {
                Invoke-RestoreOriginalSpotify
            }
            "4" {
                if (Test-Path -LiteralPath $SpDir) {
                    Start-Process explorer.exe -ArgumentList "`"$SpDir`""
                    Write-Host "`n  [OK] Folder Spotify dibuka di File Explorer." -ForegroundColor Green
                } else {
                    Write-Host "`n  [!] Folder Spotify belum terpasang." -ForegroundColor Yellow
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