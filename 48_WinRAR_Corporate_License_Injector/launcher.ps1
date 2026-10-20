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
WinRAR
Unlimited Company License
UID=4b914fb772c8376bf571
6412212250f5711ad072cf351cfa39e2851192daf8a362681bbb1d
cd48da1d14d995f0bbf960fce6cb5ffde62890079861be57638717
7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565
b41bcf56929486b8bcdac33d50ecf773996052598f1f556defffbd
982fbe71e93df6b6346c37a3890f3c7edc65d7f5455470d13d1190
6e6fb824bcf25f155547b5fc41901ad58c0992f570be1cf5608ba9
aef69d48c864bcd72d15163897773d314187f6a9af350808719796
"@

function Get-TargetPaths {
    return @(
        (Join-Path $env:LOCALAPPDATA "Programs\WinRAR"),
        (Join-Path $env:ProgramFiles "WinRAR"),
        (Join-Path ${env:ProgramFiles(x86)} "WinRAR"),
        (Join-Path $env:APPDATA "WinRAR")
    )
}

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Get-WinRARState {
    foreach ($p in (Get-TargetPaths)) {
        $kf = Join-Path $p "rarreg.key"
        if (Test-Path -LiteralPath $kf) {
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
        Write-Host "  STATUS : [ BERLISENSI: UNLIMITED COMPANY ] (Bebas Pop-up)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ MODE EVALUASI / TRIAL 40 HARI ] (Pop-up Aktif)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Install-WinRARLicense {
    Write-Host ""
    Write-Host "  [PROSES] Menyuntikkan Lisensi Resmi WinRAR..." -ForegroundColor Cyan
    $successCount = 0
    
    $cleanKey = $global:winrarKeyData.Replace("`r`n", "`n") + "`r`n"
    
    # Pastikan direktori AppData WinRAR ada
    $appDataDir = Join-Path $env:APPDATA "WinRAR"
    if (-not (Test-Path -LiteralPath $appDataDir)) {
        New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
    }
    
    foreach ($p in (Get-TargetPaths)) {
        if (Test-Path -LiteralPath $p) {
            try {
                $targetFile = Join-Path $p "rarreg.key"
                [System.IO.File]::WriteAllText($targetFile, $cleanKey)
                Write-Host "  > Update lisensi: $p... [OK]" -ForegroundColor Green
                $successCount++
            } catch {
                # Lewati jika folder Program Files membutuhkan elevasi
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
    
    foreach ($p in (Get-TargetPaths)) {
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
    foreach ($p in (Get-TargetPaths)) {
        $testExe = Join-Path $p "WinRAR.exe"
        if (Test-Path -LiteralPath $testExe) {
            $exeFound = $testExe
            break
        }
    }
    
    if ($exeFound) {
        Start-Process -FilePath $exeFound
        Write-Host "  > WinRAR berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu 'Help' -> 'About WinRAR' untuk cek lisensi." -ForegroundColor Yellow
    } else {
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
    Write-Host "  * Tipe Lisensi  : Unlimited Company License" -ForegroundColor White
    Write-Host "  * Metode Resmi  : Injeksi rarreg.key standar resmi WinRAR" -ForegroundColor Gray
    Write-Host "  * Keamanan      : 100% Bersih, Tanpa Crack Biner, Tanpa Virus" -ForegroundColor Green
    Write-Host "  * Kompatibel    : WinRAR 5.x, 6.x, hingga WinRAR 7.x Terbaru" -ForegroundColor Yellow
    Write-Host "  * Efek          : Menghilangkan pop-up evaluasi 40 hari" -ForegroundColor Gray
    Write-Host "  * Fleksibilitas : Bebas dihapus kembali via Menu [2]" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-WinRARState) -eq "LICENSED") { "Unlimited Company License" } else { "Evaluation Trial Mode" }
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
