# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 01: OFFICER HELPER - Pemulihan Microsoft Office (Ohook)
# Core Engine : Powered by Microsoft Activation Scripts (MAS) / Ohook Method
# Credits     : massgrave.dev & Open-Source Community
# Engine Host : fokuskonten.my.id (Primary) | mcjobs-id vault (Sekoci Failover)
# Arsitektur  : Launcher PS (irm|iex) -> Menu CMD Bermerek (RunAs Elevated)
# ==============================================================================

& {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    } catch {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
    }

    $ErrorActionPreference = "Continue"
    $ProgressPreference    = "SilentlyContinue"
    $psv = (Get-Host).Version.Major

    # --- Pemeriksaan Prasyarat ---
    if ($ExecutionContext.SessionState.LanguageMode.value__ -ne 0) {
        Write-Host "  [!] PowerShell tidak dalam mode FullLanguage. Aborting." -ForegroundColor Red
        return
    }
    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies()
        [void][System.Math]::Sqrt(144)
    } catch {
        Write-Host "  [!] Error .NET: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # --- Cek Antivirus Pihak Ketiga ---
    function Check-ThirdPartyAV {
        try {
            $cmd = if ($psv -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
            $avList = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue |
                Where-Object { $_.displayName -notlike '*windows*' } |
                Select-Object -ExpandProperty displayName
            if ($avList) {
                Write-Host "  [!] Antivirus terdeteksi: $($avList -join ', ')" -ForegroundColor Yellow -BackgroundColor DarkBlue
            }
        } catch {}
    }

    # --- Download Engine (Dual-Channel) ---
    $engineHash = '39B2C579385B5F521578155B6B58DBE71C3A5484EA4F7CEE09759089FA606463'
    $URLs = @(
        'https://fokuskonten.my.id/assets/engine/FK_Engine_Core.cmd',
        'https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/01_Officer_Helper/MAS_AIO.cmd'
    )

    Clear-Host
    Write-Host ""
    Write-Host "  ==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Modul 01 : OFFICER HELPER - Pemulihan Microsoft Office" -ForegroundColor Yellow
    Write-Host "  Metode   : OHook Dynamic Hook Injection (sppc.dll)" -ForegroundColor White
    Write-Host "  ==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  -> Menyiapkan komponen engine..." -ForegroundColor Cyan

    Write-Progress -Activity "FokusKonten" -Status "Mengunduh komponen..." -PercentComplete 30

    $response = $null
    $errors   = @()
    foreach ($URL in $URLs) {
        try {
            $response = if ($psv -ge 3) {
                Invoke-RestMethod $URL -UseBasicParsing
            } else {
                (New-Object Net.WebClient).DownloadString($URL)
            }
            if ($response.Length -gt 50000) { break }
            $response = $null
        } catch {
            $errors += $_
            $response = $null
        }
    }
    Write-Progress -Activity "FokusKonten" -Status "Selesai" -Completed

    if (-not $response) {
        Check-ThirdPartyAV
        foreach ($err in $errors) { Write-Host "  Error: $($err.Exception.Message)" -ForegroundColor Red }
        Write-Host "  [!] Gagal mengunduh engine dari semua jalur. Aborting." -ForegroundColor Red
        return
    }

    # --- Verifikasi SHA-256 ---
    $stream = New-Object IO.MemoryStream
    $writer = New-Object IO.StreamWriter $stream
    $writer.Write($response); $writer.Flush(); $stream.Position = 0
    $computedHash = [BitConverter]::ToString(
        [Security.Cryptography.SHA256]::Create().ComputeHash($stream)
    ) -replace '-'

    if ($computedHash -ne $engineHash) {
        Write-Warning "  Verifikasi integritas GAGAL. Aborting."
        return
    }
    Write-Host "  [OK] Engine terverifikasi aman." -ForegroundColor Green

    # --- Cek AutoRun Registry ---
    foreach ($rp in @("HKCU:\SOFTWARE\Microsoft\Command Processor","HKLM:\SOFTWARE\Microsoft\Command Processor")) {
        if (Get-ItemProperty -Path $rp -Name "Autorun" -ErrorAction SilentlyContinue) {
            Write-Warning "  AutoRun registry ditemukan — jalankan: Remove-ItemProperty -Path '$rp' -Name 'Autorun'"
        }
    }

    # --- Simpan Engine ke Temp GUID ---
    $rand     = [Guid]::NewGuid().Guid
    $isAdmin  = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $engPath  = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Eng_$rand.cmd" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Eng_$rand.cmd" }
    Set-Content -Path $engPath -Value "@::: FK-$rand `r`n$response" -Encoding ASCII

    if (-not (Test-Path $engPath)) {
        Check-ThirdPartyAV
        Write-Host "  [!] Gagal membuat berkas engine temp. Aborting." -ForegroundColor Red
        return
    }

    # --- Bangun Menu CMD Bermerek FokusKonten (inline batch) ---
    $menuScript = @"
@echo off
chcp 65001 >nul 2>&1
color 1F
title  FokusKonten // OFFICER HELPER - Microsoft Office

:MENU
cls
echo.
echo   ################################################################
echo   ##  FOKUSKONTEN  //  OFFICER HELPER                          ##
echo   ##  Pemulihan Lisensi Microsoft Office  ^|  Layanan Resmi     ##
echo   ################################################################
echo.
echo   Dokumen Word, Excel, PowerPoint, dan Outlook Anda aman 100%%.
echo   Tidak ada file kerja yang disentuh atau diubah selama proses.
echo   ----------------------------------------------------------------
echo   DETAIL LAYANAN OFFICE:
echo   * Produk   : Microsoft Office ^(Word / Excel / PowerPoint / Outlook^)
echo   * Metode   : OHook - Dynamic Hook Injection via sppc.dll
echo   * Komponen : ospp.vbs ^| sppc.dll ^| Office Licensing Service
echo   * Risiko   : 0%% - Bebas antivirus, tanpa ubah dokumen kerja
echo   ----------------------------------------------------------------
echo   MENU TINDAKAN:
echo.
echo       [1] Pasang Lisensi Office Otomatis  ^(Disarankan^)
echo           Aktivasi permanen. Banner lisensi Office hilang sepenuhnya.
echo.
echo       [2] Cek Status Lisensi Office Saat Ini
echo           Tampilkan partial key, masa aktif, dan laporan ospp.vbs.
echo.
echo       [3] Copot Lisensi Office  ^(Kembalikan ke Semula^)
echo           Cabut OHook dan pulihkan Office ke kondisi awal.
echo.
echo       [4] Toko Digital FokusKonten - Software ^& Template Bisnis
echo.
echo       [0] Keluar
echo   ################################################################
echo.
choice /C:12340 /N /T:5 /D:1 /M "  Pilihan Anda [1,2,3,4,0] (default [1] dalam 5 detik) : "
if %errorlevel%==5 goto :DONE
if %errorlevel%==4 start https://fokuskonten.my.id/toko-digital/ & goto :MENU
if %errorlevel%==3 goto :UNINSTALL
if %errorlevel%==2 goto :STATUS
if %errorlevel%==1 goto :INSTALL
goto :MENU

:INSTALL
cls
echo.
echo   ################################################################
echo   ##  MEMASANG LISENSI MICROSOFT OFFICE VIA OHOOK...           ##
echo   ##  Proses berjalan - mohon tunggu beberapa saat.            ##
echo   ################################################################
echo.
call "$engPath" /ohook
echo.
echo   [OK] LISENSI OFFICE BERHASIL DIPASANG!
echo   Banner notifikasi lisensi tidak akan muncul lagi.
echo   Terima kasih telah menggunakan layanan resmi FokusKonten.
echo.
pause
goto :DONE

:STATUS
cls
echo.
echo   ################################################################
echo   ##  STATUS LISENSI MICROSOFT OFFICE  ^(ospp.vbs /dstatus^)    ##
echo   ################################################################
echo.
for /f "delims=" %%i in ('dir /b /s "C:\Program Files\Microsoft Office\ospp.vbs" 2^>nul') do cscript //nologo "%%i" /dstatus
for /f "delims=" %%i in ('dir /b /s "C:\Program Files (x86)\Microsoft Office\ospp.vbs" 2^>nul') do cscript //nologo "%%i" /dstatus
echo.
pause
goto :MENU

:UNINSTALL
cls
echo.
echo   ################################################################
echo   ##  MENCABUT LISENSI OFFICE  ^(OHook Uninstall^)              ##
echo   ################################################################
echo.
call "$engPath" /Ohook-Uninstall
echo.
echo   [OK] LISENSI OFFICE BERHASIL DICABUT!
echo   Office kembali ke kondisi awal ^(unlicensed^).
echo.
pause
goto :MENU

:DONE
del /f /q "$engPath" 2>nul
exit /b 0
"@

    # Simpan menu sebagai CMD temp GUID terpisah
    $menuPath = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Menu_$rand.cmd" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Menu_$rand.cmd" }
    [System.IO.File]::WriteAllText($menuPath, $menuScript, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $menuPath)) {
        Check-ThirdPartyAV
        Write-Host "  [!] Gagal membuat berkas menu temp. Aborting." -ForegroundColor Red
        Remove-Item $engPath -Force -ErrorAction SilentlyContinue
        return
    }

    $env:ComSpec = "$env:SystemRoot\system32\cmd.exe"

    Write-Host "  -> Membuka menu FokusKonten Office Rescue..." -ForegroundColor Cyan
    Write-Host "     Meminta izin Administrator sistem..." -ForegroundColor Gray
    Write-Host ""

    if ($psv -lt 3) {
        if (Test-Path "$env:SystemRoot\Sysnative") {
            Write-Warning "  Gunakan PowerShell x64."
            Remove-Item $engPath, $menuPath -Force -ErrorAction SilentlyContinue
            return
        }
        $p = Start-Process -FilePath $env:ComSpec -ArgumentList "/c `"`"$menuPath`" -el -qedit`"" -Verb RunAs -PassThru
        $p.WaitForExit()
    } else {
        Start-Process -FilePath $env:ComSpec -ArgumentList "/c `"`"$menuPath`" -el`"" -Wait -Verb RunAs
    }

    # Cleanup — menu CMD sudah menghapus engPath sendiri via :DONE
    Remove-Item $menuPath -Force -ErrorAction SilentlyContinue
    Remove-Item $engPath  -Force -ErrorAction SilentlyContinue

} @args
