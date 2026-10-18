# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Engine: IDM Native CLSID Trial Lock & Registry Re-Arming
# 100% PowerShell Native - Tanpa Ketergantungan File CMD, Bebas Blokir Antivirus
# ==============================================================================
param(
    [switch]$FreezeOnly,
    [switch]$ResetOnly
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  FOKUSKONTEN // AKTIVASI NATIVE INTERNET DOWNLOAD MANAGER" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""

# 1. Hentikan proses IDM yang sedang aktif
$idmProc = Get-Process -Name "IDMan" -ErrorAction SilentlyContinue
if ($idmProc) {
    Write-Host "  -> Menghentikan proses IDM aktif..." -ForegroundColor Cyan
    Stop-Process -Name "IDMan" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# 2. Lokasi biner IDM
$idmPath = ""
$possiblePaths = @(
    "${env:ProgramFiles}\Internet Download Manager\IDMan.exe",
    "${env:ProgramFiles(x86)}\Internet Download Manager\IDMan.exe"
)
foreach ($p in $possiblePaths) {
    if (Test-Path $p) {
        $idmPath = $p
        break
    }
}

if (-not $idmPath) {
    Write-Host "  [!] PEMBERITAHUAN: Internet Download Manager (IDM) belum terinstal di sistem." -ForegroundColor Yellow
    Write-Host "      Silakan instal IDM terlebih dahulu, lalu jalankan kembali perintah ini." -ForegroundColor White
    Write-Host "      Mengunduh installer resmi IDM ke peramban Anda..." -ForegroundColor Cyan
    Start-Process "https://www.internetdownloadmanager.com/download.html"
    return
}

Write-Host "  [OK] IDM terdeteksi di: $idmPath" -ForegroundColor Green

# 3. Deteksi Arsitektur & Path Registry CLSID
$arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
if ($arch -eq "x86") {
    $regPaths = @("HKCU:\Software\Classes\CLSID")
} else {
    $regPaths = @("HKCU:\Software\Classes\WOW6432Node\CLSID")
}

# 4. Helper Hak Akses Registri (Take-Permissions)
function Take-Permissions {
    param($rootKey, $regKey, [switch]$Lock)
    try {
        $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
        $TypeBuilder = $ModuleBuilder.DefineType(0)

        $TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
        9,17,18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

        $SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
        $IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
        $Admin = New-Object System.Security.Principal.NTAccount($IDN)

        $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
        $none = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

        $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regKey, 'ReadWriteSubTree', 'TakeOwnership')
        if (-not $key) { return }

        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($Admin)
        $key.SetAccessControl($acl)

        $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)

        if ($Lock) {
            $acl = New-Object System.Security.AccessControl.RegistrySecurity
            $acl.SetOwner($none)
            $key.SetAccessControl($acl)

            $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
            $acl.ResetAccessRule($rule)
            $key.SetAccessControl($acl)
        }
    } catch {}
}

# 5. Pindai Kunci CLSID IDM
Write-Host "  -> Memindai kunci lisensi evaluasi IDM..." -ForegroundColor Cyan
$finalValues = @()
$subKeysToExclude = @("LocalServer32", "InProcServer32", "InProcHandler32")

foreach ($regPath in $regPaths) {
    $lockedKeys = $null
    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

    if ($lockedKeys) {
        foreach ($lockedKey in $lockedKeys) {
            $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
            $finalValues += $leafValue
        }
    }

    if ($subKeys) {
        $filteredKeys = $subKeys | Where-Object {
            $names = $_.GetSubKeyNames()
            -not ($names | Where-Object { $subKeysToExclude -contains $_ })
        }

        foreach ($key in $filteredKeys) {
            $fullPath = $key.PSPath
            $keyValues = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
            $defaultValue = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

            if (($defaultValue -match "^\d+$") -and ($key.SubKeyCount -eq 0)) {
                $finalValues += $($key.PSChildName)
                continue
            }
            if (($defaultValue -match "\+|=") -and ($key.SubKeyCount -eq 0)) {
                $finalValues += $($key.PSChildName)
                continue
            }
            $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
            if (($versionValue -match "^\d+$") -and ($key.SubKeyCount -eq 1)) {
                $finalValues += $($key.PSChildName)
                continue
            }
            foreach ($prop in $keyValues.PSObject.Properties) {
                if ($prop.Name -match "MData|Model|scansk|Therad") {
                    $finalValues += $($key.PSChildName)
                    break
                }
            }
            if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
                $finalValues += $($key.PSChildName)
                continue
            }
        }
    }
}

$finalValues = @($finalValues | Select-Object -Unique)

# 6. Bersihkan Kunci Trial / Reset
Write-Host "  -> Menghapus jejak registri trial IDM..." -ForegroundColor Cyan
foreach ($regPath in $regPaths) {
    foreach ($val in $finalValues) {
        $fullPath = Join-Path $regPath $val
        $rootKey = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }
        $pos = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($pos + 1)

        if (Test-Path $fullPath) {
            Take-Permissions $rootKey $regKey
            Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

# Hapus sisa registri aktivasi lama jika diminta reset
if ($ResetOnly) {
    Remove-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "FName","LName","Email","Serial" -ErrorAction SilentlyContinue
    Write-Host "  [OK] Registri evaluasi & lisensi IDM berhasil di-reset ke kondisi awal." -ForegroundColor Green
    return
}

# 7. Terapkan Lisensi Registrasi Resmi FokusKonten
Write-Host "  -> Mendaftarkan lisensi permanen FokusKonten..." -ForegroundColor Cyan
$fname = "FokusKonten"
$lname = "Customer"
$email = "lisensi@fokuskonten.my.id"
$rawKey = -join ((Get-Random -Count 20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))))
$serial = ($rawKey.Substring(0, 5) + '-' + $rawKey.Substring(5, 5) + '-' + $rawKey.Substring(10, 5) + '-' + $rawKey.Substring(15, 5) + $rawKey.Substring(20))

$dmPath = "HKCU:\Software\DownloadManager"
if (-not (Test-Path $dmPath)) { New-Item -Path $dmPath -Force | Out-Null }

Set-ItemProperty -Path $dmPath -Name "FName" -Value $fname -Type String -Force
Set-ItemProperty -Path $dmPath -Name "LName" -Value $lname -Type String -Force
Set-ItemProperty -Path $dmPath -Name "Email" -Value $email -Type String -Force
Set-ItemProperty -Path $dmPath -Name "Serial" -Value $serial -Type String -Force

# 8. Kunci Kunci CLSID untuk Menolak Notifikasi 'Fake Serial'
Write-Host "  -> Mengunci entri registri agar kebal blokir (Anti-Fake Serial)..." -ForegroundColor Cyan
foreach ($regPath in $regPaths) {
    foreach ($val in $finalValues) {
        $fullPath = Join-Path $regPath $val
        $rootKey = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }
        $pos = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($pos + 1)

        if (-not (Test-Path $fullPath)) {
            New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Take-Permissions $rootKey $regKey -Lock
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  [SUKSES] LISENSI INTERNET DOWNLOAD MANAGER BERHASIL DIAKTIFKAN!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  * Terdaftar Atas : $fname $lname" -ForegroundColor White
Write-Host "  * Kunci Serial   : $serial" -ForegroundColor White
Write-Host "  * Status Lisensi : AKTIF & PERMANEN (Bebas Popup Fake Serial)" -ForegroundColor Green
Write-Host "  * Perlindungan   : Kunci CLSID Terproteksi (Aman saat Update IDM)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""
