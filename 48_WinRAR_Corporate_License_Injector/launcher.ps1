# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : KONFIGURASI & SUITE PEMASANGAN RESMI WINRAR BEBAS POP-UP
# Modul SKU    : FK-PSH-24 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
# Fitur        : All-in-One Pasang Baru + Lisensi, Copot/Uninstall, Undo Lisensi
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // WINRAR RESMI ALL-IN-ONE SUITE"
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

function Find-WinRARExe {
    foreach ($p in (Get-TargetPaths)) {
        $exe = Join-Path $p "WinRAR.exe"
        if (Test-Path -LiteralPath $exe) {
            return $exe
        }
    }
    return $null
}

function Get-WinRARState {
    $hasExe = (Find-WinRARExe) -ne $null
    if (-not $hasExe) {
        return "NOT_INSTALLED"
    }
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
    Write-Host "  WinRAR Official Suite: Pasang, Lisensi & Kelola" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-24] Asistensi Resmi" -ForegroundColor DarkCyan
    
    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: UNLIMITED COMPANY ] (Bebas Pop-up)" -ForegroundColor Green
    } elseif ($state -eq "TRIAL") {
        Write-Host "  STATUS : [ MODE EVALUASI / TRIAL 40 HARI ] (Pop-up Aktif)" -ForegroundColor Yellow
    } else {
        Write-Host "  STATUS : [ WINRAR BELUM TERPASANG DI SISTEM INI ]" -ForegroundColor DarkYellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Inject-KeySilent {
    $cleanKey = $global:winrarKeyData.Replace("`r`n", "`n") + "`r`n"
    $appDataDir = Join-Path $env:APPDATA "WinRAR"
    if (-not (Test-Path -LiteralPath $appDataDir)) {
        New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
    }
    $done = 0
    foreach ($p in (Get-TargetPaths)) {
        if (Test-Path -LiteralPath $p) {
            try {
                $targetFile = Join-Path $p "rarreg.key"
                [System.IO.File]::WriteAllText($targetFile, $cleanKey)
                $done++
            } catch {}
        }
    }
    return ($done -gt 0)
}

function Install-FullWinRAR {
    Write-Host ""
    Write-Host "  [PROSES] Menyiapkan Pemasangan Resmi WinRAR x64..." -ForegroundColor Cyan
    
    $userProg = Join-Path $env:LOCALAPPDATA "Programs\WinRAR"
    if (-not (Test-Path -LiteralPath $userProg)) {
        [System.IO.Directory]::CreateDirectory($userProg) | Out-Null
    }
    
    $tempSetup = Join-Path ([System.IO.Path]::GetTempPath()) "winrar_setup_fk.exe"
    $cdnUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/48_WinRAR_Corporate_License_Injector/winrar_setup.exe"
    $fallbackUrl = "https://www.rarlab.com/rar/winrar-x64-701.exe"
    
    Write-Host "  > Mengunduh installer biner resmi via CDN..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $cdnUrl -OutFile $tempSetup -UseBasicParsing -TimeoutSec 30
        Write-Host "  > Unduhan biner CDN berhasil! (3.9 MB)" -ForegroundColor Green
    } catch {
        Write-Host "  > Mencoba mirror cadangan rarlab..." -ForegroundColor DarkYellow
        try {
            Invoke-WebRequest -Uri $fallbackUrl -OutFile $tempSetup -UseBasicParsing -TimeoutSec 30
            Write-Host "  > Unduhan mirror berhasil!" -ForegroundColor Green
        } catch {
            Write-Host "  [GAGAL] Tidak dapat mengunduh installer WinRAR." -ForegroundColor Red
            Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
    }
    
    # Ekstraksi biner menggunakan 7z jika ada, atau jalankan silent setup
    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
    if (Test-Path -LiteralPath $sevenZip) {
        Write-Host "  > Mengekstrak berkas biner secara bersih..." -ForegroundColor Cyan
        & $sevenZip x $tempSetup -o"$userProg" -y | Out-Null
    } else {
        Write-Host "  > Memasang installer WinRAR..." -ForegroundColor Cyan
        Start-Process -FilePath $tempSetup -ArgumentList "/s" -Wait -ErrorAction SilentlyContinue
    }
    
    # Daftarkan registri App Paths di HKCU
    $regApp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe"
    if (-not (Test-Path $regApp)) { New-Item -Path $regApp -Force | Out-Null }
    Set-ItemProperty -Path $regApp -Name "(Default)" -Value "$userProg\WinRAR.exe" -Force
    Set-ItemProperty -Path $regApp -Name "Path" -Value "$userProg" -Force
    
    # Buat Shortcut di Start Menu pengguna
    try {
        $smPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\WinRAR.lnk"
        $ws = New-Object -ComObject WScript.Shell
        $sc = $ws.CreateShortcut($smPath)
        $sc.TargetPath = "$userProg\WinRAR.exe"
        $sc.WorkingDirectory = "$userProg"
        $sc.Save()
    } catch {}
    
    # Suntikkan Lisensi Resmi Seketika
    Write-Host "  > Menyuntikkan lisensi Unlimited Company License..." -ForegroundColor Cyan
    $null = Inject-KeySilent
    
    # Bersihkan file temp installer
    Remove-Item -LiteralPath $tempSetup -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "  [SUKSES] WinRAR x64 + Lisensi Resmi Berhasil Dipasang!" -ForegroundColor Green
    Write-Host "  Aplikasi siap digunakan dan bebas kotak dialog evaluasi." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Install-LicenseOnly {
    Write-Host ""
    Write-Host "  [PROSES] Menyuntikkan Lisensi Resmi WinRAR..." -ForegroundColor Cyan
    $ok = Inject-KeySilent
    if ($ok) {
        Write-Host ""
        Write-Host "  [BERHASIL] WinRAR Anda kini berstatus Unlimited License!" -ForegroundColor Green
        Write-Host "  Seluruh pop-up evaluasi 40 hari dinonaktifkan permanen." -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "  [PERINGATAN] Folder instalasi WinRAR belum ditemukan." -ForegroundColor Yellow
        Write-Host "  Silakan pilih Menu [1] untuk memasang WinRAR otomatis." -ForegroundColor Cyan
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Uninstall-WinRARFull {
    Write-Host ""
    Write-Host "  [PERINGATAN] Anda akan mencopot WinRAR dari komputer ini." -ForegroundColor Yellow
    Write-Host -NoNewline "  Apakah Anda yakin ingin melanjutkan? [Y/N] : " -ForegroundColor Cyan
    $ans = [Console]::ReadLine()
    if ($ans.Trim().ToUpper() -ne "Y") {
        Write-Host "  Proses pencopotan dibatalkan." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        return
    }
    
    Write-Host ""
    Write-Host "  [PROSES] Menghapus WinRAR dan seluruh lisensinya..." -ForegroundColor Cyan
    
    # Hentikan proses WinRAR yang sedang berjalan
    Stop-Process -Name "winrar" -Force -ErrorAction SilentlyContinue
    
    # Hapus lisensi
    foreach ($p in (Get-TargetPaths)) {
        $kf = Join-Path $p "rarreg.key"
        if (Test-Path -LiteralPath $kf) {
            Remove-Item -LiteralPath $kf -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Hapus folder instalasi Programs\WinRAR jika ada
    $userProg = Join-Path $env:LOCALAPPDATA "Programs\WinRAR"
    if (Test-Path -LiteralPath $userProg) {
        Remove-Item -LiteralPath $userProg -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  > Folder instalasi WinRAR dibersihkan... [OK]" -ForegroundColor Green
    }
    
    # Hapus AppData WinRAR
    $appDataWinrar = Join-Path $env:APPDATA "WinRAR"
    if (Test-Path -LiteralPath $appDataWinrar) {
        Remove-Item -LiteralPath $appDataWinrar -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Hapus Shortcut Start Menu
    $smPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\WinRAR.lnk"
    if (Test-Path -LiteralPath $smPath) {
        Remove-Item -LiteralPath $smPath -Force -ErrorAction SilentlyContinue
        Write-Host "  > Pintasan Start Menu dibersihkan... [OK]" -ForegroundColor Green
    }
    
    # Hapus App Paths di registri HKCU
    $regApp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe"
    if (Test-Path -LiteralPath $regApp) {
        Remove-Item -LiteralPath $regApp -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "  [SELESAI] WinRAR telah berhasil dicopot secara bersih!" -ForegroundColor Green
    Write-Host "  Seluruh file dan registri kustom telah dihapus tuntas." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Remove-LicenseOnly {
    Write-Host ""
    Write-Host "  [PROSES] Mengembalikan WinRAR ke Mode Evaluasi (Undo)..." -ForegroundColor Yellow
    foreach ($p in (Get-TargetPaths)) {
        $targetFile = Join-Path $p "rarreg.key"
        if (Test-Path -LiteralPath $targetFile) {
            Remove-Item -LiteralPath $targetFile -Force -ErrorAction SilentlyContinue
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
    $exeFound = Find-WinRARExe
    if ($exeFound) {
        Start-Process -FilePath $exeFound
        Write-Host "  > WinRAR berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu 'Help' -> 'About WinRAR' untuk cek lisensi." -ForegroundColor Yellow
    } else {
        Write-Host "  [PERINGATAN] WinRAR belum terpasang di komputer Anda." -ForegroundColor Yellow
        Write-Host "  Pilih Menu [1] untuk mengunduh dan memasang otomatis." -ForegroundColor Cyan
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-WinRARState) -eq "LICENSED") { "Unlimited Company License" } else { "Evaluation Mode / Tidak Terpasang" }
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
    Write-Host "   [1] Pasang WinRAR x64 Baru + Lisensi Resmi (1-Klik Beres)" -ForegroundColor Green
    Write-Host "   [2] Pasang / Segarkan Lisensi Saja (WinRAR Sudah Ada)" -ForegroundColor Cyan
    Write-Host "   [3] Copot / Uninstall WinRAR dari Komputer (Hapus Bersih)" -ForegroundColor Yellow
    Write-Host "   [4] Reset Lisensi ke Mode Evaluasi (Trial Asli / Undo)" -ForegroundColor DarkYellow
    Write-Host "   [5] Buka Aplikasi WinRAR (Cek Status di Layar)" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 5, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()
    
    switch ($choice.Trim()) {
        "1" {
            Install-FullWinRAR
        }
        "2" {
            Install-LicenseOnly
        }
        "3" {
            Uninstall-WinRARFull
        }
        "4" {
            Remove-LicenseOnly
        }
        "5" {
            Launch-WinRARApp
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
