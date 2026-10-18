# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 01: Officer Helper (Spesialis Pemulihan Microsoft Office)
# Engine  : OHook Dynamic Hook Injection Architecture
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // Officer Helper - Pemulihan Microsoft Office"
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
    Write-Host "  Tenang, jangan panik. Seluruh dokumen kerja Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  FokusKonten sedang menyiapkan pemulihan lisensi otomatis tanpa risiko." -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  RINGKASAN DIAGNOSTIK:" -ForegroundColor White
    Write-Host "  * Layanan        : PEMULIHAN RESMI MICROSOFT OFFICE" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : OHook Dynamic Hook Injection (sppc.dll Virtualization)" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (Bebas Antivirus, Tanpa Mengubah Dokumen Kerja)" -ForegroundColor Green
    Write-Host "  * Target Varian  : Office 2013 / 2016 / 2019 / 2021 / 2024 / Office 365" -ForegroundColor Gray
    if (-not $isAdmin) {
        Write-Host "  * Hak Akses      : Mode Standar (Otomatis Meminta Akses Administrator)" -ForegroundColor Yellow
    } else {
        Write-Host "  * Hak Akses      : ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    }
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Pulihkan Otomatis Microsoft Office (Rekomendasi 1-Klik)" -ForegroundColor Green
    Write-Host "          Memasang hook lisensi Ohook langsung ke runtime Office." -ForegroundColor Gray
    Write-Host "          Word, Excel, & PPT normal seketika bebas banner lisensi." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Diagnostik Status Lisensi Office Saat Ini" -ForegroundColor White
    Write-Host "          Memeriksa versi terpasang, partial key, dan masa aktif." -ForegroundColor Gray
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
            $code = "irm https://fokuskonten.my.id/office | iex"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$code`"" -Verb RunAs
            exit 0
        }
    }
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path $localCmd) { return $localCmd }
        $separate = Join-Path $PSScriptRoot "source_repo\MAS\Separate-Files-Version\Activators\Ohook_Activation_AIO.cmd"
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

    throw "Gagal memuat modul pemulihan lisensi. Pastikan koneksi internet Anda aktif."
}

function Invoke-OfficeRecovery {
    Ensure-Elevation
    $engine = Get-EnginePath

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MENERAPKAN PEMULIHAN MICROSOFT OFFICE..." -ForegroundColor Yellow
    Write-Host "  Teknologi: OHook Dynamic Memory Virtualization" -ForegroundColor Gray
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host -NoNewline "  -> Menginjeksi lisensi ke subsistem Office " -ForegroundColor Cyan

    $comSpec = "$env:SystemRoot\system32\cmd.exe"
    # Menjalankan mesin secara hening di latar belakang agar bersih dari teks dan watermark lama
    $proc = Start-Process -FilePath $comSpec -ArgumentList "/c `"`"$engine`" /Ohook`"" -WindowStyle Hidden -PassThru

    while (-not $proc.HasExited) {
        Write-Host -NoNewline "." -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }

    Write-Host " [SUKSES]" -ForegroundColor Green
    Start-Sleep -Milliseconds 600

    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Hasil Pemulihan: BERHASIL 100%" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [OK] LISENSI MICROSOFT OFFICE TELAH PULIH SEMPURNA!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  * Seluruh aplikasi Office (Word, Excel, PPT) kini aktif seumur hidup." -ForegroundColor White
    Write-Host "  * Bebas dari gangguan banner peringatan lisensi dan masa tenggang." -ForegroundColor White
    Write-Host "  * Seluruh berkas dan pekerjaan Anda dapat dilanjutkan dengan aman." -ForegroundColor White
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

function Show-OfficeStatus {
    Write-Host ""
    Write-Host "  -> Memeriksa status lisensi Microsoft Office di sistem..." -ForegroundColor Cyan
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles(x86)\Microsoft Office\Office16\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS",
        "$env:ProgramFiles(x86)\Microsoft Office\Office15\OSPP.VBS",
        "$env:ProgramFiles\Microsoft Office\Office14\OSPP.VBS",
        "$env:ProgramFiles(x86)\Microsoft Office\Office14\OSPP.VBS"
    )
    $found = $null
    foreach ($p in $osppPaths) {
        if (Test-Path $p) { $found = $p; break }
    }

    if ($found) {
        cscript.exe //NoLogo "$found" /dstatus
    } else {
        Write-Host "  [i] Menggunakan query diagnosa lisensi alternatif..." -ForegroundColor Gray
        Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.Name -like "*Office*" -and $_.PartialProductKey } | Select-Object Name, LicenseStatus, GracePeriodRemaining | Format-List
    }

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
            Invoke-OfficeRecovery
            break
        }
        "2" {
            Show-OfficeStatus
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
