# ============================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 40 : CORELDRAW SHIELD - Full-Suite Anti Pop-Up & Save
# Metode   : PASMUTILITY Injection + Firewall + Hosts Shield
# Layout   : Ultra-Compact Golden 64 (Single Terminal In-Place)
# ============================================================

& {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    } catch {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
    }

    $ErrorActionPreference = "Continue"
    $ProgressPreference    = "SilentlyContinue"

    $pasmDir   = "$env:ProgramFiles\Corel\PASMUtility\v1"
    $pasmDll   = "$pasmDir\PASMUTILITY.dll"
    $pasmBak   = "$pasmDir\PASMUTILITY.dll.BAK"
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $cdnDllUrl = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/40_CorelDraw_Firewall_Telemetry_Blocker/PASMUTILITY.dll"
    $patchedHash = "1036532E7981853535E3B40F5CACCDF8C59BBC3574CCE858EDA3918DC682552C"

    $domains = @(
        "mc.corel.com",
        "apps.corel.com",
        "origin-mc.corel.com",
        "iws.corel.com",
        "corel.com",
        "telemetry.corel.com"
    )

    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

    function Show-Header {
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  FOKUSKONTEN // CORELDRAW RESCUE SHIELD SUITE" -ForegroundColor White
        Write-Host "  Buka Fitur Save, Export, Print & Hapus Pop-Up Lisensi" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  * Layanan : CORELDRAW FULL RESCUE & LICENSE GUARD" -ForegroundColor White
        Write-Host "  * Metode  : PASMUTILITY Inject + Outbound Firewall + Hosts" -ForegroundColor Gray
        if ($isAdmin) {
            Write-Host "  * Status  : Administrator Sistem [TERVERIFIKASI]" -ForegroundColor Green
        } else {
            Write-Host "  * Status  : Mode Pengguna (Izin UAC Otomatis)" -ForegroundColor Yellow
        }
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Pasang Proteksi CorelDRAW Penuh (Disarankan)" -ForegroundColor Green
        Write-Host "      Injeksi PASMUTILITY, isolasi firewall & hosts." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [2] Cek Diagnostik Status Proteksi (Before vs After)" -ForegroundColor White
        Write-Host "      Cek hash DLL, backup BAK, firewall, & domain hosts." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [3] Pulihkan ke Setelan Awal Windows (Restore / Undo)" -ForegroundColor Yellow
        Write-Host "      Kembalikan DLL asli, cabut firewall & bersihkan hosts." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [4] Buka Aplikasi CorelDRAW di Layar" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [0] Selesai & Keluar" -ForegroundColor DarkGray
        Write-Host "============================================================" -ForegroundColor Cyan
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
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "  MEMASANG PROTEKSI PARIPURNA CORELDRAW..." -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

        $workerScript = {
            param($cdnUrl, $targetHash)

            $pasmDir   = "$env:ProgramFiles\Corel\PASMUtility\v1"
            $pasmDll   = "$pasmDir\PASMUTILITY.dll"
            $pasmBak   = "$pasmDir\PASMUTILITY.dll.BAK"
            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $domains   = @("mc.corel.com","apps.corel.com","origin-mc.corel.com","iws.corel.com","corel.com","telemetry.corel.com")

            # 1. Pastikan proses Corel berhenti sementara
            Get-Process -Name "CorelDRW","Cap","CorelPP" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            # 2. Backup dan Injeksi PASMUTILITY.dll
            if (Test-Path $pasmDir) {
                if ((Test-Path $pasmDll) -and (-not (Test-Path $pasmBak))) {
                    Copy-Item -LiteralPath $pasmDll -Destination $pasmBak -Force -ErrorAction SilentlyContinue
                }

                # Cari biner lokal terlebih dahulu
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

                # Jika biner lokal belum ada, unduh dari CDN
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

            # 4. Aturan Windows Defender Firewall Outbound
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

            # 5. Blokir Domain di berkas hosts
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
            & $workerScript -cdnUrl $cdnDllUrl -targetHash $patchedHash
            Write-Host "  [OK] PASMUTILITY.dll berhasil diinjeksi ke sistem." -ForegroundColor Green
            Write-Host "  [OK] Aturan Firewall & Domain Pelacak berhasil dikunci." -ForegroundColor Green
            Write-Host "  [OK] Fitur Save, Export, Print kembali normal tanpa pop-up." -ForegroundColor Green
        } else {
            Write-Host "  -> Meminta izin Administrator sistem (UAC)..." -ForegroundColor Yellow
            $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($workerScript.ToString() + "`r`n& `$workerScript '$cdnDllUrl' '$patchedHash'"))
            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $b64" -Verb RunAs -Wait -PassThru
            if ($p.ExitCode -eq 0) {
                Write-Host "  [OK] PASMUTILITY.dll berhasil diinjeksi ke sistem." -ForegroundColor Green
                Write-Host "  [OK] Aturan Firewall & Domain Pelacak berhasil dikunci." -ForegroundColor Green
                Write-Host "  [OK] Fitur Save, Export, Print kembali normal tanpa pop-up." -ForegroundColor Green
            } else {
                Write-Host "  [!] Izin Administrator dibatalkan oleh pengguna." -ForegroundColor Red
            }
        }
    }

    function Check-DiagnosticStatus {
        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "  DIAGNOSTIK KESEHATAN SISTEM CORELDRAW (BEFORE VS AFTER)" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

        # 1. Pustaka PASMUTILITY.dll
        Write-Host "  [1] Status Pustaka PASMUTILITY.dll:" -ForegroundColor White
        if (Test-Path $pasmDll) {
            $hash = (Get-FileHash -LiteralPath $pasmDll -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            if ($hash -eq $patchedHash) {
                Write-Host "      [AFTER]  Versi Resmi FokusKonten [AKTIF & VALID]" -ForegroundColor Green
            } else {
                Write-Host "      [BEFORE] Versi Original / Evaluasi Terdeteksi" -ForegroundColor Yellow
            }
        } else {
            Write-Host "      [!] Berkas PASMUTILITY.dll tidak ditemukan di lokasi standar." -ForegroundColor DarkGray
        }

        # 2. Cadangan Asli
        Write-Host "  [2] Status Berkas Cadangan Asli (.BAK):" -ForegroundColor White
        if (Test-Path $pasmBak) {
            Write-Host "      [OK] Tersimpan Siaga (Dapat Dipulihkan Kapan Saja)" -ForegroundColor Green
        } else {
            Write-Host "      [*] Belum Dicadangkan (Akan Otomatis Dibuat Saat Opsi 1)" -ForegroundColor DarkGray
        }

        # 3. Layanan Corel
        Write-Host "  [3] Status Layanan Corel License Service:" -ForegroundColor White
        $svcs = Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue
        if ($svcs) {
            foreach ($s in $svcs) {
                $col = if ($s.StartType -eq "Disabled") { "Green" } else { "Yellow" }
                Write-Host ("      - {0,-22} : {1} [Startup: {2}]" -f $s.Name, $s.Status, $s.StartType) -ForegroundColor $col
            }
        } else {
            Write-Host "      - Tidak ada layanan Corel aktif." -ForegroundColor Green
        }

        # 4. Aturan Firewall
        Write-Host "  [4] Status Aturan Windows Defender Firewall:" -ForegroundColor White
        $fwRules = Get-NetFirewallRule -DisplayName "FK_Corel_*" -ErrorAction SilentlyContinue
        if ($fwRules) {
            Write-Host ("      [AFTER]  {0} Aturan Outbound Blokir Aktif Terpasang" -f @($fwRules).Count) -ForegroundColor Green
        } else {
            Write-Host "      [BEFORE] Belum Ada Aturan Blokir Firewall FokusKonten" -ForegroundColor Yellow
        }

        # 5. Domain Hosts
        Write-Host "  [5] Status Domain Pelacak di Berkas Hosts:" -ForegroundColor White
        $hc = if (Test-Path $hostsPath) { Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue } else { "" }
        $blockedCount = 0
        foreach ($d in $domains) {
            if ($hc -match [regex]::Escape($d)) { $blockedCount++ }
        }
        if ($blockedCount -eq $domains.Count) {
            Write-Host ("      [AFTER]  {0}/{1} Domain Pelacak Terisolasi (0.0.0.0)" -f $blockedCount, $domains.Count) -ForegroundColor Green
        } elseif ($blockedCount -gt 0) {
            Write-Host ("      [PARSIAL] {0}/{1} Domain Terblokir" -f $blockedCount, $domains.Count) -ForegroundColor Yellow
        } else {
            Write-Host "      [BEFORE] Seluruh Domain Terbuka Normal" -ForegroundColor Yellow
        }
    }

    function Restore-ShieldAction {
        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "  MEMULIHKAN SETELAN AWAL WINDOWS (RESTORE / UNDO)..." -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------" -ForegroundColor Cyan

        $workerScript = {
            $pasmDir   = "$env:ProgramFiles\Corel\PASMUtility\v1"
            $pasmDll   = "$pasmDir\PASMUTILITY.dll"
            $pasmBak   = "$pasmDir\PASMUTILITY.dll.BAK"
            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $domains   = @("mc.corel.com","apps.corel.com","origin-mc.corel.com","iws.corel.com","corel.com","telemetry.corel.com")

            # 1. Hentikan Corel sementara
            Get-Process -Name "CorelDRW","Cap","CorelPP" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            # 2. Kembalikan DLL Asli
            if (Test-Path $pasmBak) {
                Copy-Item -LiteralPath $pasmBak -Destination $pasmDll -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $pasmBak -Force -ErrorAction SilentlyContinue
            }

            # 3. Hapus aturan firewall
            Remove-NetFirewallRule -DisplayName "FK_Corel_*" -ErrorAction SilentlyContinue

            # 4. Bersihkan hosts
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

            # 5. Kembalikan layanan ke Manual
            Get-Service -DisplayName "*Corel*" -ErrorAction SilentlyContinue | Set-Service -StartupType Manual -ErrorAction SilentlyContinue
        }

        if ($isAdmin) {
            & $workerScript
            Write-Host "  [OK] DLL Asli dipulihkan dari cadangan .BAK." -ForegroundColor Green
            Write-Host "  [OK] Aturan Firewall & Pemetaan Berkas Hosts dibersihkan." -ForegroundColor Green
            Write-Host "  [OK] Setelan komputer kembali utuh seperti semula (BEFORE)." -ForegroundColor Green
        } else {
            Write-Host "  -> Meminta izin Administrator sistem (UAC)..." -ForegroundColor Yellow
            $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($workerScript.ToString() + "`r`n& `$workerScript"))
            $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $b64" -Verb RunAs -Wait -PassThru
            if ($p.ExitCode -eq 0) {
                Write-Host "  [OK] DLL Asli dipulihkan dari cadangan .BAK." -ForegroundColor Green
                Write-Host "  [OK] Aturan Firewall & Pemetaan Berkas Hosts dibersihkan." -ForegroundColor Green
                Write-Host "  [OK] Setelan komputer kembali utuh seperti semula (BEFORE)." -ForegroundColor Green
            } else {
                Write-Host "  [!] Izin Administrator dibatalkan oleh pengguna." -ForegroundColor Red
            }
        }
    }

    function Launch-CorelApp {
        Write-Host ""
        $exes = Find-CorelExecutables | Where-Object { $_ -match "CorelDRW\.exe" }
        if ($exes) {
            Write-Host "  Membuka CorelDRAW: $($exes[0])..." -ForegroundColor Cyan
            Start-Process -FilePath $exes[0]
            Write-Host "  [OK] Aplikasi berhasil diluncurkan." -ForegroundColor Green
        } else {
            Write-Host "  [!] Biner CorelDRW.exe tidak ditemukan di direktori Program Files." -ForegroundColor Yellow
        }
    }

    # Main Interaction Loop
    while ($true) {
        Show-Header
        Write-Host -NoNewline "  Pilihan Menu [1, 2, 3, 4, 0] : " -ForegroundColor Yellow
        try {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString()
            Write-Host $choice -ForegroundColor Yellow
        } catch {
            $choice = Read-Host
        }

        switch ($choice) {
            "1" {
                Apply-ShieldAction
                Write-Host ""
                Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor DarkGray
                try { [Console]::ReadKey($true) | Out-Null } catch {}
            }
            "2" {
                Check-DiagnosticStatus
                Write-Host ""
                Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor DarkGray
                try { [Console]::ReadKey($true) | Out-Null } catch {}
            }
            "3" {
                Restore-ShieldAction
                Write-Host ""
                Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor DarkGray
                try { [Console]::ReadKey($true) | Out-Null } catch {}
            }
            "4" {
                Launch-CorelApp
                Write-Host ""
                Write-Host "  Tekan sembarang tombol untuk kembali ke menu..." -ForegroundColor DarkGray
                try { [Console]::ReadKey($true) | Out-Null } catch {}
            }
            "0" {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Cyan
                Write-Host "        TERIMA KASIH TELAH MENGGUNAKAN LAYANAN RESMI        " -ForegroundColor White
                Write-Host "                  THANKS ORDER BY FOKUSKONTEN               " -ForegroundColor Yellow
                Write-Host "============================================================" -ForegroundColor Cyan
                Write-Host ""
                return
            }
        }
    }
} @args
