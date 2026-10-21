# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : PEMULIHAN LISENSI MICROSOFT OFFICE BEBAS NOTIFIKASI
# Modul SKU    : FK-PSH-01 (Officer Helper Suite)
# Desain       : Ultra-Compact Golden Layout (100% Single Terminal In-Place)
# Engine Inti  : OHook Dynamic Hook Injection (sppc.dll Virtualization)
# ==============================================================================

param(
    [string]$Order = ""
)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

if (-not $global:fkOrderNumber) {
    if (![string]::IsNullOrWhiteSpace($Order)) {
        $global:fkOrderNumber = $Order
    } elseif ($env:FK_ORDER_ID) {
        $global:fkOrderNumber = $env:FK_ORDER_ID
    } else {
        $dt = Get-Date -Format "yyyyMMdd"
        $rnd = Get-Random -Minimum 1000 -Maximum 9999
        $global:fkOrderNumber = "FK-ORD-$dt-$rnd"
    }
}

$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // OFFICER HELPER - PEMULIHAN OFFICE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$isAdmin = $false
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Find-OfficePaths {
    return @(
        (Join-Path $env:ProgramFiles "Microsoft Office"),
        (Join-Path ${env:ProgramFiles(x86)} "Microsoft Office")
    )
}

function Get-OfficeInstallType {
    $hasC2R = $false
    $hasUwp = $false

    $c2rReg = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $c2rReg86 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office\ClickToRun\Configuration"
    if ((Test-Path $c2rReg) -or (Test-Path $c2rReg86)) {
        $hasC2R = $true
    }

    $c2rLicPath = "C:\Program Files\Microsoft Office\root\Licenses16"
    if (Test-Path $c2rLicPath) { $hasC2R = $true }

    $appxManifest = "C:\Program Files\Microsoft Office\AppXManifest.xml"
    if (Test-Path $appxManifest) {
        $uwpPkg = Get-AppxPackage -Name "*Office.Desktop*" -ErrorAction SilentlyContinue
        if ($uwpPkg) {
            $hasUwp = $true
        }
    }

    if ($hasC2R) { return "C2R" }
    if ($hasUwp) { return "UWP" }

    $msiReg = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot"
    if (Test-Path $msiReg) { return "MSI" }

    return "NOT_INSTALLED"
}

function Get-OfficeHookState {
    $paths = Find-OfficePaths
    foreach ($p in $paths) {
        if (-not (Test-Path -LiteralPath $p)) { continue }
        $vfsHook = Join-Path $p "root\vfs\System\sppc.dll"
        $vfsHook86 = Join-Path $p "root\vfs\SystemX86\sppc.dll"
        $dirHook = Join-Path $p "Office16\sppc.dll"
        $rootHook = Join-Path $p "root\Office16\sppc.dll"

        if ((Test-Path -LiteralPath $vfsHook) -or (Test-Path -LiteralPath $vfsHook86) -or (Test-Path -LiteralPath $dirHook) -or (Test-Path -LiteralPath $rootHook)) {
            return "LICENSED"
        }
    }
    return "UNLICENSED"
}

function Get-OfficeState {
    $installType = Get-OfficeInstallType
    if ($installType -eq "NOT_INSTALLED") {
        return "NOT_INSTALLED"
    }
    if ($installType -eq "UWP") {
        return "UWP_DETECTED"
    }

    $hook = Get-OfficeHookState
    if ($hook -eq "LICENSED") {
        return "LICENSED"
    }
    return "UNLICENSED"
}

function Close-OfficeApps {
    Write-Host "  -> Mengamankan proses Office agar berkas tidak terkunci..." -ForegroundColor Gray
    $procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "teams", "lync")
    foreach ($pr in $procs) {
        Get-Process -Name $pr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Milliseconds 400
}

function Get-EnginePath {
    if ($PSScriptRoot) {
        $localCmd = Join-Path $PSScriptRoot "MAS_AIO.cmd"
        if (Test-Path -LiteralPath $localCmd) { return $localCmd }
        $separate = Join-Path $PSScriptRoot "source_repo\MAS\Separate-Files-Version\Activators\Ohook_Activation_AIO.cmd"
        if (Test-Path -LiteralPath $separate) { return $separate }
    }

    $workDir = Join-Path $env:ProgramData "FokusKonten"
    if (-not (Test-Path -LiteralPath $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }
    $cached = Join-Path $workDir "FK_Core_Runtime_v3.cmd"
    if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
        return $cached
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul pemulihan lisensi resmi FokusKonten..." -ForegroundColor Cyan
    $primaryUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/01_Officer_Helper/MAS_AIO.cmd"
    $fallbackUrl = "https://fokuskonten.my.id/assets/engine/FK_Engine_Core.cmd"

    try {
        $wc = New-Object System.Net.WebClient
        $rawText = $wc.DownloadString($primaryUrl)
        if ($rawText.Length -gt 50000) {
            $crlfText = $rawText -replace "(?<!`r)`n", "`r`n"
            [System.IO.File]::WriteAllText($cached, $crlfText, [System.Text.Encoding]::ASCII)
            Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
            return $cached
        }
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($fallbackUrl, $cached)
            if ((Test-Path -LiteralPath $cached) -and ((Get-Item -LiteralPath $cached).Length -gt 50000)) {
                Write-Host "     [================] 100% [KOMPONEN SIAP]" -ForegroundColor Green
                return $cached
            }
        } catch {}
    }

    return $cached
}

function Show-Header {
    Clear-Host
    $state = Get-OfficeState
    $type  = Get-OfficeInstallType

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Officer Helper: Pemulihan Lisensi Word & Excel" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-01] Asistensi Resmi" -ForegroundColor DarkCyan

    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: OHOOK PERMANEN ] (Bebas Notifikasi)" -ForegroundColor Green
    } elseif ($state -eq "UWP_DETECTED") {
        Write-Host "  STATUS : [ PERINGATAN: OFFICE STORE / UWP ] (Perlu Konversi C2R)" -ForegroundColor Red
    } elseif ($state -eq "UNLICENSED") {
        Write-Host "  STATUS : [ NOTIFIKASI AKTIF / PERLU PEMULIHAN ] (Tipe: $type)" -ForegroundColor Yellow
    } else {
        Write-Host "  STATUS : [ MICROSOFT OFFICE BELUM TERDETEKSI ]" -ForegroundColor DarkYellow
    }

    if ($isAdmin) {
        Write-Host "  AKSES  : [ ADMINISTRATOR RESMI ] (Siap Eksekusi 1 Terminal)" -ForegroundColor Green
    } else {
        Write-Host "  AKSES  : [ USER STANDAR ] (Mode In-Place 1 Terminal)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkCyan
}

function Invoke-EngineWithLiveLog {
    param(
        [string]$Arguments,
        [string]$ActionTitle
    )

    $engine = Get-EnginePath
    if (-not $engine -or -not (Test-Path -LiteralPath $engine)) {
        Write-Host "  [GAGAL] Komponen engine tidak ditemukan." -ForegroundColor Red
        return $false
    }

    $workDir = Join-Path $env:ProgramData "FokusKonten"
    if (-not (Test-Path -LiteralPath $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }
    $logFile = Join-Path $workDir "fk_exec.log"
    if (Test-Path -LiteralPath $logFile) {
        Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // $ActionTitle" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    $cmdStr = "/c `"`"$engine`" $Arguments > `"$logFile`" 2>&1`""

    try {
        if ($isAdmin) {
            Write-Host "  -> Memulai injeksi hook lisensi di latar belakang..." -ForegroundColor Cyan
            $proc = Start-Process -FilePath "$env:ComSpec" -ArgumentList $cmdStr -WindowStyle Hidden -PassThru
        } else {
            Write-Host "  -> Izin Sistem: Klik 'Yes' pada dialog konfirmasi Windows..." -ForegroundColor Yellow
            $proc = Start-Process -FilePath "$env:ComSpec" -ArgumentList $cmdStr -Verb RunAs -WindowStyle Hidden -PassThru
        }
    } catch {
        Write-Host ""
        Write-Host "  [!] Izin Administrator dibatalkan oleh pengguna." -ForegroundColor Yellow
        Write-Host "  Tips: Klik 'Yes' pada jendela konfirmasi untuk melanjutkan." -ForegroundColor White
        return $false
    }

    $lastIdx = 0
    $spin = @('|', '/', '-', '\')
    $s = 0
    $elapsed = 0
    $hasStartedLog = $false

    while (-not $proc.HasExited) {
        if (Test-Path -LiteralPath $logFile) {
            try {
                $stream = [System.IO.File]::Open($logFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                $reader = New-Object System.IO.StreamReader($stream)
                $allLines = @()
                while (-not $reader.EndOfStream) {
                    $allLines += $reader.ReadLine()
                }
                $reader.Close()
                $stream.Close()

                if ($allLines.Count -gt $lastIdx) {
                    for ($i = $lastIdx; $i -lt $allLines.Count; $i++) {
                        $raw = $allLines[$i].Trim()
                        $clean = $raw -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
                        if ($clean -and -not ($clean -match '^[=\-_~*#]{3,}$')) {
                            $hasStartedLog = $true
                            if ($clean -match 'permanently activated|Successfully|Installed|Activated|Licensed') {
                                Write-Host "`r  [OK] $clean                                                 " -ForegroundColor Green
                            } elseif ($clean -match 'error|failed|abort' -and -not ($clean -match '0 error')) {
                                Write-Host "`r  [!] $clean                                                  " -ForegroundColor Yellow
                            } else {
                                Write-Host "`r  -> $clean                                                   " -ForegroundColor Cyan
                            }
                        }
                    }
                    $lastIdx = $allLines.Count
                }
            } catch {}
        }

        $char = $spin[$s % 4]
        if ($hasStartedLog) {
            Write-Host -NoNewline "`r  [*] Sedang mengaplikasikan hook ke Office... [$char] ($elapsed dtk) "
        } else {
            Write-Host -NoNewline "`r  [*] Menunggu konfirmasi UAC & inisialisasi... [$char] ($elapsed dtk) "
        }
        
        $s++
        Start-Sleep -Milliseconds 250
        if ($s % 4 -eq 0) { $elapsed++ }
    }

    Write-Host -NoNewline "`r                                                                     `r"

    if (Test-Path -LiteralPath $logFile) {
        try {
            $stream = [System.IO.File]::Open($logFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $reader = New-Object System.IO.StreamReader($stream)
            $allLines = @()
            while (-not $reader.EndOfStream) { $allLines += $reader.ReadLine() }
            $reader.Close(); $stream.Close()

            for ($i = $lastIdx; $i -lt $allLines.Count; $i++) {
                $raw = $allLines[$i].Trim()
                $clean = $raw -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
                if ($clean -and -not ($clean -match '^[=\-_~*#]{3,}$')) {
                    if ($clean -match 'permanently activated|Successfully|Installed|Activated|Licensed') {
                        Write-Host "  [OK] $clean" -ForegroundColor Green
                    } elseif ($clean -match 'error|failed|abort' -and -not ($clean -match '0 error')) {
                        Write-Host "  [!] $clean" -ForegroundColor Yellow
                    } else {
                        Write-Host "  -> $clean" -ForegroundColor Cyan
                    }
                }
            }
        } catch {}
        Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue
    }

    return $true
}

function Invoke-Action {
    Clear-Host

    $installType = Get-OfficeInstallType
    if ($installType -eq "UWP") {
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host "  PERINGATAN: TIPE INSTALASI OFFICE TIDAK DIDUKUNG" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Sistem mendeteksi Microsoft Office edisi Microsoft Store / UWP." -ForegroundColor White
        Write-Host "  Edisi bawaan pabrik ini terisolasi dan tidak mendukung lisensi C2R." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  SOLUSI REKOMENDASI 1-KLIK:" -ForegroundColor Cyan
        Write-Host "  Gunakan Modul 37 untuk memasang Office C2R Resmi (Word, Excel, PPT)" -ForegroundColor White
        Write-Host "  bebas bloatware, lalu aktifkan kembali dengan modul ini." -ForegroundColor White
        Write-Host ""
        Write-Host "  Apakah Anda ingin membuka modul pasang bersih sekarang? (Y/N) : " -NoNewline -ForegroundColor Green
        $ans = [Console]::ReadLine()
        if ($ans -and $ans.Trim().ToUpper() -eq "Y") {
            Launch-CleanInstallC2R
            return
        }
        Write-Host "  Aktivasi dibatalkan. Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        try { [Console]::ReadKey($true) | Out-Null } catch {}
        return
    }

    Close-OfficeApps

    $res = Invoke-EngineWithLiveLog -Arguments "/ohook -qedit -el" -ActionTitle "PEMASANGAN LISENSI PERMANEN OFFICE"

    Write-Host ""
    $hookState = Get-OfficeHookState
    if ($hookState -eq "LICENSED") {
        Write-Host "  [OK] LISENSI OFFICE BERHASIL DIPASANG PERMANEN!" -ForegroundColor Green
        Write-Host "  Status : Berlisensi Penuh (Bebas Notifikasi Selamanya)" -ForegroundColor White
        Write-Host "  Tips   : Buka Word / Excel untuk memastikan status akun aktif." -ForegroundColor Yellow
    } else {
        Write-Host "  [!] PEMASANGAN HOOK LISENSI BELUM BERHASIL DITERAPKAN" -ForegroundColor Yellow
        Write-Host "  Penyebab Kemungkinan:" -ForegroundColor White
        Write-Host "   1. Windows Defender / Antivirus memblokir penulisan berkas sppc.dll." -ForegroundColor Gray
        Write-Host "   2. Residu lisensi Office 365 Trial bentrok (Gunakan Menu [2])." -ForegroundColor Gray
        Write-Host "   3. Berkas instalasi Office korup (Gunakan Menu [6] untuk pasang bersih)." -ForegroundColor Gray
    }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Invoke-CleanResidueLicenses {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // PEMBERSIHAN RESIDU LISENSI TRIAL / OSPP" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  -> Memindai kunci lisensi usang / trial di sistem..." -ForegroundColor Cyan

    Close-OfficeApps

    $cleaned = 0
    try {
        $keys = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='0ff1ce15-a989-479d-af46-f275c6370663' AND PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue
        if ($keys) {
            foreach ($k in $keys) {
                # Bersihkan kunci trial / grace period (Status 2 = OOB_GRACE)
                if ($k.LicenseStatus -ne 1 -or $k.Description -match "Grace|Trial|O365|Retail") {
                    Write-Host "  -> Mencabut kunci residu: $($k.Name) [$($k.PartialProductKey)]..." -ForegroundColor Yellow
                    try {
                        Invoke-CimMethod -InputObject $k -MethodName UninstallProductKey -ErrorAction SilentlyContinue | Out-Null
                        $cleaned++
                    } catch {}
                }
            }
        }
    } catch {}

    # Jalankan ospp.vbs /unpkey sebagai pembersihan sekoci
    $ospp = $null
    foreach ($p in (Find-OfficePaths)) {
        $found = Get-ChildItem -LiteralPath $p -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $ospp = $found.FullName; break }
    }

    if ($cleaned -gt 0) {
        Write-Host ""
        Write-Host "  [OK] BERHASIL MEMBERSIHKAN $cleaned KUNCI LISENSI RESIDU!" -ForegroundColor Green
        Write-Host "  Konflik lisensi trial telah dibersihkan dari sistem." -ForegroundColor White
        Write-Host "  Silakan pilih menu [1] untuk memasang lisensi permanen bersih." -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "  [INFO] Tidak ditemukan residu lisensi trial yang bentrok." -ForegroundColor Cyan
        Write-Host "  Sistem registri lisensi Office Anda dalam kondisi bersih." -ForegroundColor White
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Check-Diagnostics {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTIK STATUS LISENSI MICROSOFT OFFICE (OSPP.VBS)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $ospp = $null
    foreach ($p in (Find-OfficePaths)) {
        $found = Get-ChildItem -LiteralPath $p -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $ospp = $found.FullName; break }
    }

    if ($ospp) {
        cscript.exe //nologo $ospp /dstatus
    } else {
        $engine = Get-EnginePath
        if ($engine) {
            & cmd.exe /c "`"$engine`" /status"
        } else {
            Write-Host "  [PERINGATAN] Microsoft Office tidak terdeteksi." -ForegroundColor Red
        }
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Remove-License {
    Clear-Host
    Close-OfficeApps
    $res = Invoke-EngineWithLiveLog -Arguments "/Ohook-Uninstall -qedit -el" -ActionTitle "PENCABUTAN LISENSI OHOOK (KEMBALIKAN KE SEMULA)"

    Write-Host ""
    if ($res) {
        Write-Host "  [OK] LISENSI OHOOK TELAH BERHASIL DICABUT BERSIH!" -ForegroundColor Green
        Write-Host "  Office Anda telah kembali ke kondisi awal." -ForegroundColor White
    }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Launch-OfficeApps {
    Write-Host ""
    $wordExe = $null
    $excelExe = $null

    foreach ($p in (Find-OfficePaths)) {
        if (-not $wordExe) {
            $w = Get-ChildItem -LiteralPath $p -Filter "WINWORD.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($w) { $wordExe = $w.FullName }
        }
        if (-not $excelExe) {
            $e = Get-ChildItem -LiteralPath $p -Filter "EXCEL.EXE" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($e) { $excelExe = $e.FullName }
        }
    }

    if ($wordExe) {
        Start-Process -FilePath $wordExe
        Write-Host "  > Microsoft Word berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu File -> Account untuk cek status lisensi." -ForegroundColor Yellow
    } elseif ($excelExe) {
        Start-Process -FilePath $excelExe
        Write-Host "  > Microsoft Excel berhasil dibuka di layar Anda!" -ForegroundColor Green
        Write-Host "  Tips: Buka menu File -> Account untuk cek status lisensi." -ForegroundColor Yellow
    } else {
        try {
            Start-Process "winword.exe"
            Write-Host "  > Microsoft Word berhasil dibuka!" -ForegroundColor Green
        } catch {
            Write-Host "  [PERINGATAN] Aplikasi Word/Excel belum terpasang di PC." -ForegroundColor Yellow
        }
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Launch-CleanInstallC2R {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // JEMBATAN LAYANAN PASANG BERSIH C2R" -ForegroundColor Yellow
    Write-Host "  Menghubungkan ke Modul [FK-PSH-37] Office Tool Plus..." -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  -> Mengunduh peluncur resmi pasang bersih C2R FokusKonten..." -ForegroundColor Cyan

    try {
        $c2rScriptUrl = "https://fokuskonten.my.id/otp"
        $wc = New-Object System.Net.WebClient
        $scriptContent = $wc.DownloadString($c2rScriptUrl)
        if ($scriptContent.Length -gt 1000) {
            Invoke-Expression $scriptContent
            return
        }
    } catch {
        Write-Host "  [!] Beralih ke sekoci direktori internal..." -ForegroundColor Yellow
        $localVault37 = Join-Path (Split-Path $PSScriptRoot -Parent) "37_Office_Tool_Plus_Deployment_Engine\launcher.ps1"
        if (Test-Path -LiteralPath $localVault37) {
            & powershell.exe -ExecutionPolicy Bypass -File "$localVault37" -Order $global:fkOrderNumber
            return
        }
    }

    Write-Host "  [!] Gagal memuat modul pasang bersih. Periksa koneksi internet." -ForegroundColor Red
    Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor Yellow
    try { [Console]::ReadKey($true) | Out-Null } catch {}
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-OfficeHookState) -eq "LICENSED") { "OHook Virtualization (Bebas Notifikasi)" } else { "Standar / Unlicensed" }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-01] Pemulihan Lisensi Word & Excel" -ForegroundColor White
    Write-Host "  Status  : $finalStatus (Siap Pakai)" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------------------------
# LOOP UTAMA INTERAKTIF (1 TERMINAL EXECUTION - ULTRA-COMPACT GOLDEN 64 LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-Header

    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Pasang / Pulihkan Lisensi Office (Rekomendasi 1-Klik OHook)" -ForegroundColor Green
    Write-Host "   [2] Bersihkan Lisensi Residu / Reset Kunci Trial (Fix Bentrok OSPP)" -ForegroundColor Cyan
    Write-Host "   [3] Cek / Diagnostik Status Lisensi (ospp.vbs /dstatus)" -ForegroundColor Yellow
    Write-Host "   [4] Copot / Batalkan Lisensi (Kembalikan ke Semula / Undo)" -ForegroundColor Gray
    Write-Host "   [5] Buka Aplikasi Word / Excel (Cek Status di Layar)" -ForegroundColor White
    Write-Host "   [6] Pasang Bersih Office C2R Resmi (Solusi jika UWP / Rusak)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 5, 6, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()

    if ($choice -eq $null) { break }
    switch ($choice.Trim()) {
        "1" {
            Invoke-Action
        }
        "2" {
            Invoke-CleanResidueLicenses
        }
        "3" {
            Check-Diagnostics
        }
        "4" {
            Remove-License
        }
        "5" {
            Launch-OfficeApps
        }
        "6" {
            Launch-CleanInstallC2R
        }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            Write-Host "  [!] Pilihan tidak valid. Silakan pilih 1-6 atau 0." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 800
        }
    }
}
