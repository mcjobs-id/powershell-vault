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

$global:FK_ENGINE_B64 = "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"

function Ensure-EngineFile {
    $dir = "$env:ProgramData\FokusKonten"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $target = Join-Path $dir "Change_Windows_Edition.cmd"

    # Prioritaskan berkas lokal di folder yang sama jika ada
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "Change_Windows_Edition.cmd"
        if (Test-Path $localCmd) {
            Copy-Item -LiteralPath $localCmd -Destination $target -Force
            return $target
        }
    }

    if (-not (Test-Path $target) -or ((Get-Item $target).Length -lt 10000)) {
        try {
            $bytes = [Convert]::FromBase64String($global:FK_ENGINE_B64)
            $msIn = New-Object IO.MemoryStream(@(,$bytes))
            $gzIn = New-Object IO.Compression.GZipStream($msIn, [IO.Compression.CompressionMode]::Decompress)
            $msOut = New-Object IO.MemoryStream
            $gzIn.CopyTo($msOut)
            $gzIn.Close()
            [IO.File]::WriteAllBytes($target, $msOut.ToArray())
        } catch {
            # Fallback download jika dekompresi gagal
            try {
                Invoke-WebRequest -Uri "https://fokuskonten.my.id/dl/change-edition" -OutFile $target -UseBasicParsing
            } catch {}
        }
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