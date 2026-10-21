# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SUPER ADMIN UNLOCKER // ELEVASI MUTLAK TRUSTEDINSTALLER
# Modul SKU    : FK-PSH-19 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% Otomatisasi Eksekusi Tanpa Panduan Manual
# Mesin Inti   : RunAsTI Dual-Engine 64-bit & 32-bit (Joakim Schicht)
# ==============================================================================

param (
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

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // SUPER ADMIN UNLOCKER"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        try { [Console]::CursorVisible = $true } catch {}
    } catch {}
}

$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

# Direktori Kerja Resmi
$WorkDir = "$env:ProgramData\FokusKonten\RunAsTI"
$is64Bit = [Environment]::Is64BitOperatingSystem
$ExeName = if ($is64Bit) { "RunAsTI64.exe" } else { "RunAsTI32.exe" }
$ExePath = Join-Path $WorkDir $ExeName

# Sumber Biner Resmi
$VaultCdnUrl   = "https://github.com/mcjobs-id/powershell-vault/releases/download/v1.0.0/fk_runasti_engine.zip"
$VaultRawUrl   = "https://raw.githubusercontent.com/mcjobs-id/powershell-vault/main/23_RunAsTI_TrustedInstaller_Privilege/$ExeName"
$LocalProxyUrl = "http://127.0.0.1:8090/dl/runasti-engine"

function Ensure-RunAsTIPackage {
    if (-not (Test-Path -LiteralPath $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    }

    if ($PSScriptRoot) {
        $localExe = Join-Path $PSScriptRoot $ExeName
        if ((Test-Path -LiteralPath $localExe) -and ((Get-Item -LiteralPath $localExe).Length -gt 2000000)) {
            Copy-Item -LiteralPath $localExe -Destination $ExePath -Force
            return $ExePath
        }
    }

    if ((Test-Path -LiteralPath $ExePath) -and ((Get-Item -LiteralPath $ExePath).Length -gt 2000000)) {
        return $ExePath
    }

    Write-Host "  > Menyiapkan modul biner resmi..." -ForegroundColor Cyan -NoNewline
    $zipPath = Join-Path $WorkDir "fk_runasti_engine.zip"
    $downloadSuccess = $false

    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($VaultCdnUrl, $zipPath)
        if ((Test-Path -LiteralPath $zipPath) -and ((Get-Item -LiteralPath $zipPath).Length -gt 1000000)) {
            $downloadSuccess = $true
        }
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($LocalProxyUrl, $zipPath)
            if ((Test-Path -LiteralPath $zipPath) -and ((Get-Item -LiteralPath $zipPath).Length -gt 1000000)) {
                $downloadSuccess = $true
            }
        } catch {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($VaultRawUrl, $ExePath)
                if ((Test-Path -LiteralPath $ExePath) -and ((Get-Item -LiteralPath $ExePath).Length -gt 2000000)) {
                    Write-Host " [OK]" -ForegroundColor Green
                    return $ExePath
                }
            } catch {}
        }
    }

    if ($downloadSuccess) {
        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $WorkDir -Force
            Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $ExePath) {
                Write-Host " [OK]" -ForegroundColor Green
                return $ExePath
            }
        } catch {}
    }

    Write-Host " [GAGAL]" -ForegroundColor Red
    return $null
}

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Super Admin Unlocker (Elevasi Mutlak TrustedInstaller)" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-19] Asistensi Resmi" -ForegroundColor DarkCyan
    if ($isAdmin) {
        Write-Host "  STATUS : [ ADMINISTRATOR RESMI TERVERIFIKASI ]" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ MODE STANDAR - BUTUH HAK ADMINISTRATOR ]" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN TINDAKAN OTOMATIS:" -ForegroundColor White
    Write-Host "    [1] Buka Kunci Akses Berkas / Folder (Unlock Full Control)" -ForegroundColor Green
    Write-Host "    [2] Paksa Hapus Berkas / Folder Bandel (Force Delete 1-Klik)" -ForegroundColor Red
    Write-Host "    [3] Bersihkan Sampah Sistem Terkunci (Windows.old & Cache)" -ForegroundColor Yellow
    Write-Host "    [4] Mode Terminal Super Admin (Khusus Kebutuhan Teknis)" -ForegroundColor Cyan
    Write-Host "    [0] Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Invoke-UnlockPermission {
    Write-Host ""
    Write-Host "  [PROSES] Buka Kunci Hak Akses Penuh (Unlock Full Control)" -ForegroundColor Cyan
    Write-Host "  --------------------------------------------------------------" -ForegroundColor DarkGray
    
    $bin = Ensure-RunAsTIPackage
    if (-not $bin) { return }

    $target = Read-Host "  Masukkan / Tarik (Drag & Drop) folder/berkas"
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    $target = $target.Trim("`"' ")

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Host "  [!] Berkas atau folder tidak ditemukan di disk." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    Write-Host "  > Mengambil alih kepemilikan mutlak..." -ForegroundColor Cyan -NoNewline
    $actionCmd = Join-Path $WorkDir "unlock.cmd"
    $escaped = $target.Replace('"', '\"')

    $cmd = @"
@echo off
takeown /f "$escaped" /r /d y >nul 2>&1
icacls "$escaped" /grant:r administrators:F /t /c /q >nul 2>&1
icacls "$escaped" /grant:r "%USERNAME%":F /t /c /q >nul 2>&1
exit
"@
    [System.IO.File]::WriteAllText($actionCmd, $cmd, [System.Text.Encoding]::ASCII)
    & $bin "$actionCmd"
    Write-Host " [OK]" -ForegroundColor Green

    Write-Host ""
    Write-Host "  [BERHASIL] Hak akses folder/berkas telah dibuka 100%!" -ForegroundColor Green
    Write-Host "  Anda sekarang bebas membuka, memodifikasi, atau menghapusnya." -ForegroundColor White
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
}

function Invoke-ForceDelete {
    Write-Host ""
    Write-Host "  [PROSES] Paksa Hapus Berkas / Folder Bandel (Force Delete)" -ForegroundColor Red
    Write-Host "  --------------------------------------------------------------" -ForegroundColor DarkGray
    
    $bin = Ensure-RunAsTIPackage
    if (-not $bin) { return }

    $target = Read-Host "  Masukkan / Tarik (Drag & Drop) folder/berkas yang ingin dihapus"
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    $target = $target.Trim("`"' ")

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Host "  [!] Berkas atau folder tidak ditemukan di disk." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $c = Read-Host "  Yakin hapus permanen target ini? [Y/N]"
    if ($c.Trim().ToUpper() -ne "Y") { return }

    Write-Host "  > Menghapus berkas via hak mutlak TrustedInstaller..." -ForegroundColor Yellow -NoNewline
    $actionCmd = Join-Path $WorkDir "delete.cmd"
    $escaped = $target.Replace('"', '\"')

    $cmd = @"
@echo off
takeown /f "$escaped" /r /d y >nul 2>&1
icacls "$escaped" /grant:r administrators:F /t /c /q >nul 2>&1
if exist "$escaped\*" (
    rd /s /q "$escaped" >nul 2>&1
) else (
    del /f /q /a "$escaped" >nul 2>&1
)
exit
"@
    [System.IO.File]::WriteAllText($actionCmd, $cmd, [System.Text.Encoding]::ASCII)
    & $bin "$actionCmd"
    Start-Sleep -Milliseconds 800

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [BERHASIL] Berkas/folder berhasil dimusnahkan bersih dari disk!" -ForegroundColor Green
    } else {
        Write-Host " [TERTAHAN]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [!] Sebagian file masih terkunci proses aktif di latar belakang." -ForegroundColor Yellow
        Write-Host "      Silakan restart komputer untuk merampungkan penghapusan." -ForegroundColor Gray
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
}

function Invoke-AutoCleanSystemJunk {
    Write-Host ""
    Write-Host "  [PROSES] Pembersihan Sampah Sistem Terkunci Otomatis" -ForegroundColor Yellow
    Write-Host "  --------------------------------------------------------------" -ForegroundColor DarkGray

    $bin = Ensure-RunAsTIPackage
    if (-not $bin) { return }

    $junkPaths = @(
        "$env:SystemDrive\Windows.old",
        "$env:SystemRoot\SoftwareDistribution\Download",
        "$env:SystemRoot\Temp",
        "$env:LOCALAPPDATA\Temp"
    )

    $foundAny = $false
    foreach ($jp in $junkPaths) {
        if (Test-Path -LiteralPath $jp) {
            $foundAny = $true
            Write-Host "  > Menghapus sampah: $jp..." -ForegroundColor Cyan -NoNewline
            
            $actionCmd = Join-Path $WorkDir "clean_single.cmd"
            $escaped = $jp.Replace('"', '\"')
            $cmd = @"
@echo off
takeown /f "$escaped" /r /d y >nul 2>&1
icacls "$escaped" /grant:r administrators:F /t /c /q >nul 2>&1
if "$escaped" == "$env:SystemDrive\Windows.old" (
    rd /s /q "$escaped" >nul 2>&1
) else (
    del /f /q /s /a "$escaped\*" >nul 2>&1
)
exit
"@
            [System.IO.File]::WriteAllText($actionCmd, $cmd, [System.Text.Encoding]::ASCII)
            & $bin "$actionCmd"
            Start-Sleep -Milliseconds 500
            Write-Host " [BERSIH]" -ForegroundColor Green
        }
    }

    if (-not $foundAny) {
        Write-Host "  [i] Sistem Anda sudah bersih dari berkas sampah terkunci." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  [BERHASIL] Seluruh sampah sistem terkunci telah dibersihkan!" -ForegroundColor Green
        Write-Host "  Ruang penyimpanan harddisk Anda kini kembali lega." -ForegroundColor White
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
}

function Invoke-SuperAdminShell {
    Write-Host ""
    Write-Host "  > Meluncurkan Terminal dengan Hak Akses Mutlak TrustedInstaller..." -ForegroundColor Cyan -NoNewline
    $bin = Ensure-RunAsTIPackage
    if (-not $bin) { return }

    try {
        & $bin
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [GAGAL]" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

# Loop Antarmuka Utama
while ($true) {
    Show-Header
    Write-Host "  Pilihan Anda [1/2/3/4/0] : " -NoNewline -ForegroundColor Green
    
    $choice = ""
    try {
        $key = [Console]::ReadKey($true)
        $choice = $key.KeyChar.ToString()
        Write-Host $choice -ForegroundColor Green
    } catch {
        $choice = Read-Host
    }

    switch ($choice) {
        "1" { Invoke-UnlockPermission }
        "2" { Invoke-ForceDelete }
        "3" { Invoke-AutoCleanSystemJunk }
        "4" { Invoke-SuperAdminShell }
        "0" {
            Restore-Terminal
            Write-Host ""
            Write-Host "  Terima kasih telah mempercayakan utilitas sistem kepada FokusKonten." -ForegroundColor Green
            Write-Host ""
            exit 0
        }
        default {
            Start-Sleep -Milliseconds 500
        }
    }
}
Restore-Terminal
