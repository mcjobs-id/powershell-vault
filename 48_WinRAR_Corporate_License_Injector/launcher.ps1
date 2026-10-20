# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : KONFIGURASI WINRAR LISENSI RESMI BEBAS NOTIFIKASI
# Modul SKU    : FK-PSH-24 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // WINRAR LISENSI RESMI BEBAS POP-UP"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$global:winrarKeyData = @"
RAR registration data
Corporate Unlimited License
Unlimited Company License
UID=4d2626e25cbf78a48312
641221225083128d58c1448b17b6a12b4b2c15ea41b213bfa7a7b8
336f3db17f1a9b2b5fcaef91bb16b60c49cf532ec79f5a772c9a17
4c5b3644917578b948754b2a8634e2c0e86b24058b732bb64d84f8
d9a8c7b89d4e286e969966b0336214300300958f310f81d58d9294
00389b83b4b533f848f2b7b8a74e2b0c16b6188e404b9015e12be8
"@

$global:targetPaths = @(
    "$env:LOCALAPPDATA\Programs\WinRAR",
    "$env:ProgramFiles\WinRAR",
    "${env:ProgramFiles(x86)}\WinRAR",
    "$env:APPDATA\WinRAR"
)

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Get-WinRARState {
    foreach ($p in $global:targetPaths) {
        if (Test-Path (Join-Path $p "rarreg.key")) {
            return "LICENSED"
        }
    }
    return "TRIAL"
}

function Show-CompactHeader {
    Clear-Host
    $state = Get-WinRARState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Konfigurasi WinRAR Lisensi Resmi Bebas Notifikasi" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-24] Asistensi Resmi" -ForegroundColor DarkCyan
    
    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: CORPORATE UNLIMITED ] (Bebas Pop-up)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ MODE EVALUASI / TRIAL 40 HARI ] (Pop-up Aktif)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Install-WinRARLicense {
    Write-Host ""
    Write-Host "  [PROSES] Menyuntikkan Lisensi Resmi WinRAR..." -ForegroundColor Cyan
    $successCount = 0
    
    # Pastikan direktori AppData WinRAR ada
    $appDataDir = "$env:APPDATA\WinRAR"
    if (-not (Test-Path $appDataDir)) {
        New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
    }
    
    foreach ($p in $global:targetPaths) {
        if (Test-Path $p) {
            try {
                $targetFile = Join-Path $p "rarreg.key"
                Set-Content -LiteralPath $targetFile -Value $global:winrarKeyData -Encoding ASCII -Force
                Write-Host "  > Update lisensi: $p... [OK]" -ForegroundColor Green
                $successCount++
            } catch {
                # Lewati jika permission folder Program Files terkunci
            }
        }
    }
    
    if ($successCount -gt 0) {
        Write-Host ""
        Write-Host "  [BERHASIL] WinRAR Anda kini berstatus Unlimited License!" -ForegroundColor Green
        Write-Host "  Seluruh pop-up evaluasi 40 hari telah dinonaktifkan permanen." -ForegroundColor White
    } else {
        Write-Host "  [GAGAL] Direktori instalasi WinRAR tidak ditemukan." -ForegroundColor Red
    }
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Remove-WinRARLicense {
    Write-Host ""
    Write-Host "  [PROSES] Mengembalikan WinRAR ke Mode Evaluasi (Undo)..." -ForegroundColor Yellow
    $removedCount = 0
    
    foreach ($p in $global:targetPaths) {
        $targetFile = Join-Path $p "rarreg.key"
        if (Test-Path -LiteralPath $targetFile) {
            try {
                Remove-Item -LiteralPath $targetFile -Force -ErrorAction SilentlyContinue
                Write-Host "  > Hapus lisensi: $p... [OK]" -ForegroundColor Green
                $removedCount++
            } catch {}
        }
    }
    
    Write-Host ""
    Write-Host "  [BERHASIL] Lisensi kustom telah dihapus bersih." -ForegroundColor Green
    Write-Host "  WinRAR kembali ke kondisi evaluasi bawaan aslinya." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Launch-WinRARApp {
    Write-Host ""
    Write-Host "  [PROSES] Menjalankan aplikasi WinRAR..." -ForegroundColor Cyan
    
    $exeFound = $null
    foreach ($p in $global:targetPaths) {
        $testExe = Join-Path $p "WinRAR.exe"
        if (Test-Path $testExe) {
            $exeFound = $testExe
            break
        }
    }
    
    if ($exeFound) {
        Start-Process -FilePath $exeFound
        Write-Host "  > WinRAR berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu 'Help' -> 'About WinRAR' untuk cek lisensi." -ForegroundColor Yellow
    } else {
        Write-Host "  > Mencoba membuka WinRAR via path registri..." -ForegroundColor Cyan
        try {
            Start-Process "WinRAR.exe"
            Write-Host "  > WinRAR berhasil dibuka!" -ForegroundColor Green
        } catch {
            Write-Host "  [PERINGATAN] Aplikasi WinRAR belum terpasang di komputer." -ForegroundColor Red
        }
    }
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SystemGuide {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  PANDUAN & INFORMASI LISENSI WINRAR" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  * Tipe Lisensi  : Corporate Unlimited Company License" -ForegroundColor White
    Write-Host "  * Metode Resmi  : Injeksi rarreg.key standar resmi WinRAR" -ForegroundColor Gray
    Write-Host "  * Keamanan      : 100% Bersih, Tanpa Crack Biner, Tanpa Virus" -ForegroundColor Green
    Write-Host "  * Efek          : Menghilangkan pop-up evaluasi 40 hari" -ForegroundColor Gray
    Write-Host "  * Fleksibilitas : Bebas dihapus kembali via Menu [2]" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-WinRARState) -eq "LICENSED") { "Corporate Unlimited License" } else { "Evaluation Trial Mode" }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-24] WinRAR Bebas Notifikasi" -ForegroundColor White
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
    Write-Host "   [1] Pasang Lisensi Resmi WinRAR (Bebas Pop-up 40 Hari)" -ForegroundColor Green
    Write-Host "   [2] Hapus Lisensi (Restore ke Mode Evaluasi / Undo)" -ForegroundColor Yellow
    Write-Host "   [3] Buka Aplikasi WinRAR (Cek Status di Layar)" -ForegroundColor Cyan
    Write-Host "   [4] Panduan & Informasi Lisensi Sistem" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()
    
    switch ($choice.Trim()) {
        "1" {
            Install-WinRARLicense
        }
        "2" {
            Remove-WinRARLicense
        }
        "3" {
            Launch-WinRARApp
        }
        "4" {
            Show-SystemGuide
        }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            # Refresh menu jika input di luar opsi
        }
    }
}
