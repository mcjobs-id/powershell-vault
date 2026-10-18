# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 19: IDM HELPER - Internet Download Manager
# Metode    : CLSID Registry Permission Lock & Anti-Fake Serial (100% Native PS)
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
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Cyan
    Write-Host "  Modul 19 : IDM HELPER - Internet Download Manager" -ForegroundColor Yellow
    Write-Host "  Metode   : CLSID Registry Permission Lock (Anti-Fake Serial)" -ForegroundColor White
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  -> Menyiapkan engine lisensi IDM lokal..." -ForegroundColor Cyan

    # --- Bangun script PS1 elevated sebagai inline string ---
    $idmPs1 = @'
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "FokusKonten // IDM HELPER - Internet Download Manager"
try { $Host.UI.RawUI.BackgroundColor = 'DarkCyan'; $Host.UI.RawUI.ForegroundColor = 'White'; Clear-Host } catch {}

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

function Install-IDMLicense {
    cls
    Write-Host ""
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host "  SEDANG MEMASANG LISENSI INTERNET DOWNLOAD MANAGER (IDM)..." -ForegroundColor Yellow
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host ""

    $idmPath = Find-IDMPath
    if (-not $idmPath) {
        Write-Host "  [!] PEMBERITAHUAN: IDM belum terpasang di sistem ini." -ForegroundColor Yellow
        Write-Host "      Silakan instal IDM terlebih dahulu, lalu jalankan menu ini kembali." -ForegroundColor White
        Write-Host "      Membuka halaman unduh resmi IDM..." -ForegroundColor Cyan
        Start-Process "https://www.internetdownloadmanager.com/download.html"
        pause
        return
    }

    # Hentikan proses IDM aktif
    $proc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  -> Menghentikan proses IDM aktif..." -ForegroundColor Cyan
        Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    # Ambil kunci CLSID
    Write-Host "  -> Memindai entri registri evaluasi IDM..." -ForegroundColor Cyan
    $clsidData  = Get-CLSIDList
    $clsidKeys  = $clsidData[0]
    $regPaths   = $clsidData[1]

    # Bersihkan kunci trial lama
    Write-Host "  -> Membersihkan token evaluasi lama..." -ForegroundColor Cyan
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

    # Daftarkan lisensi registri
    Write-Host "  -> Mendaftarkan lisensi resmi FokusKonten..." -ForegroundColor Cyan
    $fname  = "FokusKonten"
    $lname  = "Customer"
    $email  = "lisensi@fokuskonten.my.id"
    $rawKey = -join ((Get-Random -Count 20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))))
    $serial = ($rawKey.Substring(0, 5) + '-' + $rawKey.Substring(5, 5) + '-' + $rawKey.Substring(10, 5) + '-' + $rawKey.Substring(15, 5) + $rawKey.Substring(20))

    $dmPath = "HKCU:\Software\DownloadManager"
    if (-not (Test-Path $dmPath)) { New-Item -Path $dmPath -Force | Out-Null }

    Set-ItemProperty -Path $dmPath -Name "FName"  -Value $fname  -Type String -Force
    Set-ItemProperty -Path $dmPath -Name "LName"  -Value $lname  -Type String -Force
    Set-ItemProperty -Path $dmPath -Name "Email"  -Value $email  -Type String -Force
    Set-ItemProperty -Path $dmPath -Name "Serial" -Value $serial -Type String -Force

    # Kunci CLSID untuk menolak notifikasi 'Fake Serial'
    Write-Host "  -> Mengunci entri registri (Perlindungan Anti-Fake Serial)..." -ForegroundColor Cyan
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

    # Buka kembali IDM
    if (Test-Path $idmPath) {
        Start-Process $idmPath
    }

    Write-Host ""
    Write-Host "  [OK] LISENSI IDM BERHASIL DIPASANG!" -ForegroundColor Green
    Write-Host "  * Terdaftar : $fname $lname ($email)" -ForegroundColor White
    Write-Host "  * Serial    : $serial" -ForegroundColor White
    Write-Host "  * Proteksi  : CLSID Terkunci (Bebas Popup Fake Serial & Bebas Antivirus)" -ForegroundColor Yellow
    Write-Host ""
    pause
}

function Show-IDMStatus {
    cls
    Write-Host ""
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTIK LISENSI INTERNET DOWNLOAD MANAGER (IDM)" -ForegroundColor Cyan
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host ""

    $idmPath = Find-IDMPath
    if ($idmPath) {
        $ver = (Get-Item $idmPath).VersionInfo.ProductVersion
        Write-Host "  * Lokasi IDM     : $idmPath" -ForegroundColor Green
        Write-Host "  * Versi Biner    : $ver" -ForegroundColor Green
    } else {
        Write-Host "  * Lokasi IDM     : BELUM TERINSTAL" -ForegroundColor Yellow
    }

    $dmPath = "HKCU:\Software\DownloadManager"
    if (Test-Path $dmPath) {
        $fn = (Get-ItemProperty -Path $dmPath -Name "FName"  -ErrorAction SilentlyContinue).FName
        $ln = (Get-ItemProperty -Path $dmPath -Name "LName"  -ErrorAction SilentlyContinue).LName
        $em = (Get-ItemProperty -Path $dmPath -Name "Email"  -ErrorAction SilentlyContinue).Email
        $sn = (Get-ItemProperty -Path $dmPath -Name "Serial" -ErrorAction SilentlyContinue).Serial

        Write-Host "  * Nama Pemilik   : $(if($fn){"$fn $ln"}else{"(Belum terdaftar)"})" -ForegroundColor Cyan
        Write-Host "  * Email Lisensi  : $(if($em){$em}else{"(Belum terdaftar)"})" -ForegroundColor Cyan
        Write-Host "  * Serial Key     : $(if($sn){$sn}else{"(Belum terdaftar)"})" -ForegroundColor $(if($sn){"Green"}else{"Yellow"})
    } else {
        Write-Host "  * Status Registri: Belum ada konfigurasi IDM di HKCU." -ForegroundColor Yellow
    }

    Write-Host ""
    pause
}

function Reset-IDMTrial {
    cls
    Write-Host ""
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Yellow
    Write-Host "  RESET LISENSI IDM KE TRIAL DEFAULT (EVALUASI 30 HARI)" -ForegroundColor Yellow
    Write-Host "  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Yellow
    Write-Host ""

    # Hentikan proses IDM aktif
    $proc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  -> Menghentikan proses IDM aktif..." -ForegroundColor Cyan
        Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $clsidData = Get-CLSIDList
    $clsidKeys = $clsidData[0]
    $regPaths  = $clsidData[1]

    Write-Host "  -> Membuka kunci proteksi registri CLSID..." -ForegroundColor Cyan
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

    Remove-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "FName","LName","Email","Serial" -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  [OK] REGISTRI EVALUASI IDM BERHASIL DI-RESET KE KONDISI AWAL!" -ForegroundColor Green
    Write-Host ""
    pause
}

# Main menu loop
while ($true) {
    cls
    Write-Host ""
    Write-Host "  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host "  ++  FOKUSKONTEN  //  IDM HELPER                                ++" -ForegroundColor Cyan
    Write-Host "  ++  Aktivasi & Pemulihan Lisensi Internet Download Manager     ++" -ForegroundColor Yellow
    Write-Host "  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Seluruh riwayat, pengaturan, dan antrean unduhan IDM Anda aman 100%." -ForegroundColor Yellow
    Write-Host "  Metode registri murni tanpa patch file exe/dll (aman dari false antivirus)." -ForegroundColor White
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  DETAIL LAYANAN DOWNLOAD MANAGER:" -ForegroundColor White
    Write-Host "  * Layanan  : IDM HELPER - INTERNET DOWNLOAD MANAGER" -ForegroundColor Cyan
    Write-Host "  * Metode   : CLSID Permission Lock & Registry Re-Arming (100% Native PS)" -ForegroundColor Green
    Write-Host "  * Komponen : IDMan.exe | DownloadManager Registry | CLSID Virtualization" -ForegroundColor White
    Write-Host "  * Fitur    : Kebal Popup 'Fake Serial' & Bebas Blokir Antivirus" -ForegroundColor Yellow
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  MENU TINDAKAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Pasang Lisensi IDM Permanen (Disarankan)" -ForegroundColor Yellow
    Write-Host "          Aktivasi otomatis & kunci registri agar bebas popup fake serial." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Cek Status Lisensi & Registrasi IDM" -ForegroundColor White
    Write-Host "          Memeriksa versi IDMan, nama terdaftar, email, dan serial key." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Reset IDM ke Trial Baru (Evaluasi 30 Hari)" -ForegroundColor White
    Write-Host "          Membersihkan serial key dan mengembalikan IDM ke evaluasi bersih." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Toko Digital FokusKonten - Software & Template Bisnis" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      [0] Keluar" -ForegroundColor DarkGray
    Write-Host "  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" -ForegroundColor Cyan
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
        "1" { Install-IDMLicense }
        "2" { Show-IDMStatus }
        "3" { Reset-IDMTrial }
        "4" { Start-Process "https://fokuskonten.my.id/toko-digital/" }
        "0" { exit 0 }
    }
}
'@

    # Simpan sebagai PS1 temp GUID
    $rand    = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

    # Jika terminal SUDAH Administrator, jalankan langsung in-place (CUKUP 1 TERMINAL)
    if ($isAdmin) {
        Write-Host "  [OK] Hak akses Administrator terverifikasi (Eksekusi 1 Terminal)." -ForegroundColor Green
        & ([scriptblock]::Create($idmPs1))
        return
    }

    # Jika BELUM Administrator, simpan ke temp dan luncurkan jendela elevated terpisah
    $ps1Path = "$env:USERPROFILE\AppData\Local\Temp\FK_IDM_$rand.ps1"
    [System.IO.File]::WriteAllText($ps1Path, $idmPs1, [System.Text.Encoding]::UTF8)

    if (-not (Test-Path $ps1Path)) {
        Write-Host "  [!] Gagal membuat berkas idm temp. Aborting." -ForegroundColor Red
        return
    }

    $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    Write-Host "  [OK] Engine lisensi IDM siap." -ForegroundColor Green
    Write-Host "  -> Membuka menu FokusKonten IDM Helper..." -ForegroundColor Cyan
    Write-Host "     Meminta izin Administrator sistem (UAC)..." -ForegroundColor Gray
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
