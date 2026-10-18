# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 39: ADOBE SHIELD - Genuine Service Blocker & Anti Pop-Up
# Metode    : Outbound Windows Firewall Rule & Hosts Null-Routing
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
    Write-Host "  /////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Red
    Write-Host "  Modul 39 : ADOBE SHIELD - Anti Pop-Up Unlicensed App" -ForegroundColor Yellow
    Write-Host "  Metode   : AGSService Disable & Outbound Firewall Isolation" -ForegroundColor White
    Write-Host "  /////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""
    Write-Host "  -> Menyiapkan proteksi Adobe Creative Cloud..." -ForegroundColor Cyan

    $adobePs1 = @'
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "FokusKonten // ADOBE SHIELD - Anti Pop-Up Unlicensed"
try { $Host.UI.RawUI.BackgroundColor = 'Black'; $Host.UI.RawUI.ForegroundColor = 'White'; Clear-Host } catch {}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$adobeDomains = @(
    "lmlicenses.wip4.adobe.com",
    "lm.licenses.adobe.com",
    "na1r.services.adobe.com",
    "hlrcv.stage.adobe.com",
    "genuine.adobe.com",
    "prod.adobegenuine.com",
    "ic.adobe.io",
    "cc-api-data.adobe.io"
)
$adobeApps = @(
    "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Service\Adobe Desktop Service.exe",
    "C:\Program Files (x86)\Common Files\Adobe\Adobe Genuine Software Integrity Service\AGSService.exe",
    "C:\Program Files\Common Files\Adobe\Adobe Desktop Service\Adobe Desktop Service.exe",
    "C:\Program Files\Common Files\Adobe\Adobe Genuine Software Integrity Service\AGSService.exe",
    "C:\Program Files (x86)\Adobe\Adobe Creative Cloud\ACC\Creative Cloud.exe"
)

function Enable-AdobeShield {
    cls
    Write-Host ""
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host "  MEMASANG PROTEKSI ANTI POP-UP ADOBE CREATIVE CLOUD..." -ForegroundColor Yellow
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""

    # 1. Hentikan dan nonaktifkan layanan Genuine Software Integrity
    Write-Host "  [1/3] Mematikan layanan Adobe Genuine Software Integrity (AGSService)..." -ForegroundColor Cyan
    $svcs = @("AGSService", "AdobeUpdateService", "CCXProcess", "AdobeARMservice")
    foreach ($s in $svcs) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
            Set-Service  -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  [OK] Service $s dihentikan dan dinonaktifkan." -ForegroundColor Green
        }
    }

    # Hentikan proses yang sedang berjalan di background
    foreach ($p in @("AGSService", "Adobe Desktop Service", "CCXProcess")) {
        $pr = Get-Process -Name $p -ErrorAction SilentlyContinue
        if ($pr) {
            Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Tambahkan aturan Windows Firewall Outbound
    Write-Host ""
    Write-Host "  [2/3] Menerapkan aturan Windows Firewall Outbound..." -ForegroundColor Cyan
    foreach ($app in $adobeApps) {
        if (Test-Path $app) {
            $leaf = Split-Path $app -Leaf
            $ruleName = "FokusKonten_Block_" + $leaf
            netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
            netsh advfirewall firewall add rule name="$ruleName" dir=out action=block program="$app" enable=yes | Out-Null
            Write-Host "  [OK] Blokir firewall aktif: $leaf" -ForegroundColor Green
        }
    }

    # 3. Suntikkan pemetaan host null
    Write-Host ""
    Write-Host "  [3/3] Menyuntikkan pemetaan domain pelacak Adobe ke hosts..." -ForegroundColor Cyan
    $hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    $append = ""
    foreach ($d in $adobeDomains) {
        if ($hostsContent -notmatch [regex]::Escape($d)) {
            $append += "`r`n0.0.0.0 $d"
        }
    }
    if ($append -ne "") {
        Add-Content -Path $hostsPath -Value $append -ErrorAction SilentlyContinue
        Write-Host "  [OK] 8 domain validasi lisensi Adobe diarahkan ke 0.0.0.0." -ForegroundColor Green
    } else {
        Write-Host "  * Seluruh domain validasi Adobe sudah diblokir sebelumnya." -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host "  [SUKSES] PROTEKSI ADOBE SHIELD AKTIF!" -ForegroundColor Green
    Write-Host "  * Notifikasi 'This unlicensed app will be disabled soon' hilang." -ForegroundColor White
    Write-Host "  * Photoshop, Illustrator, Premiere, dll. dapat dipakai tanpa interupsi." -ForegroundColor Yellow
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""
    pause
}

function Show-AdobeStatus {
    cls
    Write-Host ""
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host "  DIAGNOSTIK STATUS PROTEKSI ADOBE CREATIVE CLOUD" -ForegroundColor Red
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""

    # Layanan Adobe
    Write-Host "  * Status Layanan Integritas Adobe:" -ForegroundColor Cyan
    foreach ($s in @("AGSService", "AdobeUpdateService", "AdobeARMservice")) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            $c = if ($svc.StartType -eq "Disabled") { "Green" } else { "Yellow" }
            Write-Host ("    - {0,-20} : {1,-10} [Startup: {2}]" -f $s, $svc.Status, $svc.StartType) -ForegroundColor $c
        } else {
            Write-Host "    - $s : (Tidak terpasang di sistem)" -ForegroundColor Gray
        }
    }

    # Aturan Firewall
    Write-Host ""
    Write-Host "  * Aturan Windows Firewall:" -ForegroundColor Cyan
    $rules = netsh advfirewall firewall show rule name=all | Select-String "FokusKonten_Block_AGSService|FokusKonten_Block_Adobe"
    if ($rules) {
        Write-Host "    [OK] Aturan isolasi firewall Adobe terdeteksi aktif." -ForegroundColor Green
    } else {
        Write-Host "    [!] Aturan isolasi firewall Adobe belum terpasang." -ForegroundColor Yellow
    }

    # Hosts
    Write-Host ""
    Write-Host "  * Status Domain Validasi di hosts file:" -ForegroundColor Cyan
    $hc = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    foreach ($d in $adobeDomains) {
        if ($hc -match [regex]::Escape($d)) {
            Write-Host "    [OK] Terblokir (0.0.0.0) : $d" -ForegroundColor Green
        } else {
            Write-Host "    [!] Belum Terblokir     : $d" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    pause
}

function Restore-AdobeAccess {
    cls
    Write-Host ""
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Yellow
    Write-Host "  PULIHKAN / BUKA KEMBALI KONEKSI CLOUD ADOBE" -ForegroundColor Yellow
    Write-Host "  ////////////////////////////////////////////////////////////////" -ForegroundColor Yellow
    Write-Host ""

    # 1. Bersihkan Firewall
    Write-Host "  -> Menghapus aturan isolasi Adobe dari Windows Firewall..." -ForegroundColor Cyan
    netsh advfirewall firewall delete rule name="FokusKonten_Block_Adobe Desktop Service.exe" | Out-Null
    netsh advfirewall firewall delete rule name="FokusKonten_Block_AGSService.exe"            | Out-Null
    netsh advfirewall firewall delete rule name="FokusKonten_Block_Creative Cloud.exe"        | Out-Null
    netsh advfirewall firewall delete rule name="Block_Adobe Desktop Service.exe"             | Out-Null
    netsh advfirewall firewall delete rule name="Block_AGSService.exe"                        | Out-Null
    Write-Host "  [OK] Seluruh aturan firewall Adobe dibersihkan." -ForegroundColor Green

    # 2. Bersihkan Hosts
    Write-Host "  -> Membersihkan domain Adobe dari hosts file..." -ForegroundColor Cyan
    $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue | Where-Object {
        $l = $_
        $matched = $false
        foreach ($d in $adobeDomains) {
            if ($l -match [regex]::Escape($d)) { $matched = $true; break }
        }
        -not $matched
    }
    Set-Content -Path $hostsPath -Value $lines -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host "  [OK] Domain Adobe di hosts berhasil dipulihkan." -ForegroundColor Green

    # 3. Kembalikan service
    Write-Host "  -> Mengembalikan startup layanan AGSService ke Manual..." -ForegroundColor Cyan
    Set-Service -Name "AGSService" -StartupType Manual -ErrorAction SilentlyContinue
    Write-Host "  [OK] Status layanan Adobe dikembalikan ke default." -ForegroundColor Green

    Write-Host ""
    Write-Host "  [OK] PENGATURAN KONEKSI ADOBE BERHASIL DIKEMBALIKAN KE SEMULA!" -ForegroundColor Green
    Write-Host ""
    pause
}

# Main menu loop
while ($true) {
    cls
    Write-Host ""
    Write-Host "  /////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host "  //  FOKUSKONTEN  //  ADOBE SHIELD                              //" -ForegroundColor Red
    Write-Host "  //  Anti Pop-Up 'Unlicensed App' & Genuine Service Blocker     //" -ForegroundColor Yellow
    Write-Host "  /////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Seluruh project file PSD, AI, INDD, dan Premiere Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  Solusi isolasi jaringan murni tanpa modifikasi file instalasi biner Adobe." -ForegroundColor White
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  DETAIL LAYANAN ADOBE CREATIVE CLOUD:" -ForegroundColor White
    Write-Host "  * Layanan  : ADOBE SHIELD - ANTI POP-UP UNLICENSED & AGSSERVICE" -ForegroundColor Cyan
    Write-Host "  * Sasaran  : Photoshop | Illustrator | Premiere Pro | After Effects | Acrobat" -ForegroundColor White
    Write-Host "  * Solusi   : Menghentikan notifikasi 'This unlicensed app will be disabled'" -ForegroundColor Green
    Write-Host "  * Metode   : Firewall Outbound Isolation & Hosts Null-Routing (Zero Virus)" -ForegroundColor Yellow
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Pasang Proteksi Anti Pop-Up Adobe (Disarankan)" -ForegroundColor Yellow
    Write-Host "          Nonaktifkan AGSService, blokir telemetri validasi lisensi cloud." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Cek Status Proteksi Firewall & Hosts Adobe" -ForegroundColor White
    Write-Host "          Memeriksa apakah domain pelacak dan service Adobe sudah terisolasi." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Pulihkan / Buka Kembali Akses Cloud Adobe (Rollback)" -ForegroundColor White
    Write-Host "          Menghapus aturan blokir firewall dan mengembalikan file hosts." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Toko Digital FokusKonten - Software & Template Bisnis" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      [0] Keluar" -ForegroundColor DarkGray
    Write-Host "  /////////////////////////////////////////////////////////////////" -ForegroundColor Red
    Write-Host ""

    try {
        Write-Host -NoNewline "  Pilihan Anda [1,2,3,4,0] : " -ForegroundColor Yellow
        $k = [Console]::ReadKey($true)
        $c = $k.KeyChar.ToString()
        Write-Host $c -ForegroundColor Yellow
    } catch {
        $c = Read-Host "  Pilihan"
    }

    switch ($c) {
        "1" { Enable-AdobeShield }
        "2" { Show-AdobeStatus }
        "3" { Restore-AdobeAccess }
        "4" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
        "0" { exit 0 }
    }
}
'@

    $rand    = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $ps1Path = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Adobe_$rand.ps1" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Adobe_$rand.ps1" }
    [System.IO.File]::WriteAllText($ps1Path, $adobePs1, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $ps1Path)) {
        Write-Host "  [!] Gagal membuat berkas temp Adobe Shield. Aborting." -ForegroundColor Red
        return
    }

    $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    Write-Host "  [OK] Engine Adobe Shield siap." -ForegroundColor Green
    Write-Host "  -> Membuka menu FokusKonten Adobe Shield..." -ForegroundColor Cyan
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
