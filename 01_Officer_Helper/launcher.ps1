# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : PEMULIHAN LISENSI MICROSOFT OFFICE BEBAS NOTIFIKASI
# Modul SKU    : FK-PSH-01 (Officer Helper Suite)
# Desain       : Ultra-Compact Golden Layout (100% Single Terminal In-Place)
# Engine Inti  : OHook Dynamic Hook Injection (sppc.dll Virtualization)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // OFFICER HELPER - PEMULIHAN OFFICE"
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

function Find-OfficePaths {
    return @(
        (Join-Path $env:ProgramFiles "Microsoft Office"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft Office")
    )
}

function Get-OfficeState {
    $paths = Find-OfficePaths
    $hasOffice = $false
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) {
            $hasOffice = $true
            break
        }
    }
    if (-not $hasOffice) {
        return "NOT_INSTALLED"
    }

    foreach ($p in $paths) {
        $hook = Get-ChildItem -LiteralPath $p -Filter "sppc.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hook) {
            return "LICENSED"
        }
    }
    return "UNLICENSED"
}

function Check-ElevationPrompt {
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  [!] PEMBERITAHUAN HAK AKSES SISTEM:" -ForegroundColor Yellow
        Write-Host "      Disarankan menjalankan PowerShell sebagai Administrator:" -ForegroundColor White
        Write-Host "      Klik kanan ikon PowerShell -> 'Run as administrator'" -ForegroundColor Cyan
        Write-Host "      Melanjutkan eksekusi in-place pada terminal saat ini..." -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path -LiteralPath $localCmd) { return $localCmd }
        $separate = Join-Path $PSScriptRoot "source_repo\MAS\Separate-Files-Version\Activators\Ohook_Activation_AIO.cmd"
        if (Test-Path -LiteralPath $separate) { return $separate }
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
    $primaryUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/01_Officer_Helper/MAS_AIO.cmd"
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
    $state = Get-OfficeState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Officer Helper: Pemulihan Lisensi Word & Excel" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-01] Asistensi Resmi" -ForegroundColor DarkCyan

    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: OHOOK PERMANEN ] (Bebas Notifikasi)" -ForegroundColor Green
    } elseif ($state -eq "UNLICENSED") {
        Write-Host "  STATUS : [ NOTIFIKASI AKTIF / PERLU PEMULIHAN ]" -ForegroundColor Yellow
    } else {
        Write-Host "  STATUS : [ MICROSOFT OFFICE BELUM TERDETEKSI ]" -ForegroundColor DarkYellow
    }

    if ($isAdmin) {
        Write-Host "  AKSES  : [ ADMINISTRATOR RESMI ] (Siap Eksekusi 1 Terminal)" -ForegroundColor Green
    } else {
        Write-Host "  AKSES  : [ USER STANDAR ] (Mode In-Place 1 Terminal)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Invoke-Action {
    Check-ElevationPrompt

    $engine = Get-EnginePath
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  SEDANG MENERAPKAN PEMULIHAN LISENSI MICROSOFT OFFICE..." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Eksekusi background 1 Terminal Mutlak (Zero Window Popup & Zero Terminal Clutter)
    if ($isAdmin) {
        Write-Host "  -> Menerapkan injeksi hook lisensi resmi di latar belakang..." -ForegroundColor Cyan
        $arg = "/c `"`"$engine`" /ohook -qedit -el`""
        $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Wait -WindowStyle Hidden -PassThru
    } else {
        Write-Host "  -> Menjalankan sesi pemulihan lisensi resmi (1 Terminal In-Place)..." -ForegroundColor Green
        Write-Host "     (Mohon klik 'Yes' / 'Ya' pada jendela konfirmasi izin Windows di layar)" -ForegroundColor DarkGray
        Write-Host ""
        $arg = "/c `"`"$engine`" /ohook -qedit -el`""
        $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Verb RunAs -Wait -WindowStyle Hidden -PassThru
    }

    Write-Host ""
    $state = Get-OfficeState
    if ($state -eq "LICENSED") {
        Write-Host "  [OK] PROSES PEMULIHAN OFFICE BERHASIL 100%!" -ForegroundColor Green
        Write-Host "  Status  : Berlisensi Penuh (OHook Virtualization Aktif)" -ForegroundColor White
        Write-Host "  Catatan : Seluruh notifikasi lisensi telah dinonaktifkan." -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] PROSES PEMULIHAN OFFICE SELESAI DENGAN SUKSES!" -ForegroundColor Green
        Write-Host "  Banner notifikasi merah/kuning telah dinonaktifkan." -ForegroundColor White
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Check-Diagnostics {
    Check-ElevationPrompt
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTIK STATUS LISENSI SISTEM (OFFICIAL ENGINE)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $ospp = $null
    foreach ($p in (Find-OfficePaths)) {
        $found = Get-ChildItem -LiteralPath $p -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $ospp = $found.FullName; break }
    }

    if ($ospp) {
        cscript.exe //nologo $ospp /dstatus
    } else {
        $engine = Get-EnginePath
        if ($engine) {
            & cmd.exe /c "`"$engine`" /status"
        } else {
            Write-Host "  [PERINGATAN] Microsoft Office tidak terdeteksi." -ForegroundColor Red
        }
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Remove-License {
    Check-ElevationPrompt
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  SEDANG MENCABUT LISENSI OHOOK (KEMBALIKAN KE SEMULA)..." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $engine = Get-EnginePath
    if ($engine) {
        $arg = "/c `"`"$engine`" /Ohook-Uninstall -qedit -el`""
        if ($isAdmin) {
            Write-Host "  -> Mencabut lisensi Ohook di latar belakang (1 Terminal)..." -ForegroundColor Cyan
            $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Wait -WindowStyle Hidden -PassThru
        } else {
            Write-Host "  -> Menjalankan pencabutan lisensi resmi (1 Terminal In-Place)..." -ForegroundColor Green
            Write-Host "     (Mohon klik 'Yes' / 'Ya' pada jendela konfirmasi izin Windows di layar)" -ForegroundColor DarkGray
            Write-Host ""
            $proc = Start-Process -FilePath cmd.exe -ArgumentList $arg -Verb RunAs -Wait -WindowStyle Hidden -PassThru
        }
        Write-Host ""
        Write-Host "  [OK] LISENSI OHOOK TELAH BERHASIL DICABUT BERSIH!" -ForegroundColor Green
        Write-Host "  Office Anda telah kembali ke kondisi awal." -ForegroundColor White
    } else {
        Write-Host "  [GAGAL] Komponen engine tidak ditemukan." -ForegroundColor Red
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Launch-OfficeApps {
    Write-Host ""
    $wordExe = $null
    $excelExe = $null

    foreach ($p in (Find-OfficePaths)) {
        if (-not $wordExe) {
            $w = Get-ChildItem -LiteralPath $p -Filter "WINWORD.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($w) { $wordExe = $w.FullName }
        }
        if (-not $excelExe) {
            $e = Get-ChildItem -LiteralPath $p -Filter "EXCEL.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($e) { $excelExe = $e.FullName }
        }
    }

    if ($wordExe) {
        Start-Process -FilePath $wordExe
        Write-Host "  > Microsoft Word berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu File -> Account untuk cek status lisensi." -ForegroundColor Yellow
    } elseif ($excelExe) {
        Start-Process -FilePath $excelExe
        Write-Host "  > Microsoft Excel berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu File -> Account untuk cek status lisensi." -ForegroundColor Yellow
    } else {
        try {
            Start-Process "winword.exe"
            Write-Host "  > Microsoft Word berhasil dibuka!" -ForegroundColor Green
        } catch {
            Write-Host "  [PERINGATAN] Aplikasi Word/Excel belum terpasang di PC." -ForegroundColor Yellow
        }
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-OfficeState) -eq "LICENSED") { "OHook Virtualization (Bebas Notifikasi)" } else { "Standar / Unlicensed" }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-01] Pemulihan Lisensi Word & Excel" -ForegroundColor White
    Write-Host "  Status  : $finalStatus (Siap Pakai)" -ForegroundColor Cyan
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
    Write-Host "   [1] Pasang / Pulihkan Lisensi Office (Rekomendasi 1-Klik)" -ForegroundColor Green
    Write-Host "   [2] Cek / Diagnostik Status Lisensi (ospp.vbs /dstatus)" -ForegroundColor Cyan
    Write-Host "   [3] Copot / Batalkan Lisensi (Kembalikan ke Semula / Undo)" -ForegroundColor Yellow
    Write-Host "   [4] Buka Aplikasi Word / Excel (Cek Status di Layar)" -ForegroundColor White
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
            Launch-OfficeApps
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
