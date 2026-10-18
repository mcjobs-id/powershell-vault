# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 03: SYSTEM SERVICE TROUBLESHOOTER - Reparasi SPPSVC & WMI
# Metode    : 100% Native Windows Engine (Zero External Dependency)
# Arsitektur: Launcher PS (irm|iex) -> Menu PS Elevated (RunAs, .ps1 temp GUID)
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

    Clear-Host
    Write-Host ""
    Write-Host "  ==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Modul 03 : SYSTEM SERVICE TROUBLESHOOTER" -ForegroundColor Yellow
    Write-Host "  Metode   : Native Windows Engine (100% Tanpa Ketergantungan)" -ForegroundColor White
    Write-Host "  ==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  -> Menyiapkan engine reparasi lokal..." -ForegroundColor Cyan

    # --- Bangun repair script PS1 sebagai inline string ---
    $repairPs1 = @'
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "FokusKonten // SYSTEM SERVICE TROUBLESHOOTER"
try { $Host.UI.RawUI.BackgroundColor = 'DarkRed'; $Host.UI.RawUI.ForegroundColor = 'White'; Clear-Host } catch {}

function Repair-Services {
    cls
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  SEDANG MEMPERBAIKI LAYANAN SISTEM (SPPSVC, ClipSVC, WMI)..." -ForegroundColor Yellow
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""
    $svcs = @("DcomLaunch","RpcSs","KeyIso","Winmgmt","ClipSVC","LicenseManager","sppsvc")
    foreach ($s in $svcs) {
        try {
            Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $s -ErrorAction SilentlyContinue
            $st = (Get-Service -Name $s -ErrorAction SilentlyContinue).Status
            $c  = if ($st -eq "Running") { "Green" } else { "Yellow" }
            Write-Host ("  [OK] {0,-18}: {1}" -f $s, $st) -ForegroundColor $c
        } catch { Write-Host "  [!] $s : $($_.Exception.Message)" -ForegroundColor Red }
    }
    Write-Host ""
    Write-Host "  -> Re-register pustaka lisensi sistem..." -ForegroundColor Cyan
    foreach ($dll in @("slwga.dll","sppc.dll","systemcpc.dll")) {
        $p = Join-Path $env:SystemRoot "System32\$dll"
        if (Test-Path $p) {
            $r = Start-Process regsvr32.exe -ArgumentList "/s `"$p`"" -Wait -PassThru -NoNewWindow
            Write-Host ("  [{0}] {1}" -f $(if($r.ExitCode -eq 0){"OK"}else{"--"}), $dll) -ForegroundColor $(if($r.ExitCode -eq 0){"Green"}else{"DarkGray"})
        }
    }
    Write-Host ""
    Write-Host "  [OK] REPARASI LAYANAN SELESAI!" -ForegroundColor Green
    Write-Host "  Disarankan restart PC agar semua perubahan aktif penuh." -ForegroundColor Gray
    Write-Host ""
    pause
}

function Show-Diagnostics {
    cls
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  DIAGNOSTIK STATUS LAYANAN & WMI" -ForegroundColor Green
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host ""
    foreach ($s in @("sppsvc","ClipSVC","Winmgmt","KeyIso","LicenseManager","RpcSs")) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            $c = if ($svc.Status -eq "Running") { "Green" } else { "Yellow" }
            Write-Host ("  * {0,-18}: {1,-12} [Start: {2}]" -f $s, $svc.Status, $svc.StartType) -ForegroundColor $c
        } else {
            Write-Host ("  * {0,-18}: TIDAK DITEMUKAN" -f $s) -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "  * Uji WMI Repository..." -ForegroundColor Cyan
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "  [OK] WMI Normal: $($os.Caption) Build $($os.BuildNumber)" -ForegroundColor Green
    } catch {
        Write-Host "  [!] WMI Bermasalah: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    pause
}

function Repair-SystemFiles {
    cls
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Yellow
    Write-Host "  DISM RESTORE HEALTH + SFC SCANNOW" -ForegroundColor Yellow
    Write-Host "  Proses ini membutuhkan beberapa menit. Jangan tutup jendela." -ForegroundColor Gray
    Write-Host "  ================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1/2] DISM RestoreHealth..." -ForegroundColor Cyan
    DISM.exe /Online /Cleanup-Image /RestoreHealth
    Write-Host ""
    Write-Host "  [2/2] SFC Scannow..." -ForegroundColor Cyan
    sfc.exe /scannow
    Write-Host ""
    Write-Host "  [OK] PEMULIHAN FILE SISTEM SELESAI!" -ForegroundColor Green
    Write-Host ""
    pause
}

# Main menu loop
while ($true) {
    cls
    Write-Host ""
    Write-Host "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Yellow
    Write-Host "  !!  FOKUSKONTEN  //  SYSTEM SERVICE TROUBLESHOOTER            !!" -ForegroundColor Yellow
    Write-Host "  !!  Perbaikan Darurat Layanan Lisensi Windows                 !!" -ForegroundColor White
    Write-Host "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Terdeteksi gangguan pada layanan lisensi sistem Anda." -ForegroundColor Red
    Write-Host "  FokusKonten akan memperbaiki fondasi sistem sebelum proses lanjut." -ForegroundColor White
    Write-Host "  ------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  DETAIL LAYANAN REPAIR:" -ForegroundColor White
    Write-Host "  * Layanan  : SYSTEM SERVICE TROUBLESHOOTER - PERBAIKAN SPPSVC" -ForegroundColor Cyan
    Write-Host "  * Engine   : 100% NATIVE WINDOWS (TANPA KETERGANTUNGAN EKSTERNAL)" -ForegroundColor Green
    Write-Host "  * Target   : sppsvc, ClipSVC, Winmgmt (WMI), KeyIso, LicenseManager" -ForegroundColor White
    Write-Host "  * Error    : 0x80070422 / 0x80070005 / 0x80004005 / Service Stopped" -ForegroundColor Red
    Write-Host "  ------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  MENU TINDAKAN DARURAT:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Perbaiki Layanan SPPSVC & Reset Token Lisensi (1-Klik)" -ForegroundColor Yellow
    Write-Host "          Mengatasi error 0x80070422, 0x80070005, atau service berhenti." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Diagnostik Status Layanan Sistem & WMI" -ForegroundColor White
    Write-Host "          Memeriksa kesehatan sppsvc, ClipSVC, dan WMI Repository." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Pemulihan File Sistem (DISM + SFC Scan)" -ForegroundColor White
    Write-Host "          Memperbaiki file Windows corrupt yang menghambat perbaikan." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Toko Digital FokusKonten - Software & Template Bisnis" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      [0] Keluar" -ForegroundColor DarkGray
    Write-Host "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Yellow
    Write-Host ""

    try {
        Write-Host -NoNewline "  Pilihan Anda [1,2,3,4,0] : " -ForegroundColor Green
        $k = [Console]::ReadKey($true)
        $c = $k.KeyChar.ToString()
        Write-Host $c -ForegroundColor Green
    } catch {
        $c = Read-Host "  Pilihan"
    }

    switch ($c) {
        "1" { Repair-Services }
        "2" { Show-Diagnostics }
        "3" { Repair-SystemFiles }
        "4" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
        "0" { exit 0 }
    }
}
'@

    # Simpan sebagai PS1 temp GUID
    $rand    = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $ps1Path = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Repair_$rand.ps1" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Repair_$rand.ps1" }
    [System.IO.File]::WriteAllText($ps1Path, $repairPs1, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $ps1Path)) {
        Write-Host "  [!] Gagal membuat berkas repair temp. Aborting." -ForegroundColor Red
        return
    }

    $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    Write-Host "  [OK] Engine reparasi lokal siap." -ForegroundColor Green
    Write-Host "  -> Membuka menu FokusKonten Troubleshooter..." -ForegroundColor Cyan
    Write-Host "     Meminta izin Administrator sistem..." -ForegroundColor Gray
    Write-Host ""

    if ($psv -ge 3) {
        Start-Process -FilePath $pwsh `
            -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$ps1Path`"" `
            -Verb RunAs -Wait
    } else {
        $p = Start-Process -FilePath $pwsh `
            -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$ps1Path`"" `
            -Verb RunAs -PassThru
        $p.WaitForExit()
    }

    Remove-Item $ps1Path -Force -ErrorAction SilentlyContinue

} @args
