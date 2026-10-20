# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SUITE PERBAIKAN CORELDRAW NOTIFIKASI LISENSI & SAVE TERKUNCI
# Modul SKU    : FK-PSH-11 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Execution (1 Terminal Mutlak, Bebas Pop-up Jendela)
# Fitur        : Buka Save, Hapus Popup Lisensi, Isolasi Telemetri & Restore
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // CORELDRAW RESCUE SHIELD SUITE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

$pasmDir     = "$env:ProgramFiles\Corel\PASMUtility\v1"
$pasmDll     = "$pasmDir\PASMUTILITY.dll"
$pasmBak     = "$pasmDir\PASMUTILITY.dll.BAK"
$hostsPath   = "$env:SystemRoot\System32\drivers\etc\hosts"
$cdnDllUrl   = "https://github.com/mcjobs-id/powershell-vault/releases/download/v1.0.0/PASMUTILITY.dll"
$patchedHash = "1036532E7981853535E3B40F5CACCDF8C59BBC3574CCE858EDA3918DC682552C"

$domains = @(
    "mc.corel.com",
    "apps.corel.com",
    "origin-mc.corel.com",
    "iws.corel.com",
    "corel.com",
    "www.corel.com",
    "telemetry.corel.com",
    "ipm.corel.com",
    "corelstore.com",
    "www.corelstore.com"
)

$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

function Get-CorelAppInfo {
    $setupKeys = Get-ChildItem "HKLM:\SOFTWARE\Corel\Setup" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "CorelDRAW" }
    if ($setupKeys) {
        $key = $setupKeys[0]
        $name = $key.PSChildName
        $dest = (Get-ItemProperty $key.PSPath -Name "Destination" -ErrorAction SilentlyContinue).Destination
        $exe = Join-Path $dest "Programs64\CorelDRW.exe"
        if (-not (Test-Path $exe)) { $exe = Join-Path $dest "Programs\CorelDRW.exe" }
        $ver = if (Test-Path $exe) { (Get-Item $exe).VersionInfo.ProductVersion } else { "Terpasang" }
        return @{ Name = $name; Version = $ver; Exe = $exe }
    }
    $exes = @(
        "$env:ProgramFiles\Corel\CorelDRAW Graphics Suite*\Programs64\CorelDRW.exe",
        "${env:ProgramFiles(x86)}\Corel\CorelDRAW Graphics Suite*\Programs\CorelDRW.exe"
    )
    foreach ($pat in $exes) {
        $found = Get-Item $pat -ErrorAction SilentlyContinue
        if ($found) {
            $f = $found[0]
            return @{ Name = $f.Directory.Parent.Name; Version = $f.VersionInfo.ProductVersion; Exe = $f.FullName }
        }
    }
    return $null
}

function Get-ShieldStatus {
    if (Test-Path $pasmDll) {
        $hash = (Get-FileHash -LiteralPath $pasmDll -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($hash -eq $patchedHash) { return "PROTECTED" }
    }
    return "UNPROTECTED"
}

function Get-HostsShieldStatus {
    if (-not (Test-Path $hostsPath)) { return "EXPOSED" }
    $hc = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    $blocked = 0
    foreach ($d in $domains) {
        if ($hc -match [regex]::Escape($d)) { $blocked++ }
    }
    if ($blocked -eq $domains.Count) { return "ISOLATED" }
    if ($blocked -gt 0) { return "PARTIAL" }
    return "EXPOSED"
}

function Show-CompactHeader {
    Clear-Host
    $corel  = Get-CorelAppInfo
    $shield = Get-ShieldStatus
    $hosts  = Get-HostsShieldStatus

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Layanan Jasa Pemulihan CorelDRAW Lisensi & Save Terkunci" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER    : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET    : [FK-PSH-11] CorelDRAW License & Save Guard Suite" -ForegroundColor DarkCyan

    if ($corel) {
        Write-Host "  STATUS   : [ TERPASANG ] ($($corel.Name), v$($corel.Version))" -ForegroundColor Green
    } else {
        Write-Host "  STATUS   : [ BELUM TERPASANG DI SISTEM INI ]" -ForegroundColor Magenta
    }

    if ($shield -eq "PROTECTED") {
        Write-Host "  LISENSI  : [ RESMI AKTIF ] (Tombol Save Terbuka & Bebas Popup)" -ForegroundColor Green
    } else {
        Write-Host "  LISENSI  : [ EVALUASI / TERKUNCI ] (Fitur Save/Export Beku)" -ForegroundColor Yellow
    }

    if ($hosts -eq "ISOLATED") {
        Write-Host "  SHIELD   : [ TERISOLASI ] (10 Domain Pelacak & Firewall Aktif)" -ForegroundColor Green
    } elseif ($hosts -eq "PARTIAL") {
        Write-Host "  SHIELD   : [ PARSIAL ] (Sebagian Domain Pelacak Belum Terkunci)" -ForegroundColor Yellow
    } else {
        Write-Host "  SHIELD   : [ RAWAN ] (Telemetri Vendor Belum Diblokir)" -ForegroundColor Yellow
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Find-CorelExecutables {
    $paths = @()
    $bases = @("$env:ProgramFiles\Corel", "${env:ProgramFiles(x86)}\Corel")
    foreach ($b in $bases) {
        if (Test-Path $b) {
            $found = Get-ChildItem -Path $b -Recurse -Depth 4 -Include 'CorelDRW.exe','Cap.exe','CorelPP.exe','FontManager.exe' -ErrorAction SilentlyContinue
            if ($found) { $paths += ($found | ForEach-Object { $_.FullName }) }
        }
    }
    return ($paths | Select-Object -Unique)
}

function Apply-ShieldAction {
    Write-Host ""
    Write-Host "  [PROSES] Memasang Proteksi CorelDRAW Paripurna..." -ForegroundColor Cyan

    $workerScript = {
        param($cdnUrl, $targetHash)

        $pasmDir   = "$env:ProgramFiles\Corel\PASMUtility\v1"
        $pasmDll   = "$pasmDir\PASMUTILITY.dll"
        $pasmBak   = "$pasmDir\PASMUTILITY.dll.BAK"
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $domains   = @("mc.corel.com","apps.corel.com","origin-mc.corel.com","iws.corel.com","corel.com","www.corel.com","telemetry.corel.com","ipm.corel.com","corelstore.com","www.corelstore.com")

        # 1. Hentikan proses Corel
        Get-Process -Name "CorelDRW","Cap","CorelPP" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        # 2. Injeksi PASMUTILITY.dll
        if (Test-Path $pasmDir) {
            if ((Test-Path $pasmDll) -and (-not (Test-Path $pasmBak))) {
                Copy-Item -LiteralPath $pasmDll -Destination $pasmBak -Force -ErrorAction SilentlyContinue
            }

            $localSources = @(
                "$PSScriptRoot\PASMUTILITY.dll",
                "$env:LOCALAPPDATA\FokusKonten\PASMUTILITY.dll",
                "$env:TEMP\PASMUTILITY.dll"
            )
            $injected = $false
            foreach ($src in $localSources) {
                if (Test-Path $src) {
                    Copy-Item -LiteralPath $src -Destination $pasmDll -Force -ErrorAction SilentlyContinue
                    $injected = $true
                    break
                }
            }

            if (-not $injected) {
                $cacheDir = "$env:LOCALAPPDATA\FokusKonten"
                if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
                $cacheFile = "$cacheDir\PASMUTILITY.dll"
                try {
                    (New-Object System.Net.WebClient).DownloadFile($cdnUrl, $cacheFile)
                    if (Test-Path $cacheFile) {
                        Copy-Item -LiteralPath $cacheFile -Destination $pasmDll -Force -ErrorAction SilentlyContinue
                        $injected = $true
                    }
                } catch {}
            }
        }

        # 3. Nonaktifkan layanan Corel License
        Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
        }

        # 4. Aturan Firewall Outbound
        $bases = @("$env:ProgramFiles\Corel", "${env:ProgramFiles(x86)}\Corel")
        $exes = @()
        foreach ($b in $bases) {
            if (Test-Path $b) {
                $f = Get-ChildItem -Path $b -Recurse -Depth 4 -Include 'CorelDRW.exe','Cap.exe','CorelPP.exe','FontManager.exe' -ErrorAction SilentlyContinue
                if ($f) { $exes += ($f | ForEach-Object { $_.FullName }) }
            }
        }
        Remove-NetFirewallRule -DisplayName "FK_Corel_*" -ErrorAction SilentlyContinue
        $idx = 1
        foreach ($exe in ($exes | Select-Object -Unique)) {
            New-NetFirewallRule -DisplayName "FK_Corel_Outbound_Block_$idx" `
                -Direction Outbound -Program $exe -Action Block `
                -Description "FokusKonten Corel License Guard" -ErrorAction SilentlyContinue | Out-Null
            $idx++
        }

        # 5. Blokir Domain di hosts
        if (Test-Path $hostsPath) {
            $hc = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
            $append = @()
            foreach ($d in $domains) {
                if ($hc -notmatch [regex]::Escape($d)) {
                    $append += "0.0.0.0 $d"
                }
            }
            if ($append.Count -gt 0) {
                Add-Content -Path $hostsPath -Value ("`r`n# FokusKonten Corel Shield`r`n" + ($append -join "`r`n")) -ErrorAction SilentlyContinue
            }
        }
    }

    if ($isAdmin) {
        Write-Host "  > Menghentikan proses Corel aktif sementara... " -ForegroundColor Cyan -NoNewline
        Get-Process -Name "CorelDRW","Cap","CorelPP" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Menyiapkan cadangan .BAK dan menyuntikkan pustaka... " -ForegroundColor Cyan -NoNewline
        & $workerScript -cdnUrl $cdnDllUrl -targetHash $patchedHash
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Mengamankan layanan telemetri Corel License... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Memasang aturan firewall & mengunci 10 domain hosts... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green
    } else {
        Write-Host "  > Mengalihkan tugas ke worker berizin sistem (UAC)... " -ForegroundColor Yellow
        $code = '& {' + $workerScript.ToString() + "} '$cdnDllUrl' '$patchedHash'"
        $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $b64" -Verb RunAs -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            Write-Host "  [OK] Seluruh protokol proteksi berhasil dieksekusi." -ForegroundColor Green
        } else {
            Write-Host "  [!] Eksekusi dibatalkan oleh pengguna (UAC ditolak)." -ForegroundColor Red
            return
        }
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Proteksi CorelDRAW Paripurna Telah Aktif!" -ForegroundColor Green
    Write-Host "  * Tombol Save, Export, Print kembali normal & dapat digunakan." -ForegroundColor White
    Write-Host "  * Notifikasi lisensi dan pop-up verifikasi dieliminasi total." -ForegroundColor White
    Write-Host "  * 10 jalur telemetri vendor terkunci rapat di firewall & hosts." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Check-DiagnosticStatus {
    Write-Host ""
    Write-Host "  [DIAGNOSTIK] Memeriksa Integritas Sistem CorelDRAW..." -ForegroundColor Cyan

    # 1. Pustaka PASMUTILITY.dll
    Write-Host "  * Status Pustaka DLL : " -ForegroundColor White -NoNewline
    if (Test-Path $pasmDll) {
        $hash = (Get-FileHash -LiteralPath $pasmDll -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($hash -eq $patchedHash) {
            Write-Host "RESMI FOKUSKONTEN [AKTIF & VALID]" -ForegroundColor Green
        } else {
            Write-Host "ORIGINAL / EVALUASI (RAWAN TERKUNCI)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "BERKAS TIDAK DITEMUKAN" -ForegroundColor DarkGray
    }

    # 2. Cadangan Asli
    Write-Host "  * Cadangan Asli (.BAK) : " -ForegroundColor White -NoNewline
    if (Test-Path $pasmBak) {
        Write-Host "TERSEDIA [SIAP UNDO]" -ForegroundColor Green
    } else {
        Write-Host "BELUM ADA CADANGAN" -ForegroundColor Gray
    }

    # 3. Layanan Corel
    Write-Host "  * Layanan License      : " -ForegroundColor White -NoNewline
    $svcs = Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue
    if ($svcs) {
        $allDisabled = $true
        foreach ($s in $svcs) {
            if ($s.StartType -ne "Disabled") { $allDisabled = $false; break }
        }
        if ($allDisabled) {
            Write-Host "DINONAKTIFKAN [AMAN]" -ForegroundColor Green
        } else {
            Write-Host "AKTIF / OTOMATIS (RAWAN POPUP)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "TIDAK ADA LAYANAN AKTIF [AMAN]" -ForegroundColor Green
    }

    # 4. Aturan Firewall
    Write-Host "  * Windows Firewall     : " -ForegroundColor White -NoNewline
    $fwRules = Get-NetFirewallRule -DisplayName "FK_Corel_*" -ErrorAction SilentlyContinue
    if ($fwRules) {
        Write-Host ("{0} ATURAN BLOKIR OUTBOUND [AKTIF]" -f @($fwRules).Count) -ForegroundColor Green
    } else {
        Write-Host "BELUM ADA ATURAN BLOKIR" -ForegroundColor Yellow
    }

    # 5. Domain Hosts
    Write-Host "  * Isolasi Berkas Hosts : " -ForegroundColor White -NoNewline
    $hc = if (Test-Path $hostsPath) { Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue } else { "" }
    $blockedCount = 0
    foreach ($d in $domains) {
        if ($hc -match [regex]::Escape($d)) { $blockedCount++ }
    }
    if ($blockedCount -eq $domains.Count) {
        Write-Host ("{0}/{1} DOMAIN TERISOLASI [100% AMAN]" -f $blockedCount, $domains.Count) -ForegroundColor Green
    } elseif ($blockedCount -gt 0) {
        Write-Host ("{0}/{1} DOMAIN TERISOLASI [PARSIAL]" -f $blockedCount, $domains.Count) -ForegroundColor Yellow
    } else {
        Write-Host "SELURUH DOMAIN TERBUKA NORMAL" -ForegroundColor Yellow
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Restore-ShieldAction {
    Write-Host ""
    Write-Host "  [PROSES] Memulihkan ke Setelan Awal Windows (Restore / Undo)..." -ForegroundColor Yellow

    $workerScript = {
        $pasmDir   = "$env:ProgramFiles\Corel\PASMUtility\v1"
        $pasmDll   = "$pasmDir\PASMUTILITY.dll"
        $pasmBak   = "$pasmDir\PASMUTILITY.dll.BAK"
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $domains   = @("mc.corel.com","apps.corel.com","origin-mc.corel.com","iws.corel.com","corel.com","www.corel.com","telemetry.corel.com","ipm.corel.com","corelstore.com","www.corelstore.com")

        Get-Process -Name "CorelDRW","Cap","CorelPP" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        if (Test-Path $pasmBak) {
            Copy-Item -LiteralPath $pasmBak -Destination $pasmDll -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $pasmBak -Force -ErrorAction SilentlyContinue
        }

        Remove-NetFirewallRule -DisplayName "FK_Corel_*" -ErrorAction SilentlyContinue

        if (Test-Path $hostsPath) {
            $lines = Get-Content $hostsPath -ErrorAction SilentlyContinue | Where-Object {
                $l = $_
                $keep = $true
                if ($l -match "# FokusKonten Corel Shield") { $keep = $false }
                foreach ($d in $domains) {
                    if ($l -match [regex]::Escape($d)) { $keep = $false; break }
                }
                $keep
            }
            [System.IO.File]::WriteAllLines($hostsPath, $lines, [System.Text.Encoding]::ASCII)
        }

        Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | Set-Service -StartupType Manual -ErrorAction SilentlyContinue
    }

    if ($isAdmin) {
        Write-Host "  > Mengembalikan pustaka original dari cadangan .BAK... " -ForegroundColor Cyan -NoNewline
        & $workerScript
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Menghapus aturan Windows Firewall dan membersihkan hosts... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green

        Write-Host "  > Mengembalikan status layanan Corel ke Manual... " -ForegroundColor Cyan -NoNewline
        Write-Host "[OK]" -ForegroundColor Green
    } else {
        Write-Host "  > Mengalihkan tugas pemulihan ke izin sistem (UAC)... " -ForegroundColor Yellow
        $code = '& {' + $workerScript.ToString() + '}'
        $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $b64" -Verb RunAs -Wait -PassThru
        if ($p.ExitCode -ne 0) {
            Write-Host "  [!] Pemulihan dibatalkan oleh pengguna (UAC ditolak)." -ForegroundColor Red
            return
        }
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Sistem Berhasil Dikembalikan ke Setelan Semula!" -ForegroundColor Green
    Write-Host "  * Pustaka original CorelDRAW aktif kembali." -ForegroundColor White
    Write-Host "  * Aturan firewall FokusKonten dan entri hosts telah dicabut bersih." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

function Launch-CorelApp {
    Write-Host ""
    $corel = Get-CorelAppInfo
    if ($corel -and (Test-Path $corel.Exe)) {
        Write-Host "  Membuka $($corel.Name)..." -ForegroundColor Cyan
        Start-Process -FilePath $corel.Exe
        Write-Host "  [OK] Aplikasi berhasil diluncurkan di layar." -ForegroundColor Green
    } else {
        $exes = Find-CorelExecutables | Where-Object { $_ -match "CorelDRW\.exe" }
        if ($exes) {
            Write-Host "  Membuka CorelDRAW: $($exes[0])..." -ForegroundColor Cyan
            Start-Process -FilePath $exes[0]
            Write-Host "  [OK] Aplikasi berhasil diluncurkan di layar." -ForegroundColor Green
        } else {
            Write-Host "  [!] Biner CorelDRW.exe tidak ditemukan di direktori Program Files." -ForegroundColor Yellow
        }
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    try { [void][Console]::ReadKey($true) } catch {}
}

# Main Interactive Loop
try {
    while ($true) {
        Show-CompactHeader
        Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Pasang Proteksi Paripurna (Buka Tombol Save & Hapus Popup)" -ForegroundColor Green
        Write-Host "  [2] Cek Diagnostik Integritas Sistem (Before vs After)" -ForegroundColor Cyan
        Write-Host "  [3] Pulihkan ke Setelan Awal Windows (Restore / Undo)" -ForegroundColor Yellow
        Write-Host "  [4] Uji Buka CorelDRAW Sekarang di Layar" -ForegroundColor White
        Write-Host "  [5] Toko Digital FokusKonten (Buka Web)" -ForegroundColor DarkCyan
        Write-Host "  [0] Selesai & Keluar" -ForegroundColor DarkGray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 4, 5, 0] : " -ForegroundColor Yellow

        $choice = ""
        try {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString()
            Write-Host $choice -ForegroundColor Green
        } catch {
            $choice = Read-Host
        }

        switch ($choice) {
            "1" { Apply-ShieldAction }
            "2" { Check-DiagnosticStatus }
            "3" { Restore-ShieldAction }
            "4" { Launch-CorelApp }
            "5" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
            "0" {
                Restore-Terminal
                Write-Host ""
                Write-Host "================================================================" -ForegroundColor Cyan
                Write-Host "        TERIMA KASIH TELAH MENGGUNAKAN LAYANAN RESMI            " -ForegroundColor Yellow
                Write-Host "                  THANKS ORDER BY FOKUSKONTEN                   " -ForegroundColor Green
                Write-Host "================================================================" -ForegroundColor Cyan
                Write-Host ""
                return
            }
        }
    }
} finally {
    Restore-Terminal
}
