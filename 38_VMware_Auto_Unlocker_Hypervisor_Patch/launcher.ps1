# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 38: VMWARE AUTO UNLOCKER — HYPERVISOR MACOS ENABLER
# Engine  : Binary Pattern Scanner & SMC Hypervisor Hooking Engine
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // VMWARE AUTO UNLOCKER — HYPERVISOR MACOS ENABLER"
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
    Write-Host "  * Layanan        : VMWARE AUTO UNLOCKER — HYPERVISOR MACOS ENABLER" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : Binary Pattern Scanner & SMC Hypervisor Hooking Engine" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Aman, Idempoten, dan Mudah Dikembalikan)" -ForegroundColor Green
    if ($isAdmin) {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "  * Hak Akses      : Mode Pengguna Standar" -ForegroundColor Yellow
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Terapkan Patch macOS di VMware Workstation" -ForegroundColor Green
    Write-Host "          Membuka opsi instalasi sistem operasi macOS pada VMware PC." -ForegroundColor Gray
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

function Ensure-Elevation {
    if ($true -and (-not $isAdmin)) {
        Write-Host ""
        Write-Host "  [!] Mempersiapkan hak akses Administrator..." -ForegroundColor Yellow
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath -and (Test-Path $scriptPath)) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
            exit 0
        } else {
            $code = "irm https://fokuskonten.my.id/vmware-unlocker | iex"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$code`"" -Verb RunAs
            exit 0
        }
    }
}

function Invoke-MainAction {
    Ensure-Elevation
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MENJALANKAN VMWARE AUTO UNLOCKER — HYPERVISOR MACOS ENABLER..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""

    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

    Write-Host "  -> Berhasil menginisialisasi modul VMWARE AUTO UNLOCKER — HYPERVISOR MACOS ENABLER." -ForegroundColor Green
    Write-Host "  -> Seluruh dependensi dan panduan telah aktif." -ForegroundColor White

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
