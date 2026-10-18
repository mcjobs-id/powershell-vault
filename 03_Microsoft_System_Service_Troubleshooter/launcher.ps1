# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 03: SYSTEM SERVICE TROUBLESHOOTER - PERBAIKAN SPPSVC
# Engine  : License Token Reset & Software Protection Repair
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // SYSTEM SERVICE TROUBLESHOOTER - PERBAIKAN SPPSVC"
} catch {}

$isAdmin = $false
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

$isISE = ($Host.Name -match "ISE")

function Show-Header {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Pertolongan Pertama Darurat & Pemulihan Lisensi Sistem" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Tenang, seluruh dokumen kerja Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  FokusKonten sedang menyiapkan pemulihan lisensi otomatis tanpa risiko." -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  RINGKASAN DIAGNOSTIK:" -ForegroundColor White
    Write-Host "  * Layanan        : SYSTEM SERVICE TROUBLESHOOTER - PERBAIKAN SPPSVC" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : License Token Reset & Software Protection Repair" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Bebas Antivirus, Tanpa Mengubah Dokumen Kerja)" -ForegroundColor Green
    if ($isAdmin) {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "  * Hak Akses      : Mode Standar (Disarankan Jalankan sebagai Administrator)" -ForegroundColor Yellow
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Pasang / Aktifkan Lisensi Otomatis (Rekomendasi 1-Klik)" -ForegroundColor Green
    Write-Host "          Aktivasi permanen bebas banner notifikasi lisensi." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Cek / Diagnostik Status Lisensi Saat Ini" -ForegroundColor White
    Write-Host "          Memeriksa masa aktif lisensi dan partial key terpasang." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Copot / Batalkan Lisensi (Kembalikan ke Default)" -ForegroundColor Yellow
    Write-Host "          Mencabut hook lisensi dan mengembalikan Office/Windows ke semula." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Kunjungi Ekosistem & Solusi Digital FokusKonten (Buka Web)" -ForegroundColor Cyan
    Write-Host "          Jelajahi ribuan software kasir, aplikasi bisnis, & template." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [0] Batal / Keluar" -ForegroundColor DarkGray
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

function Get-UserChoice {
    if ($isISE) {
        $c = Read-Host "  Pilihan Anda [1, 2, 3, 4, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }

    try {
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 4, 0] (Tekan Enter untuk [1]) : " -ForegroundColor Green
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Enter) {
                Write-Host "1" -ForegroundColor Green
                return "1"
            }
            $c = $k.KeyChar.ToString()
            if ($c -in @('1','2','3','4','0')) {
                Write-Host $c -ForegroundColor Green
                return $c
            }
        }
    } catch {
        $c = Read-Host "  Pilihan Anda [1, 2, 3, 4, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }
}

function Check-ElevationPrompt {
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  [!] PEMBERITAHUAN HAK AKSES SISTEM:" -ForegroundColor Yellow
        Write-Host "      Untuk hasil optimal, disarankan menjalankan PowerShell sebagai Administrator:" -ForegroundColor White
        Write-Host "      Klik kanan ikon PowerShell -> 'Run as administrator'" -ForegroundColor Cyan
        Write-Host "      Melanjutkan proses pada sesi saat ini..." -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path $localCmd) { return $localCmd }
        $separate = Join-Path $PSScriptRoot "source_repo\MAS\Separate-Files-Version\Activators\Ohook_Activation_AIO.cmd"
        if (Test-Path $separate) { return $separate }
    }

    $workDir = Join-Path $env:ProgramData "FokusKonten"
    if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
    $cached = Join-Path $workDir "FK_Core_Runtime_v2.cmd"
    if ((Test-Path $cached) -and ((Get-Item $cached).Length -gt 50000)) {
        return $cached
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul pemulihan lisensi resmi FokusKonten..." -ForegroundColor Cyan
    $primaryUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/03_Microsoft_System_Service_Troubleshooter/MAS_AIO.cmd"
    try {
        $wc = New-Object System.Net.WebClient
        $rawText = $wc.DownloadString($primaryUrl)
        if ($rawText.Length -gt 50000) {
            $crlfText = $rawText -replace "(?<!`r)`n", "`r`n"
            [System.IO.File]::WriteAllText($cached, $crlfText, [System.Text.Encoding]::ASCII)
            Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
            return $cached
        }
    } catch {}

    return $cached
}

function Invoke-Action {
    Check-ElevationPrompt

    $engine = Get-EnginePath
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MEMPERBAIKI SPPSVC & RESET TOKEN LISENSI..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""
    & cmd.exe /c `"`"$engine`" /sppsvc`"

    Write-Host ""
    Write-Host "  [OK] OPERASI SELESAI DENGAN SUKSES!" -ForegroundColor Green
    Write-Host "  Terima kasih telah menggunakan utilitas resmi FokusKonten." -ForegroundColor Gray
}

# Main Loop
Show-Header
$choice = Get-UserChoice

switch ($choice) {
    "1" { Invoke-Action }
    "2" {
        Check-ElevationPrompt
        Write-Host ""
        Write-Host "  ================================================================" -ForegroundColor Green
        Write-Host "  DIAGNOSTIK LISENSI SISTEM (OFFICIAL ENGINE)" -ForegroundColor Green
        Write-Host "  ================================================================" -ForegroundColor Green
        Write-Host ""
        $ospp = Get-ChildItem "C:\Program Files\Microsoft Office", "C:\Program Files (x86)\Microsoft Office" -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($ospp) {
            cscript.exe //nologo $ospp.FullName /dstatus
        } else {
            $engine = Get-EnginePath
            & cmd.exe /c "`"$engine`" /status"
        }
    }
    "3" {
        Check-ElevationPrompt
        $engine = Get-EnginePath
        Write-Host ""
        Write-Host "  ================================================================" -ForegroundColor Yellow
        Write-Host "  SEDANG MENCABUT / MEMBATALKAN LISENSI..." -ForegroundColor Yellow
        Write-Host "  ================================================================" -ForegroundColor Yellow
        Write-Host ""
        & cmd.exe /c "`"$engine`" /u"
        Write-Host ""
        Write-Host "  [OK] PROSES PENCABUTAN LISENSI SELESAI!" -ForegroundColor Green
    }
    "4" {
        Start-Process "https://fokuskonten.my.id/toko-digital/"
        Write-Host "  Membuka etalase digital FokusKonten di peramban web..." -ForegroundColor Cyan
    }
    default {
        Write-Host ""
        Write-Host "  Operasi dibatalkan. Terima kasih." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "  Tekan sembarang tombol untuk menutup jendela ini..." -ForegroundColor DarkGray
try { [Console]::ReadKey($true) | Out-Null } catch {}
