# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : PEMULIHAN LISENSI MICROSOFT OFFICE BEBAS NOTIFIKASI
# Modul SKU    : FK-PSH-01 (Officer Helper Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
# Fitur        : 1-Klik OHook, Diagnostik Status, Copot/Undo, Buka Aplikasi
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

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
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

    # Cek keberadaan hook virtualisasi sppc.dll
    foreach ($p in $paths) {
        $hook = Get-ChildItem -LiteralPath $p -Filter "sppc.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hook) {
            return "LICENSED"
        }
    }
    return "UNLICENSED"
}

function Request-Elevation {
    Write-Host ""
    Write-Host "  [PROSES] Menyiapkan Sesi Administrator (UAC)..." -ForegroundColor Cyan
    Write-Host "  Klik 'Yes' pada jendela konfirmasi sistem di layar Anda." -ForegroundColor Yellow
    try {
        $cmd = "irm fokuskonten.my.id/office | iex"
        Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $cmd -Verb RunAs
        exit 0
    } catch {
        Write-Host "  [!] Izin Administrator tidak diberikan." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

function Get-EnginePath {
    # 1. Cek direktori lokal jika ada
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path -LiteralPath $localCmd) { return $localCmd }
    }

    # 2. Cek temp cache
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "FK_Officer"
    if (-not (Test-Path -LiteralPath $tempDir)) {
        [System.IO.Directory]::CreateDirectory($tempDir) | Out-Null
    }
    $cached = Join-Path $tempDir "MAS_AIO.cmd"
    if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
        return $cached
    }

    # 3. Unduh dari CDN GitHub Vault resmi
    Write-Host "  > Menghubungkan ke Jaringan Cloud FokusKonten..." -ForegroundColor Gray
    Write-Host "  > Mengunduh komponen engine resmi via CDN..." -ForegroundColor Cyan
    $urls = @(
        "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/01_Officer_Helper/MAS_AIO.cmd",
        "https://fokuskonten.my.id/assets/engine/FK_Engine_Core.cmd"
    )

    foreach ($u in $urls) {
        try {
            Invoke-WebRequest -Uri $u -OutFile $cached -UseBasicParsing -TimeoutSec 30
            if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
                Write-Host "  > Komponen engine berhasil disiapkan! [OK]" -ForegroundColor Green
                return $cached
            }
        } catch {}
    }

    return $null
}

function Show-CompactHeader {
    Clear-Host
    $state = Get-OfficeState
    $isAdmin = Test-IsAdmin

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
        Write-Host "  AKSES  : [ ADMINISTRATOR RESMI ] (Siap Eksekusi 1-Klik)" -ForegroundColor Green
    } else {
        Write-Host "  AKSES  : [ USER STANDAR ] (Perlu Izin Administrator)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Install-OfficeLicense {
    if (-not (Test-IsAdmin)) {
        Request-Elevation
        return
    }

    Write-Host ""
    Write-Host "  [PROSES] Menyiapkan Pemulihan Lisensi Microsoft Office..." -ForegroundColor Cyan
    $engine = Get-EnginePath

    if (-not $engine) {
        Write-Host "  [GAGAL] Tidak dapat mengunduh engine pemulihan." -ForegroundColor Red
        Write-Host "  Periksa koneksi internet Anda lalu coba lagi." -ForegroundColor Gray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Write-Host "  > Menerapkan OHook Virtualization resmi (sppc.dll)..." -ForegroundColor Cyan
    & cmd.exe /c "`"$engine`" /ohook"

    Write-Host ""
    Write-Host "  [SUKSES] Lisensi Microsoft Office Berhasil Dipulihkan!" -ForegroundColor Green
    Write-Host "  Word, Excel, & PowerPoint Anda kini aktif bebas notifikasi." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Check-OfficeStatus {
    Write-Host ""
    Write-Host "  [PROSES] Memeriksa Diagnostik Status Lisensi Office..." -ForegroundColor Cyan
    
    # Cari ospp.vbs
    $ospp = $null
    foreach ($p in (Find-OfficePaths)) {
        $found = Get-ChildItem -LiteralPath $p -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $ospp = $found.FullName; break }
    }

    if ($ospp) {
        Write-Host "  > Menjalankan cscript ospp.vbs /dstatus..." -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        cscript.exe //nologo $ospp /dstatus
    } else {
        Write-Host "  > ospp.vbs tidak ditemukan. Menjalankan engine status..." -ForegroundColor Yellow
        $engine = Get-EnginePath
        if ($engine) {
            & cmd.exe /c "`"$engine`" /status"
        } else {
            Write-Host "  [PERINGATAN] Microsoft Office tidak terdeteksi di sistem." -ForegroundColor Red
        }
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Remove-OfficeLicense {
    if (-not (Test-IsAdmin)) {
        Request-Elevation
        return
    }

    Write-Host ""
    Write-Host "  [PERINGATAN] Anda akan mencabut lisensi OHook Office." -ForegroundColor Yellow
    Write-Host -NoNewline "  Apakah Anda yakin ingin melanjutkan? [Y/N] : " -ForegroundColor Cyan
    $ans = [Console]::ReadLine()
    if ($ans.Trim().ToUpper() -ne "Y") {
        Write-Host "  Proses pembatalan dibatalkan." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }

    Write-Host ""
    Write-Host "  [PROSES] Mencabut lisensi OHook (Kembalikan ke Semula)..." -ForegroundColor Cyan
    $engine = Get-EnginePath
    if ($engine) {
        & cmd.exe /c "`"$engine`" /Ohook-Uninstall"
        Write-Host ""
        Write-Host "  [BERHASIL] Lisensi OHook telah berhasil dicabut bersih." -ForegroundColor Green
        Write-Host "  Office Anda telah kembali ke kondisi awal." -ForegroundColor White
    } else {
        Write-Host "  [GAGAL] Komponen engine tidak ditemukan." -ForegroundColor Red
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
# LOOP UTAMA INTERAKTIF (ULTRA-COMPACT GOLDEN LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-CompactHeader

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
            Install-OfficeLicense
        }
        "2" {
            Check-OfficeStatus
        }
        "3" {
            Remove-OfficeLicense
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
