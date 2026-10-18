# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 02: MICROSOFT HELPER - Lisensi Digital Windows (HWID)
# Core Engine : Powered by Microsoft Activation Scripts (MAS) / HWID Method
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

    $engineHash = '39B2C579385B5F521578155B6B58DBE71C3A5484EA4F7CEE09759089FA606463'
    $URLs = @(
        'https://fokuskonten.my.id/assets/engine/FK_Engine_Core.cmd',
        'https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/02_Microsoft_Helper/MAS_AIO.cmd'
    )

    Clear-Host
    Write-Host ""
    Write-Host "  ==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Modul 02 : MICROSOFT HELPER - Lisensi Digital Windows (HWID)" -ForegroundColor Yellow
    Write-Host "  Metode   : Hardware ID Ticket Registration (ClipSVC Permanent)" -ForegroundColor White
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

    foreach ($rp in @("HKCU:\SOFTWARE\Microsoft\Command Processor","HKLM:\SOFTWARE\Microsoft\Command Processor")) {
        if (Get-ItemProperty -Path $rp -Name "Autorun" -ErrorAction SilentlyContinue) {
            Write-Warning "  AutoRun registry ditemukan — jalankan: Remove-ItemProperty -Path '$rp' -Name 'Autorun'"
        }
    }

    $rand    = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $engPath = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Eng_$rand.cmd" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Eng_$rand.cmd" }
    Set-Content -Path $engPath -Value "@::: FK-$rand `r`n$response" -Encoding ASCII

    if (-not (Test-Path $engPath)) {
        Check-ThirdPartyAV
        Write-Host "  [!] Gagal membuat berkas engine temp. Aborting." -ForegroundColor Red
        return
    }

    $menuScript = @"
@echo off
chcp 65001 >nul 2>&1
color 0A
title  FokusKonten // MICROSOFT HELPER - Lisensi Digital Windows

:MENU
cls
echo.
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo   >>  FOKUSKONTEN  //  MICROSOFT HELPER                        >>
echo   >>  Pendaftaran Lisensi Digital Windows  ^|  HWID Method      >>
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo.
echo   Lisensi Windows akan terdaftar permanen ke motherboard PC ini.
echo   Berlaku selamanya - bahkan setelah Windows diinstal ulang.
echo   ----------------------------------------------------------------
echo   DETAIL LAYANAN WINDOWS:
echo   * Produk   : Microsoft Windows 10 / 11 ^(Home / Pro / Education^)
echo   * Metode   : HWID - Hardware ID Ticket Registration via ClipSVC
echo   * Komponen : ClipSVC ^| LicenseManager ^| slmgr.vbs
echo   * Sifat    : Permanen terikat motherboard, bebas aktivasi ulang
echo   ----------------------------------------------------------------
echo   MENU TINDAKAN:
echo.
echo       [1] Daftarkan Lisensi HWID Windows Permanen  ^(Disarankan^)
echo           Terhubung ke server Microsoft - proses 10-30 detik.
echo.
echo       [2] Cek Status Lisensi Windows Saat Ini
echo           Tampilkan jenis lisensi, masa aktif, dan channel ID.
echo.
echo       [3] Hapus Kunci Lisensi  ^(Reset ke Belum Aktif^)
echo           Jalankan slmgr /upk dan /cpky untuk reset total.
echo.
echo       [4] Toko Digital FokusKonten - Software ^& Template Bisnis
echo.
echo       [0] Keluar
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo   >>  MENDAFTARKAN LISENSI DIGITAL WINDOWS  ^(HWID^)...          >>
echo   >>  Menghubungi server aktivasi Microsoft...                  >>
echo   >>  Mohon tunggu 10-30 detik. Jangan tutup jendela ini.      >>
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo.
call "$engPath" /hwid
echo.
echo   [OK] LISENSI WINDOWS BERHASIL DIDAFTARKAN!
echo   Lisensi ini permanen dan terikat ke motherboard PC Anda.
echo   Terima kasih telah menggunakan layanan resmi FokusKonten.
echo.
pause
goto :DONE

:STATUS
cls
echo.
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo   >>  STATUS LISENSI WINDOWS  ^(slmgr.vbs^)                     >>
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo.
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /xpr
echo.
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /dli
echo.
pause
goto :MENU

:UNINSTALL
cls
echo.
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo   >>  MENGHAPUS KUNCI LISENSI WINDOWS...                       >>
echo   >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
echo.
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /upk
cscript //nologo "%SystemRoot%\System32\slmgr.vbs" /cpky
echo.
echo   [OK] KUNCI LISENSI WINDOWS BERHASIL DIHAPUS!
echo   Windows kembali ke status belum aktif.
echo.
pause
goto :MENU

:DONE
del /f /q "$engPath" 2>nul
exit /b 0
"@

    $menuPath = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Menu_$rand.cmd" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Menu_$rand.cmd" }
    [System.IO.File]::WriteAllText($menuPath, $menuScript, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $menuPath)) {
        Check-ThirdPartyAV
        Write-Host "  [!] Gagal membuat berkas menu temp. Aborting." -ForegroundColor Red
        Remove-Item $engPath -Force -ErrorAction SilentlyContinue
        return
    }

    $env:ComSpec = "$env:SystemRoot\system32\cmd.exe"

    # Jika terminal SUDAH Administrator, jalankan langsung in-place (CUKUP 1 TERMINAL)
    if ($isAdmin) {
        Write-Host "  [OK] Hak akses Administrator terverifikasi (Eksekusi 1 Terminal)." -ForegroundColor Green
        & $env:ComSpec /c "`"$menuPath`""
        Remove-Item $menuPath -Force -ErrorAction SilentlyContinue
        Remove-Item $engPath  -Force -ErrorAction SilentlyContinue
        return
    }

    Write-Host "  -> Membuka menu FokusKonten Windows License..." -ForegroundColor Cyan
    Write-Host "     Meminta izin Administrator sistem (UAC)..." -ForegroundColor Gray
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

    Remove-Item $menuPath -Force -ErrorAction SilentlyContinue
    Remove-Item $engPath  -Force -ErrorAction SilentlyContinue

} @args
