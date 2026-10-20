# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : PERBAIKAN WINDOWS WATERMARK & LISENSI KADALUARSA (HWID)
# Modul SKU    : FK-PSH-02 (Microsoft Helper Suite)
# Desain       : Ultra-Compact Golden Layout (100% Single Terminal In-Place)
# Engine Inti  : Hardware ID Ticket Registration (ClipSVC Permanent License)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // MICROSOFT HELPER - LISENSI WINDOWS HWID"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$isAdmin = $false
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Get-WindowsLicenseState {
    try {
        $lic = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey is not null" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*Windows*" -and $_.LicenseStatus -eq 1 } | Select-Object -First 1
        if ($lic) {
            return "LICENSED"
        }
    } catch {
        try {
            $wmi = Get-WmiObject -Class SoftwareLicensingProduct -Filter "PartialProductKey is not null" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*Windows*" -and $_.LicenseStatus -eq 1 } | Select-Object -First 1
            if ($wmi) { return "LICENSED" }
        } catch {}
    }
    return "UNLICENSED"
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path -LiteralPath $localCmd) { return $localCmd }
    }

    $workDir = Join-Path $env:ProgramData "FokusKonten"
    if (-not (Test-Path -LiteralPath $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }
    $cached = Join-Path $workDir "FK_Core_Runtime_v3.cmd"
    if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
        return $cached
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul pemulihan lisensi resmi FokusKonten..." -ForegroundColor Cyan
    $primaryUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/02_Microsoft_Helper/MAS_AIO.cmd"
    $fallbackUrl = "https://fokuskonten.my.id/assets/engine/FK_Engine_Core.cmd"

    try {
        $wc = New-Object System.Net.WebClient
        $rawText = $wc.DownloadString($primaryUrl)
        if ($rawText.Length -gt 50000) {
            $crlfText = $rawText -replace "(?<!`r)`n", "`r`n"
            [System.IO.File]::WriteAllText($cached, $crlfText, [System.Text.Encoding]::ASCII)
            Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
            return $cached
        }
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($fallbackUrl, $cached)
            if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
                Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
                return $cached
            }
        } catch {}
    }

    return $cached
}

function Show-Header {
    Clear-Host
    $state = Get-WindowsLicenseState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Microsoft Helper: Lisensi Digital Windows (HWID)" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-02] Asistensi Resmi" -ForegroundColor DarkCyan

    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: DIGITAL HWID PERMANEN ] (Bebas Watermark)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ WATERMARK AKTIF / PERLU PENDAFTARAN LISENSI ]" -ForegroundColor Yellow
    }

    if ($isAdmin) {
        Write-Host "  AKSES  : [ ADMINISTRATOR RESMI ] (Siap Eksekusi 1 Terminal)" -ForegroundColor Green
    } else {
        Write-Host "  AKSES  : [ USER STANDAR ] (Mode In-Place 1 Terminal)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkCyan
}

function Invoke-Action {
    Clear-Host
    $engine = Get-EnginePath
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // PENDAFTARAN LISENSI DIGITAL WINDOWS HWID" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Eksekusi background 1 Terminal Mutlak (Zero Window Popup & Zero Terminal Clutter)
    $arg = "/c `"`"$engine`" /hwid -qedit -el`""
    if ($isAdmin) {
        Write-Host "  -> Mendaftarkan tiket lisensi HWID di latar belakang..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Wait -WindowStyle Hidden -PassThru
    } else {
        Write-Host "  -> Izin Sistem: Klik 'Yes' pada dialog konfirmasi Windows..." -ForegroundColor Yellow
        $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Verb RunAs -Wait -WindowStyle Hidden -PassThru
    }

    Write-Host ""
    $state = Get-WindowsLicenseState
    if ($state -eq "LICENSED") {
        Write-Host "  [OK] LISENSI DIGITAL WINDOWS BERHASIL DIDAFTARKAN!" -ForegroundColor Green
        Write-Host "  Status  : Berlisensi Permanen HWID (Motherboard Terikat)" -ForegroundColor White
        Write-Host "  Catatan : Tanda air (watermark) otomatis dinonaktifkan." -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] OPERASI REGISTRASI TIKET SELESAI DIEKSEKUSI!" -ForegroundColor Green
        Write-Host "  Status  : Silakan periksa status aktivasi di Windows Settings." -ForegroundColor White
    }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Check-Diagnostics {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTIK STATUS LISENSI WINDOWS (SLMGR.VBS)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $slmgr = Join-Path $env:SystemRoot "System32\slmgr.vbs"
    if (Test-Path -LiteralPath $slmgr) {
        cscript.exe //nologo $slmgr /xpr
        Write-Host ""
        cscript.exe //nologo $slmgr /dli
    } else {
        $engine = Get-EnginePath
        if ($engine) {
            & cmd.exe /c "`"$engine`" /status -qedit -el"
        }
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Remove-License {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  SEDANG MENGHAPUS KUNCI LISENSI WINDOWS (RESET TOTAL)..." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $slmgr = Join-Path $env:SystemRoot "System32\slmgr.vbs"
    if (Test-Path -LiteralPath $slmgr) {
        if ($isAdmin) {
            Start-Process cscript.exe -ArgumentList "//nologo `"$slmgr`" /upk" -Wait -WindowStyle Hidden
            Start-Process cscript.exe -ArgumentList "//nologo `"$slmgr`" /cpky" -Wait -WindowStyle Hidden
        } else {
            Write-Host "  -> Izin Sistem: Klik 'Yes' pada dialog konfirmasi Windows..." -ForegroundColor Yellow
            Start-Process cscript.exe -ArgumentList "//nologo `"$slmgr`" /upk" -Verb RunAs -Wait -WindowStyle Hidden
            Start-Process cscript.exe -ArgumentList "//nologo `"$slmgr`" /cpky" -Verb RunAs -Wait -WindowStyle Hidden
        }
        Write-Host ""
        Write-Host "  [OK] KUNCI LISENSI WINDOWS BERHASIL DIHAPUS DARI REGISTRY!" -ForegroundColor Green
        Write-Host "  Windows telah dikembalikan ke status semula." -ForegroundColor White
    } else {
        Write-Host "  [GAGAL] Utilitas slmgr.vbs tidak ditemukan di sistem." -ForegroundColor Red
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Open-ActivationSettings {
    Write-Host ""
    try {
        Start-Process "ms-settings:activation"
        Write-Host "  > Menu Pengaturan Aktivasi Windows berhasil dibuka!" -ForegroundColor Green
        Write-Host "  Cek status 'Windows is activated with a digital license'." -ForegroundColor Yellow
    } catch {
        Write-Host "  [PERINGATAN] Tidak dapat membuka ms-settings:activation." -ForegroundColor Yellow
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-WindowsLicenseState) -eq "LICENSED") { "Digital License HWID (Permanen)" } else { "Belum Terdaftar / Default" }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-02] Perbaikan Watermark Lisensi Windows" -ForegroundColor White
    Write-Host "  Status  : $finalStatus (Motherboard Bound)" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------------------------
# LOOP UTAMA INTERAKTIF (1 TERMINAL EXECUTION — ULTRA-COMPACT GOLDEN 64 LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-Header

    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Daftarkan Lisensi HWID Permanen (Bebas Watermark)" -ForegroundColor Green
    Write-Host "   [2] Cek / Diagnostik Status Lisensi (slmgr.vbs /xpr)" -ForegroundColor Cyan
    Write-Host "   [3] Hapus Kunci Lisensi (Reset Windows ke Semula)" -ForegroundColor Yellow
    Write-Host "   [4] Buka Menu Pengaturan Aktivasi Windows di Layar" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()

    switch ($choice.Trim()) {
        "1" {
            Invoke-Action
        }
        "2" {
            Check-Diagnostics
        }
        "3" {
            Remove-License
        }
        "4" {
            Open-ActivationSettings
        }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            # Refresh menu
        }
    }
}
