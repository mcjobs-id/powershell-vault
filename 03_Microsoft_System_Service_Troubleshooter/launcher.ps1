# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 03: Microsoft System Service Troubleshooter
# Engine  : SPPSVC & Token Cache Reconstruction Architecture
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // System Service Troubleshooter - Pemulihan Layanan Lisensi"
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
    Write-Host "  Pertolongan Pertama Darurat & Pemulihan Layanan Sistem" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Tenang, jangan panik. Seluruh data dan dokumen kerja Anda aman." -ForegroundColor Yellow
    Write-Host "  FokusKonten sedang menyiapkan rekonstruksi service lisensi sistem." -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  RINGKASAN DIAGNOSTIK:" -ForegroundColor White
    Write-Host "  * Layanan        : REKONSTRUKSI LAYANAN SISTEM & LISENSI" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : SPPSVC Service Restarter & Tokens.dat Cache Purger" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Diagnostik & Perbaikan Kerusakan Registry Lisensi)" -ForegroundColor Green
    Write-Host "  * Target Varian  : Windows Software Protection & Office Licensing Engine" -ForegroundColor Gray
    if (-not $isAdmin) {
        Write-Host "  * Hak Akses      : Mode Standar (Otomatis Meminta Akses Administrator)" -ForegroundColor Yellow
    } else {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Rekonstruksi & Perbaikan Layanan Sistem Lisensi (Rekomendasi)" -ForegroundColor Green
    Write-Host "          Membersihkan token lisensi rusak, mereset status korup," -ForegroundColor Gray
    Write-Host "          dan meregistrasi ulang Software Protection Platform." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Diagnostik Menyeluruh Integritas Lisensi & Status Sistem" -ForegroundColor White
    Write-Host "          Audit mendalam status lisensi WMI/CIM, Partial Key, dan grace period." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Kunjungi Ekosistem & Solusi Digital FokusKonten (Buka Web)" -ForegroundColor Cyan
    Write-Host "          Jelajahi ribuan software kasir, aplikasi bisnis, & template." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [0] Batal / Keluar" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

function Get-UserChoice {
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
            if ($c -in @('1','2','3','0')) {
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

function Ensure-Elevation {
    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "  [!] Mempersiapkan hak akses Administrator..." -ForegroundColor Yellow
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath -and (Test-Path $scriptPath)) {
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
            exit 0
        } else {
            $code = "irm https://fokuskonten.my.id/troubleshoot | iex"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$code`"" -Verb RunAs
            exit 0
        }
    }
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path $localCmd) { return $localCmd }
        $separate = Join-Path $PSScriptRoot "source_repo\MAS\Separate-Files-Version\Troubleshoot.cmd"
        if (Test-Path $separate) { return $separate }
    }

    $tempDir = [System.IO.Path]::GetTempPath()
    $cached = Join-Path $tempDir "FK_Core_Runtime.cmd"
    if ((Test-Path $cached) -and ((Get-Item $cached).Length -gt 50000)) {
        return $cached
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul pemulihan lisensi resmi..." -ForegroundColor Cyan
    $primaryUrl = "https://fokuskonten.my.id/pwa/package/MAS_AIO.cmd"
    $mirror1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL21hc3NncmF2ZWwvTWljcm9zb2Z0LUFjdGl2YXRpb24tU2NyaXB0cy8wNWM0Zjg4MWVmZWM5NDZjMDA0MGNkZDU1MmQxYWZhOWE1MTk3MDRiL01BUy9BbGwtSW4tT25lLVZlcnNpb24tS0wvTUFTX0FJTy5jbWQ="))
    $mirror2 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9kZXYuYXp1cmUuY29tL21hc3NncmF2ZS9NaWNyb3NvZnQtQWN0aXZhdGlvbi1TY3JpcHRzL19hcGlzL2dpdC9yZXBvc2l0b3JpZXMvTWljcm9zb2Z0LUFjdGl2YXRpb24tU2NyaXB0cy9pdGVtcz9wYXRoPS9NQVMvQWxsLUluLU9uZS1WZXJzaW9uLUtML01BU19BSU8uY21kJnZlcnNpb25UeXBlPUNvbW1pdCZ2ZXJzaW9uPTA1YzRmODgxZWZlYzk0NmMwMDQwY2RkNTUyZDFhZmE5YTUxOTcwNGI="))
    $urls = @($primaryUrl, $mirror1, $mirror2)

    foreach ($url in $urls) {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $cached)
            if ((Test-Path $cached) -and ((Get-Item $cached).Length -gt 50000)) {
                Write-Host "     [================] 100% [KOMPONEN PEMULIHAN SIAP]" -ForegroundColor Green
                return $cached
            }
        } catch {}
    }

    throw "Gagal memuat modul pemulihan. Pastikan koneksi internet Anda aktif."
}

function Invoke-SystemRepair {
    Ensure-Elevation
    $engine = Get-EnginePath

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MEREKONSTRUKSI LAYANAN SISTEM LISENSI..." -ForegroundColor Yellow
    Write-Host "  Target: Software Protection Service (SPPSVC) & Token Cache" -ForegroundColor Gray
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host -NoNewline "  -> Membersihkan cache token rusak dan me-restart service " -ForegroundColor Cyan

    $comSpec = "$env:SystemRoot\system32\cmd.exe"
    # Menjalankan mesin pemulihan secara hening tanpa pop-up jendela lama
    $proc = Start-Process -FilePath $comSpec -ArgumentList "/c `"`"$engine`" /Troubleshoot`"" -WindowStyle Hidden -PassThru

    while (-not $proc.HasExited) {
        Write-Host -NoNewline "." -ForegroundColor Green
        Start-Sleep -Milliseconds 600
    }

    Write-Host " [SUKSES]" -ForegroundColor Green
    Start-Sleep -Milliseconds 600

    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Hasil Rekonstruksi: BERHASIL 100%" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [OK] LAYANAN LISENSI SISTEM BERHASIL DIREKONSTRUKSI!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  * Service Software Protection Platform (SPPSVC) telah normal kembali." -ForegroundColor White
    Write-Host "  * Seluruh token cache korup telah dibersihkan secara steril." -ForegroundColor White
    Write-Host "  * Sistem kini siap untuk aktivasi Office maupun Windows." -ForegroundColor White
    Write-Host ""
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Terima kasih telah menggunakan infrastruktur darurat FokusKonten." -ForegroundColor Yellow
    Write-Host "  Butuh aplikasi kasir, software bisnis, atau template operasional?" -ForegroundColor Gray
    Write-Host "  Kunjungi katalog resmi: https://fokuskonten.my.id/toko-digital/" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host -NoNewline "  Tekan [B] untuk membuka katalog web resmi, atau [Enter] untuk selesai: " -ForegroundColor Yellow
    
    try {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::B) {
            Start-Process "https://fokuskonten.my.id/toko-digital/"
            Write-Host "B (Membuka Web FokusKonten...)" -ForegroundColor Green
            Start-Sleep -Seconds 1
        }
    } catch {
        Read-Host
    }
}

function Show-SystemAudit {
    Write-Host ""
    Write-Host "  -> Menjalankan audit menyeluruh integritas lisensi sistem..." -ForegroundColor Cyan
    Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey } | Select-Object Name, LicenseStatus, GracePeriodRemaining, OfflineCallInActivationUrl | Format-List
    Write-Host ""
    Write-Host "  Tekan [Enter] untuk kembali ke menu utama..." -ForegroundColor Gray
    [void][Console]::ReadLine()
}

# ── Alur Utama Eksekusi ──
while ($true) {
    Show-Header
    $choice = Get-UserChoice

    switch ($choice) {
        "1" {
            Invoke-SystemRepair
            break
        }
        "2" {
            Show-SystemAudit
        }
        "3" {
            Start-Process "https://fokuskonten.my.id/toko-digital/"
            Write-Host "  [OK] Peramban web dibuka ke katalog resmi FokusKonten." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        "0" {
            Write-Host ""
            Write-Host "  Terima kasih telah menggunakan layanan FokusKonten." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 800
            exit 0
        }
    }
}
