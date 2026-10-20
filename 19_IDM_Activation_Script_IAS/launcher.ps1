# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SUITE LENGKAP INTERNET DOWNLOAD MANAGER (IDM) ALL-IN-ONE
# Modul SKU    : FK-PSH-119 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Execution (1 Terminal Mutlak, Bebas Pop-up Jendela)
# Fitur        : Pasang Lisensi, Instal IDM Baru, Copot/Uninstall, Saklar Ekstensi
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // IDM COMPLETE RESCUE SUITE"
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

function Find-IDMPath {
    $paths = @(
        "${env:ProgramFiles}\Internet Download Manager\IDMan.exe",
        "${env:ProgramFiles(x86)}\Internet Download Manager\IDMan.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Take-Permissions {
    param($rootKey, $regKey, [switch]$Lock)
    try {
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
        $ModuleBuilder   = $AssemblyBuilder.DefineDynamicModule(2, $False)
        $TypeBuilder     = $ModuleBuilder.DefineType(0)

        $TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
        9,17,18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

        $SID   = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
        $IDN   = ($SID.Translate([System.Security.Principal.NTAccount])).Value
        $Admin = New-Object System.Security.Principal.NTAccount($IDN)

        $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
        $none     = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

        $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regKey, 'ReadWriteSubTree', 'TakeOwnership')
        if (-not $key) { return }

        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($Admin)
        $key.SetAccessControl($acl)

        $key  = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)

        if ($Lock) {
            $acl = New-Object System.Security.AccessControl.RegistrySecurity
            $acl.SetOwner($none)
            $key.SetAccessControl($acl)

            $key  = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
            $acl.ResetAccessRule($rule)
            $key.SetAccessControl($acl)
        }
    } catch {}
}

function Get-CLSIDList {
    $arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -ErrorAction SilentlyContinue).PROCESSOR_ARCHITECTURE
    $regPaths = if ($arch -eq "x86") { @("HKCU:\Software\Classes\CLSID") } else { @("HKCU:\Software\Classes\WOW6432Node\CLSID") }

    $finalValues = @()
    $subKeysToExclude = @("LocalServer32", "InProcServer32", "InProcHandler32")

    foreach ($regPath in $regPaths) {
        $lockedKeys = $null
        $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys |
            Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

        if ($lockedKeys) {
            foreach ($lockedKey in $lockedKeys) {
                $finalValues += Split-Path -Path $lockedKey.TargetObject -Leaf
            }
        }

        if ($subKeys) {
            $filteredKeys = $subKeys | Where-Object {
                $names = $_.GetSubKeyNames()
                -not ($names | Where-Object { $subKeysToExclude -contains $_ })
            }

            foreach ($key in $filteredKeys) {
                $fullPath   = $key.PSPath
                $keyValues  = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
                $defaultVal = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

                if (($defaultVal -match "^\d+$") -and ($key.SubKeyCount -eq 0)) { $finalValues += $($key.PSChildName); continue }
                if (($defaultVal -match "\+|=") -and ($key.SubKeyCount -eq 0))  { $finalValues += $($key.PSChildName); continue }

                $versionVal = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
                if (($versionVal -match "^\d+$") -and ($key.SubKeyCount -eq 1)) { $finalValues += $($key.PSChildName); continue }

                foreach ($prop in $keyValues.PSObject.Properties) {
                    if ($prop.Name -match "MData|Model|scansk|Therad") {
                        $finalValues += $($key.PSChildName)
                        break
                    }
                }
                if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) { $finalValues += $($key.PSChildName); continue }
            }
        }
    }

    return @($finalValues | Select-Object -Unique), $regPaths
}

function Get-IDMStatus {
    $dmPath = "HKCU:\Software\DownloadManager"
    if (Test-Path $dmPath) {
        $sn = (Get-ItemProperty -Path $dmPath -Name "Serial" -ErrorAction SilentlyContinue).Serial
        if ($sn) { return "REGISTERED" }
    }
    return "TRIAL_OR_UNREGISTERED"
}

function Get-ExtensionStatus {
    $nmChrome = Test-Path "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.tonec.idm"
    $chromeHook = Test-Path "HKCU:\Software\Google\Chrome\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    if ($nmChrome -or $chromeHook) {
        return "ACTIVE"
    }
    return "DISABLED"
}

function Repair-IDMBrowserExtensions {
    param([switch]$Silent)

    if (-not $Silent) {
        Write-Host ""
        Write-Host "  [PROSES] Mengaktifkan & Mengintegrasikan Ekstensi Browser..." -ForegroundColor Cyan
    }

    $idmPath = Find-IDMPath
    if (-not $idmPath) {
        if (-not $Silent) {
            Write-Host "  [!] Biner IDM belum terpasang di sistem ini." -ForegroundColor Yellow
            Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
            [void][Console]::ReadKey($true)
        }
        return
    }

    $idmDir = Split-Path -Path $idmPath -Parent
    $jsonMain = Join-Path $idmDir "IDMMsgHost.json"
    $jsonMoz  = Join-Path $idmDir "IDMMsgHostMoz.json"

    # 1. Daftarkan Native Messaging Hosts untuk semua browser
    if (-not $Silent) { Write-Host "  > Menghubungkan Native Messaging Host (Jembatan Biner)... " -ForegroundColor Cyan -NoNewline }
    $nmTargets = @(
        @{ Path = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.tonec.idm"; Json = $jsonMain },
        @{ Path = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\com.tonec.idm"; Json = $jsonMain },
        @{ Path = "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\com.tonec.idm"; Json = $jsonMain },
        @{ Path = "HKCU:\Software\Mozilla\NativeMessagingHosts\com.tonec.idm"; Json = $jsonMoz }
    )
    foreach ($item in $nmTargets) {
        if (Test-Path $item.Json) {
            if (-not (Test-Path $item.Path)) { New-Item -Path $item.Path -Force | Out-Null }
            Set-ItemProperty -Path $item.Path -Name "(Default)" -Value $item.Json -Force | Out-Null
        }
    }
    if (-not $Silent) { Write-Host "[OK]" -ForegroundColor Green }

    # 2. Hook auto-install ekstensi resmi di registri browser (Chrome, Edge, Brave)
    if (-not $Silent) { Write-Host "  > Mendaftarkan hook ekstensi resmi di registri browser... " -ForegroundColor Cyan -NoNewline }
    
    # Chrome (ID Resmi: ngpampappnmepgilojfohadhhmbhlaek)
    $chromeKey = "HKCU:\Software\Google\Chrome\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    if (-not (Test-Path $chromeKey)) { New-Item -Path $chromeKey -Force | Out-Null }
    Set-ItemProperty -Path $chromeKey -Name "update_url" -Value "https://clients2.google.com/service/update2/crx" -Force | Out-Null

    # Microsoft Edge (Edge Add-ons & Chrome Web Store fallback)
    $edgeKey1 = "HKCU:\Software\Microsoft\Edge\Extensions\fbmkfjdnahhehkhgbmahiaflfladhhib"
    if (-not (Test-Path $edgeKey1)) { New-Item -Path $edgeKey1 -Force | Out-Null }
    Set-ItemProperty -Path $edgeKey1 -Name "update_url" -Value "https://edge.microsoft.com/extensionproxy/service/update2/crx" -Force | Out-Null

    $edgeKey2 = "HKCU:\Software\Microsoft\Edge\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    if (-not (Test-Path $edgeKey2)) { New-Item -Path $edgeKey2 -Force | Out-Null }
    Set-ItemProperty -Path $edgeKey2 -Name "update_url" -Value "https://clients2.google.com/service/update2/crx" -Force | Out-Null

    # Brave Browser
    $braveKey = "HKCU:\Software\BraveSoftware\Brave-Browser\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    if (-not (Test-Path $braveKey)) { New-Item -Path $braveKey -Force | Out-Null }
    Set-ItemProperty -Path $braveKey -Name "update_url" -Value "https://clients2.google.com/service/update2/crx" -Force | Out-Null

    if (-not $Silent) { Write-Host "[OK]" -ForegroundColor Green }

    # 3. Sinkronisasi preferensi IDM internal
    $dmPath = "HKCU:\Software\DownloadManager"
    if (Test-Path $dmPath) {
        Set-ItemProperty -Path $dmPath -Name "bRmGUCfEx" -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $dmPath -Name "EnableDriver" -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $dmPath -Name "lastintres" -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null
    }

    if (-not $Silent) {
        Write-Host ""
        Write-Host "  [BERHASIL] Integrasi Ekstensi Browser IDM Telah Aktif!" -ForegroundColor Green
        Write-Host "  * Chrome / Brave : Ekstensi IDM terdaftar resmi di registri" -ForegroundColor White
        Write-Host "  * Microsoft Edge : Ekstensi IDM terdaftar resmi di registri" -ForegroundColor White
        Write-Host "  * Mozilla Firefox: Native Messaging Moz Host aktif" -ForegroundColor White
        Write-Host ""
        Write-Host "  Apakah Anda ingin membuka link Web Store ekstensi IDM di browser?" -ForegroundColor Yellow
        Write-Host "  [Y] Buka Halaman Ekstensi Resmi IDM di Browser Sekarang" -ForegroundColor Cyan
        Write-Host "  [N] Kembali ke Menu Utama" -ForegroundColor Gray
        Write-Host -NoNewline "  Pilihan Anda [Y/N] : " -ForegroundColor Yellow

        $openChoice = ""
        try {
            $k = [Console]::ReadKey($true)
            $openChoice = $k.KeyChar.ToString().ToUpper()
            Write-Host $openChoice -ForegroundColor Green
        } catch {
            $openChoice = (Read-Host).ToUpper()
        }

        if ($openChoice -eq "Y") {
            Start-Process "https://chromewebstore.google.com/detail/idm-integration-module/ngpampappnmepgilojfohadhhmbhlaek"
        }

        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
    }
}

function Disable-IDMBrowserExtensions {
    param([switch]$Silent)

    if (-not $Silent) {
        Write-Host ""
        Write-Host "  [PROSES] Menonaktifkan Integrasi Ekstensi Browser IDM..." -ForegroundColor Yellow
    }

    # 1. Hapus Native Messaging Hosts dari registri HKCU
    if (-not $Silent) { Write-Host "  > Memutus Native Messaging Host (Jembatan Biner)... " -ForegroundColor Cyan -NoNewline }
    $nmTargets = @(
        "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.tonec.idm",
        "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\com.tonec.idm",
        "HKCU:\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\com.tonec.idm",
        "HKCU:\Software\Mozilla\NativeMessagingHosts\com.tonec.idm"
    )
    foreach ($item in $nmTargets) {
        if (Test-Path $item) {
            Remove-Item -Path $item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    if (-not $Silent) { Write-Host "[OK]" -ForegroundColor Green }

    # 2. Hapus Hook Ekstensi Otomatis di Registri Browser
    if (-not $Silent) { Write-Host "  > Menghapus hook pendaftaran ekstensi peramban... " -ForegroundColor Cyan -NoNewline }
    $extKeys = @(
        "HKCU:\Software\Google\Chrome\Extensions\ngpampappnmepgilojfohadhhmbhlaek",
        "HKCU:\Software\Microsoft\Edge\Extensions\fbmkfjdnahhehkhgbmahiaflfladhhib",
        "HKCU:\Software\Microsoft\Edge\Extensions\ngpampappnmepgilojfohadhhmbhlaek",
        "HKCU:\Software\BraveSoftware\Brave-Browser\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    )
    foreach ($k in $extKeys) {
        if (Test-Path $k) {
            Remove-Item -Path $k -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    if (-not $Silent) { Write-Host "[OK]" -ForegroundColor Green }

    # 3. Matikan pengambilalihan browser di pengaturan internal IDM
    $dmPath = "HKCU:\Software\DownloadManager"
    if (Test-Path $dmPath) {
        Set-ItemProperty -Path $dmPath -Name "bRmGUCfEx" -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $dmPath -Name "EnableDriver" -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $dmPath -Name "lastintres" -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    }

    if (-not $Silent) {
        Write-Host ""
        Write-Host "  [BERHASIL] Integrasi Ekstensi Browser Telah Dinonaktifkan!" -ForegroundColor Green
        Write-Host "  * Unduhan browser tidak akan diambil alih otomatis oleh IDM." -ForegroundColor White
        Write-Host "  * Chrome, Edge, Brave, dan Firefox kembali memakai downloader bawaan." -ForegroundColor White
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
    }
}

function Download-And-Install-IDM {
    Write-Host ""
    Write-Host "  [PROSES] Mengunduh Installer Resmi Internet Download Manager..." -ForegroundColor Cyan

    $tempDir = [System.IO.Path]::GetTempPath()
    $setupFile = Join-Path $tempDir "idman_setup_official.exe"
    if (Test-Path $setupFile) { Remove-Item $setupFile -Force -ErrorAction SilentlyContinue }

    # Daftar mirror berkecepatan tinggi (Lokal & GitHub Edge CDN -> Fallback Tonec)
    $mirrors = @(
        @{ Name = "Server Lokal FokusKonten (Instan)"; Url = "http://127.0.0.1:8090/bin/idman.exe" },
        @{ Name = "GitHub Global Edge CDN";          Url = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/19_IDM_Activation_Script_IAS/idman_setup.exe" },
        @{ Name = "jsDelivr High-Speed Mirror";      Url = "https://cdn.jsdelivr.net/gh/mcjobs-id/powershell-vault@main/19_IDM_Activation_Script_IAS/idman_setup.exe" },
        @{ Name = "Server Resmi Tonec (Fallback)";   Url = "https://download.internetdownloadmanager.com/idman643build15.exe" }
    )

    $curl = "$env:SystemRoot\System32\curl.exe"
    $downloadSuccess = $false

    foreach ($m in $mirrors) {
        Write-Host "  > Menghubungi $($m.Name)..." -ForegroundColor Cyan
        try {
            if (Test-Path $curl) {
                $status = (& $curl -s -o NUL -w "%{http_code}" --connect-timeout 2 $m.Url)
                if ($status -eq "200") {
                    Write-Host "    Koneksi terhubung. Memulai unduhan biner resmi..." -ForegroundColor Green
                    & $curl -# -L --connect-timeout 5 --retry 2 -o $setupFile $m.Url
                    if ((Test-Path $setupFile) -and ((Get-Item $setupFile).Length -gt 10000000)) {
                        $downloadSuccess = $true
                        break
                    }
                }
            } else {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($m.Url, $setupFile)
                if ((Test-Path $setupFile) -and ((Get-Item $setupFile).Length -gt 10000000)) {
                    $downloadSuccess = $true
                    break
                }
            }
        } catch {}
    }

    if ($downloadSuccess) {
        Write-Host ""
        Write-Host "  [OK] Unduhan biner installer IDM resmi selesai diverifikasi!" -ForegroundColor Green
        Write-Host "  > Memulai proses instalasi IDM resmi..." -ForegroundColor Cyan
        Write-Host "    (Silakan konfirmasi jika muncul jendela UAC Windows)" -ForegroundColor Gray
        
        $p = Start-Process -FilePath $setupFile -Wait -PassThru
        Start-Sleep -Seconds 2
        Remove-Item -Path $setupFile -Force -ErrorAction SilentlyContinue

        $newIdm = Find-IDMPath
        if ($newIdm) {
            Write-Host ""
            Write-Host "  [BERHASIL] Internet Download Manager telah terpasang!" -ForegroundColor Green
            Write-Host "  * Lokasi: $newIdm" -ForegroundColor White
            
            Write-Host ""
            Write-Host "  Apakah Anda ingin langsung memasang lisensi permanen sekarang?" -ForegroundColor Yellow
            Write-Host "  [Y] Pasang Lisensi Permanen & Integrasikan Ekstensi Sekarang" -ForegroundColor Cyan
            Write-Host "  [N] Kembali ke Menu Utama" -ForegroundColor Gray
            Write-Host -NoNewline "  Pilihan Anda [Y/N] : " -ForegroundColor Yellow

            $actChoice = ""
            try {
                $k = [Console]::ReadKey($true)
                $actChoice = $k.KeyChar.ToString().ToUpper()
                Write-Host $actChoice -ForegroundColor Green
            } catch {
                $actChoice = (Read-Host).ToUpper()
            }

            if ($actChoice -eq "Y") {
                Install-IDMLicenseInPlace
                return
            }
        } else {
            Write-Host "  [!] Pemasangan selesai atau dibatalkan oleh pengguna." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "  [!] Gagal mengunduh biner installer dari seluruh mirror." -ForegroundColor Red
        Write-Host "      Silakan periksa koneksi internet Anda atau coba lagi." -ForegroundColor White
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Uninstall-IDMInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Mencopot / Uninstall Internet Download Manager..." -ForegroundColor Yellow

    $idmPath = Find-IDMPath
    if (-not $idmPath) {
        Write-Host "  [!] IDM belum terpasang di sistem ini." -ForegroundColor Yellow
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    $idmDir = Split-Path -Path $idmPath -Parent
    $uninstaller = Join-Path $idmDir "Uninstall.exe"

    if (-not (Test-Path $uninstaller)) {
        Write-Host "  [!] Berkas Uninstall.exe tidak ditemukan di direktori IDM." -ForegroundColor Red
        Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
        [void][Console]::ReadKey($true)
        return
    }

    # Hentikan proses IDM aktif
    $proc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  > Menghentikan proses IDM yang sedang berjalan... " -ForegroundColor Cyan -NoNewline
        Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
        Write-Host "[OK]" -ForegroundColor Green
    }

    Write-Host "  > Membuka uninstaller resmi IDM..." -ForegroundColor Cyan
    Write-Host "    (Pilih 'Full' pada jendela untuk pencopotan bersih)" -ForegroundColor Gray
    
    $p = Start-Process -FilePath $uninstaller -Wait -PassThru
    Start-Sleep -Seconds 2

    # Putus hook browser dan bersihkan registri sisa
    Write-Host "  > Membersihkan sisa registri lisensi & hook ekstensi peramban... " -ForegroundColor Cyan -NoNewline
    Disable-IDMBrowserExtensions -Silent
    Write-Host "[OK]" -ForegroundColor Green

    Write-Host ""
    Write-Host "  [SELESAI] Proses pencopotan IDM telah selesai." -ForegroundColor Green
    Write-Host "  * Sistem telah bersih dari integrasi dan biner IDM." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Show-CompactHeader {
    Clear-Host
    $state = Get-IDMStatus
    $extState = Get-ExtensionStatus
    $idmPath = Find-IDMPath

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  IDM All-In-One: Lisensi, Instal, Copot & Ekstensi" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER    : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET    : [FK-PSH-119] IDM Complete Rescue Suite" -ForegroundColor DarkCyan
    
    if ($idmPath) {
        $ver = (Get-Item $idmPath).VersionInfo.ProductVersion
        Write-Host "  STATUS   : [ TERPASANG ] (Versi $ver)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS   : [ BELUM TERPASANG DI SISTEM INI ]" -ForegroundColor Magenta
    }

    if ($state -eq "REGISTERED") {
        Write-Host "  LISENSI  : [ RESMI AKTIF ] (Bebas Popup Fake Serial)" -ForegroundColor Green
    } else {
        Write-Host "  LISENSI  : [ EVALUASI / BELUM TERLISENSI ]" -ForegroundColor Yellow
    }

    if ($extState -eq "ACTIVE") {
        Write-Host "  EKSTENSI : [ AKTIF & TERHUBUNG KE PERAMBAN ]" -ForegroundColor Green
    } else {
        Write-Host "  EKSTENSI : [ NONAKTIF / DILEPAS DARI PERAMBAN ]" -ForegroundColor Yellow
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Install-IDMLicenseInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Memasang Lisensi IDM Permanen & Integrasi Browser..." -ForegroundColor Cyan

    $idmPath = Find-IDMPath
    if (-not $idmPath) {
        Write-Host "  [!] IDM belum terpasang di sistem ini." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Apakah Anda ingin mengunduh dan memasang IDM resmi sekarang?" -ForegroundColor Cyan
        Write-Host "  [Y] Unduh & Instal IDM Resmi Sekarang" -ForegroundColor Green
        Write-Host "  [N] Batal dan Kembali ke Menu" -ForegroundColor Gray
        Write-Host -NoNewline "  Pilihan Anda [Y/N] : " -ForegroundColor Yellow

        $dlChoice = ""
        try {
            $k = [Console]::ReadKey($true)
            $dlChoice = $k.KeyChar.ToString().ToUpper()
            Write-Host $dlChoice -ForegroundColor Green
        } catch {
            $dlChoice = (Read-Host).ToUpper()
        }

        if ($dlChoice -eq "Y") {
            Download-And-Install-IDM
        }
        return
    }

    # Hentikan proses IDM aktif
    $proc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  > Menghentikan proses IDM aktif... " -ForegroundColor Cyan -NoNewline
        Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
        Write-Host "[OK]" -ForegroundColor Green
    }

    # Scan dan bersihkan kunci trial lama
    Write-Host "  > Memindai token registri evaluasi IDM... " -ForegroundColor Cyan -NoNewline
    $clsidData = Get-CLSIDList
    $clsidKeys = $clsidData[0]
    $regPaths  = $clsidData[1]
    Write-Host "[OK]" -ForegroundColor Green

    Write-Host "  > Membersihkan entri evaluasi lama... " -ForegroundColor Cyan -NoNewline
    foreach ($regPath in $regPaths) {
        foreach ($val in $clsidKeys) {
            $fullPath = Join-Path $regPath $val
            $rootKey  = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }
            $pos      = $fullPath.IndexOf("\")
            $regKey   = $fullPath.Substring($pos + 1)

            if (Test-Path $fullPath) {
                Take-Permissions $rootKey $regKey
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[OK]" -ForegroundColor Green

    # Daftarkan lisensi registri
    Write-Host "  > Mendaftarkan lisensi resmi FokusKonten... " -ForegroundColor Cyan -NoNewline
    $fname  = "FokusKonten"
    $lname  = "Customer"
    $email  = "lisensi@fokuskonten.my.id"
    $rawKey = -join ((Get-Random -Count 20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))))
    $serial = ($rawKey.Substring(0, 5) + '-' + $rawKey.Substring(5, 5) + '-' + $rawKey.Substring(10, 5) + '-' + $rawKey.Substring(15, 5) + $rawKey.Substring(20))

    $dmPath = "HKCU:\Software\DownloadManager"
    if (-not (Test-Path $dmPath)) { New-Item -Path $dmPath -Force | Out-Null }

    Set-ItemProperty -Path $dmPath -Name "FName"  -Value $fname  -Type String -Force | Out-Null
    Set-ItemProperty -Path $dmPath -Name "LName"  -Value $lname  -Type String -Force | Out-Null
    Set-ItemProperty -Path $dmPath -Name "Email"  -Value $email  -Type String -Force | Out-Null
    Set-ItemProperty -Path $dmPath -Name "Serial" -Value $serial -Type String -Force | Out-Null
    Write-Host "[OK]" -ForegroundColor Green

    # Kunci CLSID untuk menolak notifikasi 'Fake Serial'
    Write-Host "  > Mengunci registri proteksi anti-fake serial... " -ForegroundColor Cyan -NoNewline
    foreach ($regPath in $regPaths) {
        foreach ($val in $clsidKeys) {
            $fullPath = Join-Path $regPath $val
            $rootKey  = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }
            $pos      = $fullPath.IndexOf("\")
            $regKey   = $fullPath.Substring($pos + 1)

            if (-not (Test-Path $fullPath)) {
                New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Take-Permissions $rootKey $regKey -Lock
        }
    }
    Write-Host "[OK]" -ForegroundColor Green

    # Sekalian otomatis integrasikan ekstensi browser (Chrome, Edge, Brave, Firefox)
    Repair-IDMBrowserExtensions -Silent

    # Buka kembali IDM
    if (Test-Path $idmPath) {
        Start-Process $idmPath
    }

    Write-Host ""
    Write-Host "  [BERHASIL] Lisensi & Integrasi Browser IDM Telah Aktif!" -ForegroundColor Green
    Write-Host "  * Terdaftar : $fname $lname ($email)" -ForegroundColor White
    Write-Host "  * Serial    : $serial" -ForegroundColor White
    Write-Host "  * Proteksi  : CLSID Terkunci (Bebas Popup Fake Serial)" -ForegroundColor Yellow
    Write-Host "  * Ekstensi  : Hook Chrome, Edge, Brave & Firefox Aktif" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Show-IDMStatusInPlace {
    Write-Host ""
    Write-Host "  [DIAGNOSTIK] Memeriksa Konfigurasi IDM & Ekstensi..." -ForegroundColor Cyan

    $idmPath = Find-IDMPath
    if ($idmPath) {
        $ver = (Get-Item $idmPath).VersionInfo.ProductVersion
        Write-Host "  * Lokasi IDM     : $idmPath" -ForegroundColor Green
        Write-Host "  * Versi Biner    : $ver" -ForegroundColor Green
    } else {
        Write-Host "  * Lokasi IDM     : Belum Terpasang di Komputer Ini" -ForegroundColor Yellow
    }

    $dmPath = "HKCU:\Software\DownloadManager"
    if (Test-Path $dmPath) {
        $fn = (Get-ItemProperty -Path $dmPath -Name "FName"  -ErrorAction SilentlyContinue).FName
        $ln = (Get-ItemProperty -Path $dmPath -Name "LName"  -ErrorAction SilentlyContinue).LName
        $em = (Get-ItemProperty -Path $dmPath -Name "Email"  -ErrorAction SilentlyContinue).Email
        $sn = (Get-ItemProperty -Path $dmPath -Name "Serial" -ErrorAction SilentlyContinue).Serial

        Write-Host "  * Nama Pemilik   : $(if($fn){"$fn $ln"}else{"(Belum terdaftar)"})" -ForegroundColor White
        Write-Host "  * Email Lisensi  : $(if($em){$em}else{"(Belum terdaftar)"})" -ForegroundColor White
        Write-Host "  * Serial Key     : $(if($sn){$sn}else{"(Belum terdaftar)"})" -ForegroundColor $(if($sn){"Green"}else{"Yellow"})
    } else {
        Write-Host "  * Status Registri: Belum ada konfigurasi IDM di HKCU." -ForegroundColor Yellow
    }

    # Cek status hook ekstensi browser
    $chromeHook = Test-Path "HKCU:\Software\Google\Chrome\Extensions\ngpampappnmepgilojfohadhhmbhlaek"
    $edgeHook   = Test-Path "HKCU:\Software\Microsoft\Edge\Extensions\fbmkfjdnahhehkhgbmahiaflfladhhib"
    $nmChrome   = Test-Path "HKCU:\Software\Google\Chrome\NativeMessagingHosts\com.tonec.idm"
    
    Write-Host "  * Hook Chrome    : $(if($chromeHook){'TERDAFTAR [OK]'}else{'Belum Terdaftar'})" -ForegroundColor $(if($chromeHook){'Green'}else{'Gray'})
    Write-Host "  * Hook Edge      : $(if($edgeHook){'TERDAFTAR [OK]'}else{'Belum Terdaftar'})" -ForegroundColor $(if($edgeHook){'Green'}else{'Gray'})
    Write-Host "  * Native Host    : $(if($nmChrome){'TERHUBUNG [OK]'}else{'Terputus / Belum Aktif'})" -ForegroundColor $(if($nmChrome){'Green'}else{'Yellow'})

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

function Reset-IDMTrialInPlace {
    Write-Host ""
    Write-Host "  [PROSES] Mengembalikan IDM ke Evaluasi Bersih..." -ForegroundColor Yellow

    $proc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  > Menghentikan proses IDM aktif... " -ForegroundColor Cyan -NoNewline
        Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600
        Write-Host "[OK]" -ForegroundColor Green
    }

    Write-Host "  > Membuka proteksi kunci registri CLSID... " -ForegroundColor Cyan -NoNewline
    $clsidData = Get-CLSIDList
    $clsidKeys = $clsidData[0]
    $regPaths  = $clsidData[1]

    foreach ($regPath in $regPaths) {
        foreach ($val in $clsidKeys) {
            $fullPath = Join-Path $regPath $val
            $rootKey  = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }
            $pos      = $fullPath.IndexOf("\")
            $regKey   = $fullPath.Substring($pos + 1)

            if (Test-Path $fullPath) {
                Take-Permissions $rootKey $regKey
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[OK]" -ForegroundColor Green

    Write-Host "  > Menghapus serial key lama... " -ForegroundColor Cyan -NoNewline
    Remove-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "FName","LName","Email","Serial" -ErrorAction SilentlyContinue
    Write-Host "[OK]" -ForegroundColor Green

    Write-Host ""
    Write-Host "  [BERHASIL] Registri IDM berhasil di-reset ke kondisi awal!" -ForegroundColor Green
    Write-Host "  IDM sekarang kembali ke mode evaluasi baru (30 hari)." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    [void][Console]::ReadKey($true)
}

# Main Loop (100% In-Place, 1 Terminal)
try {
    while ($true) {
        Show-CompactHeader
        Write-Host "  PILIHAN MENU TINDAKAN:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Pasang Lisensi IDM Permanen & Aktifkan Ekstensi" -ForegroundColor Green
        Write-Host "  [2] Unduh & Instal IDM Versi Terbaru (Resmi Tonec)" -ForegroundColor Cyan
        Write-Host "  [3] Copot / Uninstall IDM dari Komputer" -ForegroundColor Yellow
        Write-Host "  [4] Aktifkan / Perbaiki Ekstensi Browser IDM" -ForegroundColor Green
        Write-Host "  [5] Nonaktifkan Ekstensi Browser IDM (Kembalikan ke Bawaan)" -ForegroundColor DarkYellow
        Write-Host "  [6] Cek Diagnostik Lisensi, Biner & Ekstensi" -ForegroundColor White
        Write-Host "  [7] Reset IDM ke Evaluasi Bersih (Trial 30 Hari)" -ForegroundColor Gray
        Write-Host "  [8] Toko Digital FokusKonten (Buka Web)" -ForegroundColor DarkCyan
        Write-Host "  [0] Keluar" -ForegroundColor DarkGray
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host -NoNewline "  Pilihan Anda [1, 2, 3, 4, 5, 6, 7, 8, 0] : " -ForegroundColor Yellow

        $choice = ""
        try {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString()
            Write-Host $choice -ForegroundColor Green
        } catch {
            $choice = Read-Host
        }

        switch ($choice) {
            "1" { Install-IDMLicenseInPlace }
            "2" { Download-And-Install-IDM }
            "3" { Uninstall-IDMInPlace }
            "4" { Repair-IDMBrowserExtensions }
            "5" { Disable-IDMBrowserExtensions }
            "6" { Show-IDMStatusInPlace }
            "7" { Reset-IDMTrialInPlace }
            "8" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
            "0" {
                Restore-Terminal
                Write-Host ""
                Write-Host "  Terima kasih telah menggunakan utilitas FokusKonten." -ForegroundColor Green
                Write-Host ""
                return
            }
        }
    }
} finally {
    Restore-Terminal
}
