# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 40: CORELDRAW SHIELD - Anti Blokir Akun & Pop-Up Ilegal
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
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Magenta
    Write-Host "  Modul 40 : CORELDRAW SHIELD - Anti Blokir & Pop-Up Ilegal" -ForegroundColor Yellow
    Write-Host "  Metode   : Firewall Outbound Isolation & Null-Route Telemetry" -ForegroundColor White
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  -> Menyiapkan proteksi CorelDraw..." -ForegroundColor Cyan

    $corelPs1 = @'
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "FokusKonten // CORELDRAW SHIELD - Anti Pop-Up Ilegal"
try { $Host.UI.RawUI.BackgroundColor = 'DarkMagenta'; $Host.UI.RawUI.ForegroundColor = 'White'; Clear-Host } catch {}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$corelDomains = @(
    "mc.corel.com",
    "apps.corel.com",
    "origin-mc.corel.com",
    "iws.corel.com",
    "corel.com"
)
$corelPaths = @(
    "C:\Program Files\Corel\*\Programs64\CorelDRW.exe",
    "C:\Program Files\Corel\*\Programs64\Cap.exe",
    "C:\Program Files\Corel\*\Programs64\CorelPP.exe",
    "C:\Program Files (x86)\Corel\*\Programs\CorelDRW.exe"
)

function Enable-CorelShield {
    cls
    Write-Host ""
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host "  MEMASANG PROTEKSI ANTI POP-UP CORELDRAW..." -ForegroundColor Yellow
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host ""

    # 1. Hentikan dan nonaktifkan layanan Corel License Validation
    Write-Host "  [1/3] Mematikan layanan Corel License Validation Service..." -ForegroundColor Cyan
    $svcs = Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue
    foreach ($s in $svcs) {
        Stop-Service -Name $s.Name -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $s.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [OK] Service $($s.Name) dinonaktifkan." -ForegroundColor Green
    }
    if (-not $svcs) {
        Write-Host "  * Tidak ada service Corel background aktif." -ForegroundColor Gray
    }

    # 2. Tambah aturan Firewall Outbound Block
    Write-Host ""
    Write-Host "  [2/3] Menerapkan aturan Windows Firewall Outbound..." -ForegroundColor Cyan
    $found = 0
    Get-ChildItem -Path $corelPaths -ErrorAction SilentlyContinue | ForEach-Object {
        $exe = $_.FullName
        $ruleName = "FokusKonten_Block_Corel_" + $_.Name
        netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
        netsh advfirewall firewall add rule name="$ruleName" dir=out action=block program="$exe" enable=yes | Out-Null
        Write-Host "  [OK] Blokir firewall aktif: $exe" -ForegroundColor Green
        $found++
    }
    if ($found -eq 0) {
        Write-Host "  * Biner CorelDRW.exe di Program Files belum terdeteksi otomatis." -ForegroundColor Yellow
        Write-Host "    (Aturan nama biner standar tetap dipasang ke firewall)" -ForegroundColor Gray
        foreach ($b in @("CorelDRW.exe", "Cap.exe", "CorelPP.exe")) {
            netsh advfirewall firewall add rule name="FokusKonten_Block_Corel_$b" dir=out action=block program="$b" enable=yes | Out-Null
        }
    }

    # 3. Suntikkan pemetaan host null
    Write-Host ""
    Write-Host "  [3/3] Menyuntikkan pemetaan domain pelacak ke hosts..." -ForegroundColor Cyan
    $hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    $append = ""
    foreach ($d in $corelDomains) {
        if ($hostsContent -notmatch [regex]::Escape($d)) {
            $append += "`r`n0.0.0.0 $d"
        }
    }
    if ($append -ne "") {
        Add-Content -Path $hostsPath -Value $append -ErrorAction SilentlyContinue
        Write-Host "  [OK] 5 domain pelacak Corel diarahkan ke 0.0.0.0." -ForegroundColor Green
    } else {
        Write-Host "  * Seluruh domain pelacak Corel sudah diblokir sebelumnya." -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host "  [SUKSES] PROTEKSI CORELDRAW AKTIF!" -ForegroundColor Green
    Write-Host "  * Fungsi Save, Export, Print kembali normal tanpa blokir popup." -ForegroundColor White
    Write-Host "  * Notifikasi software ilegal / pirated tidak akan muncul lagi." -ForegroundColor Yellow
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host ""
    pause
}

function Show-CorelStatus {
    cls
    Write-Host ""
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host "  DIAGNOSTIK STATUS PROTEKSI CORELDRAW" -ForegroundColor Magenta
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host ""

    # Layanan Corel
    Write-Host "  * Status Layanan Corel License:" -ForegroundColor Cyan
    $svcs = Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue
    if ($svcs) {
        foreach ($s in $svcs) {
            $c = if ($s.StartType -eq "Disabled") { "Green" } else { "Yellow" }
            Write-Host ("    - {0,-25} : {1,-10} [Startup: {2}]" -f $s.Name, $s.Status, $s.StartType) -ForegroundColor $c
        }
    } else {
        Write-Host "    - Tidak ada service Corel terdaftar." -ForegroundColor Gray
    }

    # Aturan Firewall
    Write-Host ""
    Write-Host "  * Aturan Windows Firewall:" -ForegroundColor Cyan
    $rules = netsh advfirewall firewall show rule name=all | Select-String "FokusKonten_Block_Corel|Block_Corel"
    if ($rules) {
        Write-Host "    [OK] Aturan blokir Corel terdeteksi aktif di Firewall." -ForegroundColor Green
    } else {
        Write-Host "    [!] Aturan blokir Corel belum terpasang di Firewall." -ForegroundColor Yellow
    }

    # Hosts
    Write-Host ""
    Write-Host "  * Status Domain Pelacak di C:\Windows\System32\drivers\etc\hosts:" -ForegroundColor Cyan
    $hc = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    foreach ($d in $corelDomains) {
        if ($hc -match [regex]::Escape($d)) {
            Write-Host "    [OK] Terblokir (0.0.0.0) : $d" -ForegroundColor Green
        } else {
            Write-Host "    [!] Belum Terblokir     : $d" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    pause
}

function Restore-CorelAccess {
    cls
    Write-Host ""
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Yellow
    Write-Host "  PULIHKAN / BUKA KEMBALI KONEKSI JARINGAN CORELDRAW" -ForegroundColor Yellow
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Yellow
    Write-Host ""

    # 1. Bersihkan Firewall
    Write-Host "  -> Menghapus aturan blokir Corel dari Windows Firewall..." -ForegroundColor Cyan
    netsh advfirewall firewall delete rule name="FokusKonten_Block_Corel_CorelDRW.exe" | Out-Null
    netsh advfirewall firewall delete rule name="FokusKonten_Block_Corel_Cap.exe"      | Out-Null
    netsh advfirewall firewall delete rule name="FokusKonten_Block_Corel_CorelPP.exe"  | Out-Null
    netsh advfirewall firewall delete rule name="Block_Corel_CorelDRW.exe"            | Out-Null
    netsh advfirewall firewall delete rule name="Block_Corel_Cap.exe"                 | Out-Null
    netsh advfirewall firewall delete rule name="Block_Corel_CorelPP.exe"             | Out-Null
    Write-Host "  [OK] Seluruh aturan firewall Corel dibersihkan." -ForegroundColor Green

    # 2. Bersihkan Hosts
    Write-Host "  -> Membersihkan domain Corel dari hosts file..." -ForegroundColor Cyan
    $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue | Where-Object {
        $l = $_
        $matched = $false
        foreach ($d in $corelDomains) {
            if ($l -match [regex]::Escape($d)) { $matched = $true; break }
        }
        -not $matched
    }
    Set-Content -Path $hostsPath -Value $lines -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host "  [OK] Domain Corel di hosts berhasil dipulihkan." -ForegroundColor Green

    # 3. Kembalikan service
    Write-Host "  -> Mengembalikan startup layanan Corel ke Manual..." -ForegroundColor Cyan
    Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | Set-Service -StartupType Manual -ErrorAction SilentlyContinue
    Write-Host "  [OK] Status layanan Corel dikembalikan ke default." -ForegroundColor Green

    Write-Host ""
    Write-Host "  [OK] PENGATURAN JARINGAN CORELDRAW BERHASIL DIKEMBALIKAN KE SEMULA!" -ForegroundColor Green
    Write-Host ""
    pause
}

# Main menu loop
while ($true) {
    cls
    Write-Host ""
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host "  ~~  FOKUSKONTEN  //  CORELDRAW SHIELD                          ~~" -ForegroundColor Magenta
    Write-Host "  ~~  Anti Blokir Akun & Pemulihan Fitur Save / Export Corel    ~~" -ForegroundColor Yellow
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Dokumen desain CDR, palet warna, dan artwork Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  Solusi firewall murni tanpa modifikasi file instalasi biner CorelDRAW." -ForegroundColor White
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  DETAIL LAYANAN DESAIN CORELDRAW:" -ForegroundColor White
    Write-Host "  * Layanan  : CORELDRAW SHIELD - ANTI POP-UP ILEGAL & TELEMETRY" -ForegroundColor Cyan
    Write-Host "  * Sasaran  : CorelDRW.exe | Cap.exe | CorelPP.exe | Corel License Service" -ForegroundColor White
    Write-Host "  * Solusi   : Buka kunci tombol Save, Export, Print yang dinonaktifkan" -ForegroundColor Green
    Write-Host "  * Metode   : Outbound Firewall Rule & Hosts Null-Routing (Zero Virus)" -ForegroundColor Yellow
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Pasang Proteksi Anti Pop-Up CorelDraw (Disarankan)" -ForegroundColor Yellow
    Write-Host "          Matikan telemetri, blokir notifikasi software bajakan/ilegal." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Cek Status Proteksi Firewall & Hosts Corel" -ForegroundColor White
    Write-Host "          Memeriksa apakah domain pelacak dan exe Corel sudah terisolasi." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Pulihkan / Buka Kembali Akses Jaringan Corel (Rollback)" -ForegroundColor White
    Write-Host "          Menghapus aturan blokir firewall dan mengembalikan file hosts." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Toko Digital FokusKonten - Software & Template Bisnis" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      [0] Keluar" -ForegroundColor DarkGray
    Write-Host "  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Magenta
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
        "1" { Enable-CorelShield }
        "2" { Show-CorelStatus }
        "3" { Restore-CorelAccess }
        "4" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
        "0" { exit 0 }
    }
}
'@

    $rand    = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $ps1Path = if ($isAdmin) { "$env:SystemRoot\Temp\FK_Corel_$rand.ps1" } else { "$env:USERPROFILE\AppData\Local\Temp\FK_Corel_$rand.ps1" }
    [System.IO.File]::WriteAllText($ps1Path, $corelPs1, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $ps1Path)) {
        Write-Host "  [!] Gagal membuat berkas temp Corel Shield. Aborting." -ForegroundColor Red
        return
    }

    $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    Write-Host "  [OK] Engine Corel Shield siap." -ForegroundColor Green
    Write-Host "  -> Membuka menu FokusKonten Corel Shield..." -ForegroundColor Cyan
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
