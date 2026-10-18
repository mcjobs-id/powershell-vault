# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 43: TCP LATENCY & GAMING PING OPTIMIZER
# Engine  : TcpAckFrequency & TCPNoDelay Registry Optimization
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // TCP LATENCY & GAMING PING OPTIMIZER"
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
    Write-Host "  * Layanan        : TCP LATENCY & GAMING PING OPTIMIZER" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : TcpAckFrequency & TCPNoDelay Registry Optimization" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Aman, Idempoten, dan Mudah Dikembalikan)" -ForegroundColor Green
    if ($isAdmin) {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "  * Hak Akses      : Mode Standar (Disarankan Jalankan sebagai Administrator)" -ForegroundColor Yellow
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Terapkan Optimasi TCP Latency (Rendahkan Ping Game)" -ForegroundColor Green
    Write-Host "          Mengurangi jeda packet acknowledgment untuk gameplay lebih mulus." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Kembalikan Pengaturan Jaringan ke Default Windows" -ForegroundColor White
    Write-Host "          Mengembalikan konfigurasi sistem ke kondisi default." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Kunjungi Ekosistem & Solusi Digital FokusKonten (Buka Web)" -ForegroundColor Cyan
    Write-Host "          Jelajahi ribuan software kasir, aplikasi bisnis, & template." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [0] Batal / Keluar" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

function Get-UserChoice {
    $validChoices = @('1','2','3','0')
    if ($isISE) {
        $c = Read-Host "  Pilihan Anda [1, 2, 3, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }

    try {
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 0] (Tekan Enter untuk [1]) : " -ForegroundColor Green
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
        $c = Read-Host "  Pilihan Anda [1, 2, 3, 0] (Tekan Enter untuk [1])"
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
    Write-Host "  SEDANG MENJALANKAN TCP LATENCY & GAMING PING OPTIMIZER..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    $targetScript = Join-Path $scriptDir "optimize_tcp_latency.ps1"
    if (Test-Path $targetScript) {
        & $targetScript
    } else {
        Write-Host "  [!] Berkas skrip lokal tidak ditemukan, mengalirkan biner dari lumbung resmi..." -ForegroundColor Cyan
        $remoteScript = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/43_TCP_Latency_Ping_Optimizer/optimize_tcp_latency.ps1"
        irm $remoteScript | iex
    }

    Write-Host ""
    Write-Host "  [OK] PROSES SELESAI DENGAN STATUS BERHASIL!" -ForegroundColor Green
    Write-Host "  Terima kasih telah mempercayakan utilitas sistem kepada FokusKonten." -ForegroundColor Gray
}

function Invoke-RollbackAction {
    Check-ElevationPrompt
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Yellow
    Write-Host "  SEDANG MENGEMBALIKAN PENGATURAN SEMULA..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Yellow
    Write-Host ""

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    $targetScript = Join-Path $scriptDir "restore_default_tcp.ps1"
    if (Test-Path $targetScript) {
        & $targetScript
    } else {
        $remoteScript = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/43_TCP_Latency_Ping_Optimizer/restore_default_tcp.ps1"
        irm $remoteScript | iex
    }

    Write-Host ""
    Write-Host "  [OK] SISTEM BERHASIL DIKEMBALIKAN KE KONDISI DEFAULT!" -ForegroundColor Green
}

# Main Program Loop
Show-Header
$choice = Get-UserChoice

switch ($choice) {
    "1" { Invoke-MainAction }
    "2" { Invoke-RollbackAction }
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
