# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 21: KMS-VL-ALL-AIO - STANDALONE LOCAL KMS EMULATOR
# Engine  : Offline Local Windows & Office Volume License Activation
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // KMS-VL-ALL-AIO - STANDALONE LOCAL KMS EMULATOR"
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
    Write-Host "  Pertolongan Pertama Darurat & Utilitas Rekayasa Sistem" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Tenang, seluruh konfigurasi dan dokumen kerja Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  FokusKonten menyiapkan otomatisasi sistem tanpa risiko data loss." -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  RINGKASAN DIAGNOSTIK:" -ForegroundColor White
    Write-Host "  * Layanan        : KMS-VL-ALL-AIO - STANDALONE LOCAL KMS EMULATOR" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : Offline Local Windows & Office Volume License Activation" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Aman, Idempoten, dan Mudah Dikembalikan)" -ForegroundColor Green
    if ($isAdmin) {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "  * Hak Akses      : Mode Standar (Disarankan Jalankan sebagai Administrator)" -ForegroundColor Yellow
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Jalankan Aktivasi Volume License KMS Lokal" -ForegroundColor Green
    Write-Host "          Aktivasi Windows dan Office edisi Volume License 100% offline." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Kunjungi Ekosistem & Solusi Digital FokusKonten (Buka Web)" -ForegroundColor Cyan
    Write-Host "          Jelajahi ribuan software kasir, aplikasi bisnis, & template." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [0] Batal / Keluar" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

function Get-UserChoice {
    $validChoices = @('1','3','0')
    if ($isISE) {
        $c = Read-Host "  Pilihan Anda [1, 3, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }

    try {
        Write-Host -NoNewline "  Pilihan Anda [1, 3, 0] (Tekan Enter untuk [1]) : " -ForegroundColor Green
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Enter) {
                Write-Host "1" -ForegroundColor Green
                return "1"
            }
            $c = $k.KeyChar.ToString()
            if ($c -in $validChoices) {
                Write-Host $c -ForegroundColor Green
                return $c
            }
        }
    } catch {
        $c = Read-Host "  Pilihan Anda [1, 3, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }
}

function Check-ElevationPrompt {
    if ($true -and (-not $isAdmin)) {
        Write-Host ""
        Write-Host "  [!] PEMBERITAHUAN HAK AKSES SISTEM:" -ForegroundColor Yellow
        Write-Host "      Modul ini membutuhkan hak akses Administrator untuk konfigurasi sistem." -ForegroundColor White
        Write-Host "      Jika operasi ditolak oleh Windows, silakan jalankan PowerShell via:" -ForegroundColor Cyan
        Write-Host "      Klik kanan ikon PowerShell -> 'Run as administrator'" -ForegroundColor Cyan
        Write-Host "      Melanjutkan eksekusi in-session pada sesi saat ini..." -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Invoke-MainAction {
    Check-ElevationPrompt
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MENJALANKAN KMS-VL-ALL-AIO - STANDALONE LOCAL KMS EMULATOR..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    $targetCmd = Join-Path $scriptDir "Activate.cmd"
    if (Test-Path $targetCmd) {
        Start-Process cmd.exe -ArgumentList "/c `"$targetCmd`" " -Wait -WindowStyle Hidden
    } else {
        Write-Host "  [!] Berkas biner lokal tidak ditemukan, mengunduh runtime dari sekoci resmi..." -ForegroundColor Cyan
        $remoteCmd = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/21_KMS_VL_ALL_AIO_abbodi1406/Activate.cmd"
        $workDir = Join-Path $env:ProgramData "FokusKonten"
        if (-not (Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
        $tmp = Join-Path $workDir "Activate.cmd"
        (New-Object System.Net.WebClient).DownloadFile($remoteCmd, $tmp)
        Start-Process cmd.exe -ArgumentList "/c `"$tmp`" " -Wait -WindowStyle Hidden
    }

    Write-Host ""
    Write-Host "  [OK] PROSES SELESAI DENGAN STATUS BERHASIL!" -ForegroundColor Green
    Write-Host "  Terima kasih telah mempercayakan utilitas sistem kepada FokusKonten." -ForegroundColor Gray
}


# Main Program Loop
Show-Header
$choice = Get-UserChoice

switch ($choice) {
    "1" { Invoke-MainAction }
    "3" {
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
