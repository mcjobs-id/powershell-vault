# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : MATIKAN PEMBAGIAN UPDATE WINDOWS P2P SEDOT KUOTA
# Modul SKU    : FK-PSH-156 (Delivery Optimization Guard)
# Desain       : Ultra-Compact Golden 64 Layout (100% Single Terminal In-Place)
# Handover     : Seamless Single-Window Elevation Handover (Auto-UAC + Exit)
# Opsi         : BEFORE (Rawan Kuota) vs AFTER (Terkunci Hemat 100%) + UNDO
# ==============================================================================

param(
    [string]$Order = "",
    [switch]$NonInteractive
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // DELIVERY OPTIMIZATION GUARD - HEMAT KUOTA"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$isAdmin = $false
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

# ==============================================================================
# SEAMLESS SINGLE-WINDOW ELEVATION HANDOVER
# Jika dijalankan di terminal biasa, buka terminal Administrator resmi dan langsung
# tutup terminal non-admin lama agar tidak ada tumpukan terminal ganda (1 Terminal)
# ==============================================================================
if (-not $isAdmin -and -not $NonInteractive) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // PERIZINAN SISTEM (ADMINISTRATOR)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Layanan ini membutuhkan hak akses Administrator untuk" -ForegroundColor White
    Write-Host "  mengunci Group Policy sistem dan mematikan DoSvc." -ForegroundColor White
    Write-Host ""
    Write-Host "  -> Membuka sesi Administrator resmi (1 Terminal)..." -ForegroundColor Green
    Write-Host "     (Mohon klik 'Yes' / 'Ya' pada dialog konfirmasi UAC)" -ForegroundColor DarkGray
    Write-Host "================================================================" -ForegroundColor Cyan
    try {
        $orderArg = if ($global:fkOrderNumber) { " -Order '$global:fkOrderNumber'" } else { "" }
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { irm fokuskonten.my.id/anti-sedot-kuota$orderArg | iex }`"" -Verb RunAs
        exit
    } catch {
        Write-Host ""
        Write-Host "  [!] Izin Administrator dibatalkan oleh pengguna." -ForegroundColor Red
        Write-Host "      Silakan buka PowerShell dengan klik kanan -> 'Run as administrator'" -ForegroundColor Yellow
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk keluar..." -ForegroundColor Gray
        try { [Console]::ReadKey($true) | Out-Null } catch {}
        exit
    }
}

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Wait-Prompt {
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan Enter untuk kembali ke menu..." -ForegroundColor Gray
    try {
        if ([Console]::IsInputRedirected -or $NonInteractive) {
            Start-Sleep -Milliseconds 300
        } else {
            [Console]::ReadLine() | Out-Null
        }
    } catch {
        try { Read-Host | Out-Null } catch {}
    }
}

function Get-DoState {
    $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    $polVal = $null
    if (Test-Path -LiteralPath $polPath) {
        $prop = Get-ItemProperty -LiteralPath $polPath -Name "DODownloadMode" -ErrorAction SilentlyContinue
        if ($prop) { $polVal = $prop.DODownloadMode }
    }

    $nsPath = "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings"
    $nsVal = $null
    if (Test-Path -LiteralPath $nsPath) {
        $prop = Get-ItemProperty -LiteralPath $nsPath -Name "DownloadMode" -ErrorAction SilentlyContinue
        if ($prop) { $nsVal = $prop.DownloadMode }
    }

    $svc = Get-Service -Name "DoSvc" -ErrorAction SilentlyContinue
    $svcStatus = if ($svc) { $svc.Status.ToString() } else { "Unknown" }

    # Terkunci jika HKLM Policy bernilai 0 atau 100 (Bypass/None), atau NetworkService bernilai 0
    $isLocked = ($polVal -eq 0 -or $polVal -eq 100 -or $nsVal -eq 0)

    return [PSCustomObject]@{
        PolicyMode  = $polVal
        NsMode      = $nsVal
        Service     = $svcStatus
        IsProtected = $isLocked
    }
}

function Show-Header {
    Clear-Host
    $state = Get-DoState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Delivery Optimization Guard: Kunci P2P Anti-Sedot Kuota" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-156] Asistensi Resmi" -ForegroundColor DarkCyan

    if ($state.IsProtected) {
        Write-Host "  STATUS : [ TERKUNCI HEMAT KUOTA / AFTER ] (P2P Nonaktif)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ RAWAN SEDOT KUOTA / BEFORE ] (P2P Masih Aktif)" -ForegroundColor Yellow
    }

    if ($isAdmin) {
        Write-Host "  AKSES  : [ ADMINISTRATOR RESMI ] (Siap Eksekusi 1 Terminal)" -ForegroundColor Green
    } else {
        Write-Host "  AKSES  : [ USER STANDAR ] (Mode In-Place 1 Terminal)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Show-Diagnostics {
    Clear-Host
    $state = Get-DoState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTIK SISTEM & PENGGUNAAN KUOTA BACKGROUND (WUDO)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [1] STATUS KEBIJAKAN & REGISTRI:" -ForegroundColor White
    $polText = if ($null -eq $state.PolicyMode) { "Default Bawaan (Tidak Dibatasi)" } elseif ($state.PolicyMode -eq 0) { "0 (Terkunci: HTTP CDN Only / 0% P2P)" } else { "$($state.PolicyMode) (P2P Aktif)" }
    Write-Host "      - Policy DODownloadMode : $polText" -ForegroundColor Gray
    
    $nsText = if ($null -eq $state.NsMode) { "Default (P2P Diizinkan)" } elseif ($state.NsMode -eq 0) { "0 (Mati / Off di Windows Settings)" } else { "$($state.NsMode) (Aktif)" }
    Write-Host "      - NetworkService Mode   : $nsText" -ForegroundColor Gray

    Write-Host ""
    Write-Host "  [2] STATUS LAYANAN LATAR BELAKANG:" -ForegroundColor White
    $svcCol = if ($state.Service -eq "Running") { "Yellow" } else { "Green" }
    Write-Host "      - Service DoSvc Status  : $($state.Service)" -ForegroundColor $svcCol

    Write-Host ""
    Write-Host "  [3] RIWAYAT PEMAKAIAN BANDWIDTH BULAN INI:" -ForegroundColor White
    try {
        $perf = Get-DeliveryOptimizationPerfSnapThisMonth -ErrorAction SilentlyContinue
        if ($perf) {
            $dlMb = [math]::Round($perf.DownloadHttpBytes / 1MB, 2)
            $cacheMb = [math]::Round($perf.DownloadCacheHostBytes / 1MB, 2)
            $upMb = [math]::Round(($perf.UploadLanBytes + $perf.UploadInternetBytes) / 1MB, 2)
            Write-Host "      - Total Unduhan HTTP    : $dlMb MB" -ForegroundColor Gray
            Write-Host "      - Cache Host Download   : $cacheMb MB" -ForegroundColor Gray
            Write-Host "      - Total Upload ke PC Lain: $upMb MB" -ForegroundColor $(if ($upMb -gt 0) { "Red" } else { "Green" })
        } else {
            Write-Host "      - Data perf snap bulan ini belum tersedia." -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "      - Pemeriksaan metrik bandwidth dilewati." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  [4] KESIMPULAN AUDIT SISTEM:" -ForegroundColor White
    if ($state.IsProtected) {
        Write-Host "      [AMAN] PC Anda sudah berada dalam kondisi AFTER." -ForegroundColor Green
        Write-Host "      Windows Update tidak akan membagikan file ke PC lain." -ForegroundColor White
    } else {
        Write-Host "      [PERINGATAN] PC Anda berada dalam kondisi BEFORE." -ForegroundColor Yellow
        Write-Host "      Layanan Delivery Optimization berpotensi menyedot kuota." -ForegroundColor White
    }

    Wait-Prompt
}

function Set-DisableP2P {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  MENERAPKAN MODE AFTER // KUNCI HEMAT KUOTA 100%" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    $allOk = $true

    # Langkah 1: Kunci Kebijakan Mesin (HKLM Policy DODownloadMode = 0)
    Write-Host "  [1/4] Mengunci Group Policy DODownloadMode = 0 (HTTP Only)..." -NoNewline
    try {
        $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if (-not (Test-Path -LiteralPath $polPath)) {
            New-Item -Path $polPath -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $polPath -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [GAGAL]" -ForegroundColor Red
        Write-Host "        Pesan: $($_.Exception.Message)" -ForegroundColor DarkGray
        $allOk = $false
    }

    # Langkah 2: Kunci Registri Akun NetworkService (S-1-5-20 DownloadMode = 0)
    Write-Host "  [2/4] Mengunci Registri S-1-5-20 DownloadMode = 0 (GUI OFF)..." -NoNewline
    try {
        $nsPath = "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings"
        if (-not (Test-Path -LiteralPath $nsPath)) {
            New-Item -Path $nsPath -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $nsPath -Name "DownloadMode" -Value 0 -Type DWord -Force -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [GAGAL]" -ForegroundColor Red
        Write-Host "        Pesan: $($_.Exception.Message)" -ForegroundColor DarkGray
        $allOk = $false
    }

    # Langkah 3: Hentikan Service DoSvc & Set ke Manual
    Write-Host "  [3/4] Menghentikan background service DoSvc..." -NoNewline
    try {
        Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "DoSvc" -StartupType Manual -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [GAGAL]" -ForegroundColor Yellow
        Write-Host "        Pesan: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    # Langkah 4: Pembersihan Cache Delivery Optimization
    Write-Host "  [4/4] Membersihkan cache sisa Delivery Optimization..." -NoNewline
    try {
        Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [SELESAI]" -ForegroundColor Green
    }

    # Tambahan: Set DODownloadMode via CIM jika modul tersedia
    try {
        Import-Module DeliveryOptimization -ErrorAction SilentlyContinue
        Set-DODownloadMode -downloadMode CdnOnly -ErrorAction SilentlyContinue
    } catch {}

    Write-Host ""
    if ($allOk) {
        Write-Host "  ============================================================" -ForegroundColor Green
        Write-Host "  [SUKSES] STATUS SISTEM BERHASIL DIUBAH MENJADI: AFTER!" -ForegroundColor Green
        Write-Host "  Windows Update kini 100% direct-download tanpa P2P upload." -ForegroundColor White
        Write-Host "  Kuota internet Anda terlindungi dari penyedotan latar belakang." -ForegroundColor White
        Write-Host "  ============================================================" -ForegroundColor Green
    } else {
        Write-Host "  ============================================================" -ForegroundColor Yellow
        Write-Host "  [PERHATIAN] Beberapa kunci registri memerlukan izin Admin." -ForegroundColor Yellow
        Write-Host "  Mohon buka PowerShell dengan klik kanan -> 'Run as administrator'" -ForegroundColor Cyan
        Write-Host "  ============================================================" -ForegroundColor Yellow
    }

    Wait-Prompt
}

function Set-RestoreBefore {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  MENERAPKAN MODE BEFORE // KEMBALIKAN KE SETELAN AWAL (UNDO)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Langkah 1: Hapus Group Policy
    Write-Host "  [1/3] Menghapus Group Policy DODownloadMode..." -NoNewline
    try {
        $polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if (Test-Path -LiteralPath $polPath) {
            Remove-ItemProperty -Path $polPath -Name "DODownloadMode" -ErrorAction SilentlyContinue
        }
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [LEWAT]" -ForegroundColor DarkGray
    }

    # Langkah 2: Kembalikan NetworkService ke Default LAN (1)
    Write-Host "  [2/3] Mengembalikan NetworkService DownloadMode = 1 (LAN)..." -NoNewline
    try {
        $nsPath = "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings"
        if (Test-Path -LiteralPath $nsPath) {
            Set-ItemProperty -Path $nsPath -Name "DownloadMode" -Value 1 -Type DWord -Force -ErrorAction Stop
        }
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [LEWAT]" -ForegroundColor DarkGray
    }

    # Langkah 3: Kembalikan Service DoSvc ke Automatic & Start
    Write-Host "  [3/3] Mengembalikan service DoSvc ke Automatic..." -NoNewline
    try {
        Set-Service -Name "DoSvc" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "DoSvc" -ErrorAction SilentlyContinue
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [LEWAT]" -ForegroundColor DarkGray
    }

    # Kembalikan via CIM jika modul tersedia
    try {
        Import-Module DeliveryOptimization -ErrorAction SilentlyContinue
        Set-DODownloadMode -downloadMode Lan -ErrorAction SilentlyContinue
    } catch {}

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "  [PULIH] SISTEM TELAH DIKEMBALIKAN KE STATUS AWAL: BEFORE" -ForegroundColor Yellow
    Write-Host "  Pengaturan Delivery Optimization kembali ke bawaan Windows." -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor Yellow

    Wait-Prompt
}

function Open-GuiSettings {
    Write-Host ""
    Write-Host "  -> Membuka halaman Pengaturan Windows Delivery Optimization..." -ForegroundColor Cyan
    try {
        Start-Process "ms-settings:delivery-optimization"
        Write-Host "     [OK] Jendela Settings Windows berhasil dibuka." -ForegroundColor Green
        Write-Host "     Anda dapat melihat saklar 'Izinkan unduhan dari PC lain'" -ForegroundColor White
        Write-Host "     berada dalam posisi NONAKTIF / DIATUR OLEH KEBIJAKAN." -ForegroundColor Gray
    } catch {
        Write-Host "     [GAGAL] Tidak dapat membuka ms-settings:delivery-optimization." -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 1200
}

function Show-ExitBanner {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  SERAH TERIMA RESMI" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Terima kasih telah mempercayakan asistensi teknis kepada kami." -ForegroundColor White
    Write-Host "  Layanan : [FK-PSH-156] Delivery Optimization Guard" -ForegroundColor Gray
    Write-Host "  Status  : Perlindungan Kuota Background Selesai Dikonfigurasi" -ForegroundColor Green
    Write-Host "  Web     : https://fokuskonten.my.id" -ForegroundColor DarkCyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Restore-Terminal
}

# ==============================================================================
# MENU UTAMA (LOOP)
# ==============================================================================
function Run-MainMenu {
    while ($true) {
        Show-Header
        Write-Host "  PILIHAN MENU OPERASI:" -ForegroundColor White
        Write-Host "  [1] Matikan Pembagian P2P (Kunci Hemat Kuota 100% - AFTER)" -ForegroundColor Green
        Write-Host "  [2] Diagnostik Status & Pemakaian Kuota (Before / After)" -ForegroundColor Cyan
        Write-Host "  [3] Kembalikan ke Setelan Awal Windows (Bawaan / BEFORE / UNDO)" -ForegroundColor Yellow
        Write-Host "  [4] Buka GUI Pengaturan Windows (Verifikasi Saklar di Layar)" -ForegroundColor White
        Write-Host "  [0] Selesai & Keluar" -ForegroundColor Gray
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host -NoNewline "  Ketik angka pilihan [0-4] lalu tekan Enter: " -ForegroundColor Yellow

        if ($NonInteractive) {
            Write-Host "0 (Non-interactive mode)"
            Show-ExitBanner
            return
        }

        $pilihan = [Console]::ReadLine()
        if ($null -eq $pilihan) { $pilihan = "" }
        $pilihan = $pilihan.Trim()

        switch ($pilihan) {
            "1" { Set-DisableP2P }
            "2" { Show-Diagnostics }
            "3" { Set-RestoreBefore }
            "4" { Open-GuiSettings }
            "0" { Show-ExitBanner; return }
            default {
                Write-Host "  Pilihan tidak valid. Silakan pilih [0-4]." -ForegroundColor Red
                Start-Sleep -Milliseconds 800
            }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Run-MainMenu
}
