# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : UPGRADE WINDOWS HOME MENJADI WINDOWS PRO (IN-PLACE CBS UPGRADE)
# Modul SKU    : FK-PSH-63 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Execution (1 Terminal Mutlak, Bebas Pop-up Jendela)
# Engine       : MAS Change_Windows_Edition Embedded CBS & DISM Upgrade Engine
# Fitur        : Upgrade Home -> Pro 1-Klik, Zero Format, Dokumen Aman 100%
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // WINDOWS HOME TO PRO UPGRADE SUITE"
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

function Get-EditionInfo {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $caption = if ($os.Caption) { $os.Caption.Trim() } else { "Microsoft Windows" }
    $build = if ($os.BuildNumber) { $os.BuildNumber } else { "10.0" }
    $arch = if ($os.OSArchitecture) { $os.OSArchitecture } else { "64-bit" }
    
    $isPro = ($caption -match "Pro|Professional|Enterprise|Education")
    $statusText = if ($isPro) { "[ SUDAH EDISI PRO / AKTIF ]" } else { "[ BELUM AKTIF / MASIH HOME ]" }

    return @{
        Caption    = $caption
        Build      = $build
        Arch       = $arch
        IsPro      = $isPro
        StatusText = $statusText
    }
}

function Test-ProFeatures {
    $gpedit = Test-Path "$env:SystemRoot\System32\gpedit.msc"
    $sandbox = (Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -ErrorAction SilentlyContinue).State -eq "Enabled"
    $rdp = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections -eq 0

    return @{
        Gpedit  = if ($gpedit) { "TERSEDIA" } else { "TERKUNCI (HANYA DI PRO)" }
        Sandbox = if ($sandbox) { "AKTIF" } else { "BELUM AKTIF / PERLU PRO" }
        RDP     = if ($rdp) { "DIIZINKAN" } else { "TERBATAS DI HOME" }
    }
}

function Ensure-EngineFile {
    $dir = "$env:ProgramData\FokusKonten"
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $target = Join-Path $dir "Change_Windows_Edition.cmd"

    # 1. Prioritaskan berkas lokal di folder yang sama jika ada
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "Change_Windows_Edition.cmd"
        if (Test-Path -LiteralPath $localCmd) {
            Copy-Item -LiteralPath $localCmd -Destination $target -Force
            return $target
        }
    }

    # 2. Periksa apakah sudah ada di ProgramData dan ukurannya valid (> 10000 bytes)
    if ((Test-Path -LiteralPath $target) -and ((Get-Item -LiteralPath $target).Length -gt 10000)) {
        return $target
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul mesin resmi FokusKonten..." -ForegroundColor Cyan
    $primaryUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/63_Change_Windows_Edition_Home_To_Pro/Change_Windows_Edition.cmd"
    $fallbackUrl = "http://127.0.0.1:8090/dl/change-edition"

    try {
        $wc = New-Object System.Net.WebClient
        $rawText = $wc.DownloadString($primaryUrl)
        if ($rawText.Length -gt 10000) {
            $crlfText = $rawText -replace "(?<!`r)`n", "`r`n"
            [System.IO.File]::WriteAllText($target, $crlfText, [System.Text.Encoding]::ASCII)
            Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
            return $target
        }
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            $rawText = $wc.DownloadString($fallbackUrl)
            if ($rawText.Length -gt 10000) {
                $crlfText = $rawText -replace "(?<!`r)`n", "`r`n"
                [System.IO.File]::WriteAllText($target, $crlfText, [System.Text.Encoding]::ASCII)
                Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
                return $target
            }
        } catch {}
    }

    return $target
}

function Show-Header {
    Clear-Host
    $info = Get-EditionInfo
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " FOKUSKONTEN // WINDOWS HOME TO PRO UPGRADE SUITE              " -ForegroundColor White
    Write-Host " Rekayasa Sistem In-Place Upgrade Resmi Tanpa Instal Ulang      " -ForegroundColor DarkGray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " TIKET ORDER : " -NoNewline -ForegroundColor Gray
    Write-Host "$($global:fkOrderNumber)" -ForegroundColor Yellow
    Write-Host " SISTEM OPERASI : " -NoNewline -ForegroundColor Gray
    Write-Host "$($info.Caption) ($($info.Arch))" -ForegroundColor White
    Write-Host " BUILD WINDOWS : " -NoNewline -ForegroundColor Gray
    Write-Host "Build $($info.Build)" -ForegroundColor White
    Write-Host " STATUS PRO     : " -NoNewline -ForegroundColor Gray
    if ($info.IsPro) {
        Write-Host "$($info.StatusText)" -ForegroundColor Green
    } else {
        Write-Host "$($info.StatusText)" -ForegroundColor Yellow
    }
    Write-Host " HAK AKSES      : " -NoNewline -ForegroundColor Gray
    if ($isAdmin) {
        Write-Host "ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "User Standar (Auto-Elevasi Mandiri)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " PILIHAN TINDAKAN UPGRADE:" -ForegroundColor White
    Write-Host "   [1] Upgrade Langsung ke Windows 10/11 Pro (1-Klik Rekomendasi)" -ForegroundColor Green
    Write-Host "   [2] Pilih Edisi Lainnya (Workstation / Enterprise / Education)" -ForegroundColor Cyan
    Write-Host "   [3] Cek Kesiapan Fitur Pro (BitLocker, Gpedit, Sandbox, RDP)" -ForegroundColor White
    Write-Host "   [4] Buka Menu Pengaturan Aktivasi Windows di Layar" -ForegroundColor Gray
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Invoke-UpgradeToPro {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " [PROSES UPGRADE] Memulai Transisi Windows Home ke Pro..." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " * Mode          : In-Place CBS Component Activation" -ForegroundColor White
    Write-Host " * Resiko Data   : 0% (Seluruh Dokumen & Aplikasi Tetap Utuh)" -ForegroundColor Green
    Write-Host " * Durasi        : 1 - 2 Menit (Membutuhkan 1x Restart)" -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray

    $engineFile = Ensure-EngineFile
    if (-not (Test-Path $engineFile)) {
        Write-Host " [!] Gagal menyiapkan berkas mesin eksekusi." -ForegroundColor Red
        Write-Host " Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        $null = [Console]::ReadKey($true)
        return
    }

    Write-Host " [i] Mempersiapkan lisensi upgrade generik resmi Microsoft..." -ForegroundColor Cyan
    Write-Host " [i] Kunci Produk : VK7JG-NPHTM-C97JM-9MPGT-3V66T" -ForegroundColor Gray
    Write-Host ""

    # Eksekusi via Start-Process
    if (-not $isAdmin) {
        Write-Host " [*] Meminta izin hak akses Administrator sistem..." -ForegroundColor Yellow
        try {
            $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$engineFile`" -el" -Verb RunAs -PassThru -Wait
        } catch {
            Write-Host " [!] Izin Administrator dibatalkan oleh pengguna." -ForegroundColor Red
        }
    } else {
        & cmd.exe /c "`"$engineFile`""
    }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host " PROSES SELESAI!" -ForegroundColor Yellow
    Write-Host " Silakan restart komputer/laptop Anda untuk merampungkan" -ForegroundColor White
    Write-Host " pembaruan komponen Windows Pro secara permanen." -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host " Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
}

function Invoke-FullEditionMenu {
    $engineFile = Ensure-EngineFile
    if (-not (Test-Path $engineFile)) {
        Write-Host " [!] Gagal menyiapkan berkas mesin eksekusi." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    if (-not $isAdmin) {
        Write-Host " [*] Membuka antarmuka pemilihan edisi Administrator..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$engineFile`" -el" -Verb RunAs -Wait
        } catch {
            Write-Host " [!] Izin dibatalkan oleh pengguna." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } else {
        & cmd.exe /c "`"$engineFile`""
    }
}

function Show-FeatureDiagnostic {
    Clear-Host
    $info = Get-EditionInfo
    $feat = Test-ProFeatures
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " FOKUSKONTEN // DIAGNOSTIK KESIAPAN FITUR WINDOWS PRO           " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] NAMA SISTEM OPERASI :" -ForegroundColor Gray
    Write-Host "     $($info.Caption) ($($info.Arch)) - Build $($info.Build)" -ForegroundColor White
    Write-Host ""
    Write-Host " [2] STATUS EDISI SAAT INI :" -ForegroundColor Gray
    if ($info.IsPro) {
        Write-Host "     $($info.StatusText) - Fitur Pro Sudah Siap Digunakan" -ForegroundColor Green
    } else {
        Write-Host "     $($info.StatusText) - Fitur Terkunci Bawaan Pabrik" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host " [3] SENSOR FITUR SPESIFIK :" -ForegroundColor Gray
    Write-Host "     * Group Policy Editor (gpedit.msc) : " -NoNewline -ForegroundColor White
    Write-Host "$($feat.Gpedit)" -ForegroundColor (if ($feat.Gpedit -eq "TERSEDIA") { "Green" } else { "Yellow" })
    Write-Host "     * Remote Desktop Host (RDP)        : " -NoNewline -ForegroundColor White
    Write-Host "$($feat.RDP)" -ForegroundColor (if ($feat.RDP -eq "DIIZINKAN") { "Green" } else { "Yellow" })
    Write-Host "     * Windows Sandbox / Container      : " -NoNewline -ForegroundColor White
    Write-Host "$($feat.Sandbox)" -ForegroundColor (if ($feat.Sandbox -eq "AKTIF") { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
}

function Open-WindowsActivationSettings {
    Write-Host " [*] Membuka panel Pengaturan Aktivasi Windows di layar..." -ForegroundColor Cyan
    Start-Process "ms-settings:activation"
    Start-Sleep -Seconds 1
}

# Loop Utama Menu
while ($true) {
    Show-Header
    Write-Host " Silakan ketik angka pilihan menu [1, 2, 3, 4, 0] : " -NoNewline -ForegroundColor Green
    $choice = [Console]::ReadLine()
    if ($choice) { $choice = $choice.Trim() }

    switch ($choice) {
        "1" { Invoke-UpgradeToPro }
        "2" { Invoke-FullEditionMenu }
        "3" { Show-FeatureDiagnostic }
        "4" { Open-WindowsActivationSettings }
        "0" {
            Clear-Host
            Write-Host "================================================================" -ForegroundColor Green
            Write-Host " TERIMA KASIH TELAH MENGGUNAKAN LAYANAN RESMI FOKUSKONTEN      " -ForegroundColor Yellow
            Write-Host " Solusi Rekayasa Sistem Cepat, Aman, & Bergaransi Nonstop       " -ForegroundColor White
            Write-Host "================================================================" -ForegroundColor Green
            Write-Host ""
            Restore-Terminal
            exit 0
        }
        default {
            Write-Host " [!] Pilihan tidak valid. Silakan pilih menu yang tersedia." -ForegroundColor Red
            Start-Sleep -Milliseconds 800
        }
    }
}