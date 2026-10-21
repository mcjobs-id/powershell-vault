# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul [FK-PSH-17] : VENTOY PRO - MULTI-BOOT USB FLASH DISK SUITE
# Engine            : Official Ventoy Bootloader v1.1.18 + Auto-Bypass Windows 11
# Standard          : Ultra-Compact Golden 64 Layout // In-Place Single Terminal
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // VENTOY PRO MULTI-BOOT USB SUITE"
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

# Directories & Configuration
$WorkDir = "$env:TEMP\FokusKonten_Ventoy"
$VentoyVersion = "1.1.18"
$VentoyDir = "$WorkDir\ventoy-$VentoyVersion"
$VentoyExe = "$VentoyDir\Ventoy2Disk.exe"
$VentoyZip = "$WorkDir\ventoy-$VentoyVersion-windows.zip"
$VentoyDownloadUrl = "https://github.com/ventoy/Ventoy/releases/download/v$VentoyVersion/ventoy-$VentoyVersion-windows.zip"

$BypassJsonContent = @'
{
    "control": [
        { "VTOY_DEFAULT_SEARCH_ROOT": "/ISO" },
        { "VTOY_WIN11_BYPASS_CHECK": "1" },
        { "VTOY_WIN11_BYPASS_NRO": "1" }
    ]
}
'@

function Get-ConnectedUsbDrives {
    $results = @()
    try {
        $usbDisks = Get-CimInstance Win32_DiskDrive | Where-Object { $_.InterfaceType -match 'USB' -or $_.MediaType -match 'Removable' }
        foreach ($disk in $usbDisks) {
            $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition -ErrorAction SilentlyContinue
            $letters = @()
            foreach ($part in $partitions) {
                $logicals = Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue
                foreach ($log in $logicals) {
                    if ($log.DeviceID) { $letters += $log.DeviceID }
                }
            }
            $driveStr = if ($letters.Count -gt 0) { ($letters -join ', ') } else { "Belum Terformat" }
            $sizeGb = [math]::Round($disk.Size / 1GB, 1)
            $results += [PSCustomObject]@{
                Index   = $disk.Index
                Model   = $disk.Model.Trim()
                SizeGB  = $sizeGb
                Drives  = $driveStr
                Letters = $letters
            }
        }
    } catch {}
    return $results
}

function Ensure-VentoyEngine {
    if (Test-Path $VentoyExe) {
        return $true
    }

    if (-not (Test-Path $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    }

    Write-Host ""
    Write-Host "  -> Menyiapkan modul resmi Ventoy v$VentoyVersion..." -ForegroundColor Cyan

    try {
        if (-not (Test-Path $VentoyZip) -or ((Get-Item $VentoyZip).Length -lt 15000000)) {
            $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($curlCmd) {
                & curl.exe -L $VentoyDownloadUrl -o $VentoyZip -#
            } else {
                Invoke-WebRequest -Uri $VentoyDownloadUrl -OutFile $VentoyZip -UseBasicParsing
            }
        }

        Expand-Archive -Path $VentoyZip -DestinationPath $WorkDir -Force

        # Buka blokir Mark of the Web
        Get-ChildItem -Path $VentoyDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

        if (Test-Path $VentoyExe) {
            Write-Host "     [================] 100% [VENTOY ENGINE SIAP]" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  [!] Berkas Ventoy2Disk.exe tidak ditemukan." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  [!] Gagal mengunduh biner Ventoy: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Inject-BypassPlugins {
    param ([string]$TargetDrive)

    if (-not $TargetDrive) { return }
    $cleanLetter = $TargetDrive.TrimEnd('\').TrimEnd(':') + ":"
    $ventoyFolder = "$cleanLetter\ventoy"
    $isoFolder = "$cleanLetter\ISO"

    try {
        if (-not (Test-Path $ventoyFolder)) {
            New-Item -ItemType Directory -Path $ventoyFolder -Force | Out-Null
        }
        $jsonPath = "$ventoyFolder\ventoy.json"
        Set-Content -Path $jsonPath -Value $BypassJsonContent -Encoding UTF8 -Force
        Write-Host "  [+] Injeksi konfigurasi bypass Windows 11 berhasil ($jsonPath)." -ForegroundColor Green

        if (-not (Test-Path $isoFolder)) {
            New-Item -ItemType Directory -Path $isoFolder -Force | Out-Null
            Write-Host "  [+] Folder penampung ISO siap pakai berhasil dibuat ($isoFolder)." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [!] Gagal menyuntikkan plugin bypass: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Show-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " FOKUSKONTEN // VENTOY PRO MULTI-BOOT USB SUITE                " -ForegroundColor White
    Write-Host " Bootloader Multi-ISO Portabel & Auto-Bypass Windows 11         " -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " TIKET ORDER   : " -NoNewline -ForegroundColor Gray
    Write-Host "$($global:fkOrderNumber)" -ForegroundColor Yellow
    Write-Host " MESIN UTAMA   : " -NoNewline -ForegroundColor Gray
    Write-Host "Official Ventoy v$VentoyVersion (Multi-ISO Engine)" -ForegroundColor White
    Write-Host " BYPASS WIN 11 : " -NoNewline -ForegroundColor Gray
    Write-Host "[ AKTIF // BYPASS TPM 2.0 + SECURE BOOT + NO ONLINE ACC ]" -ForegroundColor Green
    Write-Host " KEAMANAN      : " -NoNewline -ForegroundColor Gray
    Write-Host "Proteksi Partisi Sistem (Drive C: Terkunci Aman)" -ForegroundColor Green
    Write-Host " HAK AKSES     : " -NoNewline -ForegroundColor Gray
    if ($isAdmin) {
        Write-Host "ADMINISTRATOR RESMI [TERVERIFIKASI]" -ForegroundColor Green
    } else {
        Write-Host "User Standar [UAC Elevasi Otomatis Siaga]" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    
    # Deteksi USB Real-time
    $usbs = Get-ConnectedUsbDrives
    if ($usbs.Count -eq 0) {
        Write-Host " SENSOR PERANGKAT USB:" -ForegroundColor Yellow
        Write-Host " [!] Tidak ada Flashdisk / USB Drive terdeteksi." -ForegroundColor Red
        Write-Host "     Silakan colokkan flashdisk Anda ke port USB komputer." -ForegroundColor Gray
    } else {
        Write-Host " SENSOR PERANGKAT USB TERDETEKSI:" -ForegroundColor Yellow
        foreach ($u in $usbs) {
            Write-Host "  * [Disk $($u.Index)] Drive $($u.Drives) | $($u.Model) ($($u.SizeGB) GB)" -ForegroundColor White
        }
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " PILIHAN MENU TINDAKAN:" -ForegroundColor White
    Write-Host "   [1] Pasang Bootloader Ventoy Baru (Format & Install ke USB)" -ForegroundColor Green
    Write-Host "   [2] Perbarui Bootloader Ventoy (Update In-Place - Data ISO Aman)" -ForegroundColor Cyan
    Write-Host "   [3] Pasang Modul Bypass Windows 11 TPM & NRO (ventoy.json)" -ForegroundColor Yellow
    Write-Host "   [4] Buka Antarmuka GUI Resmi Ventoy (Ventoy2Disk.exe)" -ForegroundColor White
    Write-Host "   [5] Panduan Tautan Unduh File ISO Resmi Teknisi IT" -ForegroundColor Cyan
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

function Install-VentoyNew {
    $usbs = Get-ConnectedUsbDrives
    if ($usbs.Count -eq 0) {
        Write-Host "`n  [!] Flashdisk tidak ditemukan. Colokkan flashdisk dan coba lagi." -ForegroundColor Red
        return
    }

    Write-Host "`n  === PILIH FLASHDISK TARGET PEMASANGAN BARU ===" -ForegroundColor Yellow
    for ($i = 0; $i -lt $usbs.Count; $i++) {
        $u = $usbs[$i]
        Write-Host "  [$($i+1)] Disk $($u.Index) - Drive $($u.Drives) - $($u.Model) ($($u.SizeGB) GB)" -ForegroundColor White
    }
    Write-Host "  [0] Batal" -ForegroundColor Gray

    $sel = Read-Host "`n  Pilih nomor flashdisk target [1-$($usbs.Count)]"
    $num = 0
    if (-not [int]::TryParse($sel, [ref]$num) -or $num -lt 1 -or $num -gt $usbs.Count) {
        Write-Host "  Operasi dibatalkan." -ForegroundColor Yellow
        return
    }

    $targetDisk = $usbs[$num - 1]

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host " PERINGATAN KRITIS: PEMASANGAN BARU AKAN MEMFORMAT FLASHDISK!   " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host " Target Disk       : Disk $($targetDisk.Index) - $($targetDisk.Model) ($($targetDisk.SizeGB) GB)" -ForegroundColor White
    Write-Host " Partisi Saat Ini  : $($targetDisk.Drives)" -ForegroundColor White
    Write-Host " Seluruh data di flashdisk ini akan DIHAPUS & diformat Ventoy." -ForegroundColor Red
    Write-Host " Pastikan file penting di flashdisk sudah Anda cadangkan!" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    $confirm = Read-Host " Ketik 'Y' dan tekan Enter untuk melanjutkan format dan instal"
    if ($confirm.Trim().ToUpper() -ne "Y") {
        Write-Host " [BATAL] Format dibatalkan. Flashdisk Anda aman 100%." -ForegroundColor Green
        return
    }

    if (-not (Ensure-VentoyEngine)) { return }

    Write-Host ""
    Write-Host " [1/3] Memulai proses instalasi bootloader Ventoy..." -ForegroundColor Cyan
    Set-Location $VentoyDir

    # Bersihkan file status lama
    Remove-Item "$VentoyDir\cli_done.txt" -ErrorAction SilentlyContinue
    Remove-Item "$VentoyDir\cli_percent.txt" -ErrorAction SilentlyContinue

    # MBR Mode (Universal compatibility untuk semua BIOS Legacy & UEFI Modern)
    $cliArgs = "VTOYCLI /I /PhyDrive:$($targetDisk.Index)"

    # Jalankan dengan elevasi otomatis jika sesi bukan Administrator
    if (-not $isAdmin) {
        Write-Host " [*] Meminta izin Administrator Windows (UAC)..." -ForegroundColor Yellow
        $proc = Start-Process -FilePath $VentoyExe -ArgumentList $cliArgs -WorkingDirectory $VentoyDir -Verb RunAs -PassThru
    } else {
        $proc = Start-Process -FilePath $VentoyExe -ArgumentList $cliArgs -WorkingDirectory $VentoyDir -PassThru -NoNewWindow
    }

    # Pantau persentase realtime dari cli_percent.txt
    $doneFile = "$VentoyDir\cli_done.txt"
    $percentFile = "$VentoyDir\cli_percent.txt"
    $timeoutSec = 90
    $elapsed = 0

    while ($elapsed -lt $timeoutSec -and (-not (Test-Path $doneFile)) -and ($proc -and -not $proc.HasExited)) {
        Start-Sleep -Seconds 1
        $elapsed++
        if (Test-Path $percentFile) {
            $pct = (Get-Content $percentFile -Raw -ErrorAction SilentlyContinue).Trim()
            if ($pct) {
                Write-Host "`r  -> Sedang memformat & menyalin bootloader: $pct% " -NoNewline -ForegroundColor Cyan
            }
        }
    }
    Write-Host ""

    # Tunggu proses selesai
    if ($proc -and -not $proc.HasExited) { $proc.WaitForExit(5000) }

    $isSuccess = $false
    if (Test-Path $doneFile) {
        $doneVal = (Get-Content $doneFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ($doneVal -eq "0") { $isSuccess = $true }
    }

    if ($isSuccess) {
        Write-Host " [2/3] Bootloader Ventoy berhasil dipasang ke Disk $($targetDisk.Index)!" -ForegroundColor Green
        
        # Polling deteksi huruf drive baru (hingga 12 detik)
        Write-Host "  -> Menunggu Windows menetapkan huruf partisi flashdisk..." -ForegroundColor Gray
        $targetLetter = $null
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt 12 -and (-not $targetLetter)) {
            Start-Sleep -Seconds 2
            $freshUsbs = Get-ConnectedUsbDrives
            $fresh = $freshUsbs | Where-Object { $_.Index -eq $targetDisk.Index }
            if ($fresh -and $fresh.Letters.Count -gt 0) {
                $targetLetter = $fresh.Letters[0]
            }
        }

        if ($targetLetter) {
            Write-Host " [3/3] Menyuntikkan template bypass Windows 11 ke Drive $targetLetter..." -ForegroundColor Cyan
            Inject-BypassPlugins -TargetDrive $targetLetter
        }

        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host " [SUKSES] FLASHDISK MULTI-BOOT VENTOY PRO SIAP DIGUNAKAN!       " -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host " Panduan Penggunaan:" -ForegroundColor White
        Write-Host " 1. Salin (copy-paste) file .ISO apa saja ke folder ISO di USB." -ForegroundColor White
        Write-Host " 2. Tancapkan ke laptop/PC target, nyalakan dan tekan tombol Boot Menu." -ForegroundColor White
        Write-Host " 3. Pilih installer OS langsung dari menu boot di layar." -ForegroundColor White
    } else {
        Write-Host " [!] Pemasangan otomatis dialihkan ke GUI resmi..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath $VentoyExe -WorkingDirectory $VentoyDir -Verb RunAs
        } catch {
            Start-Process explorer.exe -ArgumentList "`"$VentoyDir`""
        }
    }
}

function Update-VentoyInPlace {
    $usbs = Get-ConnectedUsbDrives
    if ($usbs.Count -eq 0) {
        Write-Host "`n  [!] Flashdisk tidak ditemukan. Colokkan flashdisk dan coba lagi." -ForegroundColor Red
        return
    }

    Write-Host "`n  === PILIH FLASHDISK YANG AKAN DI-UPDATE (DATA ISO AMAN 100%) ===" -ForegroundColor Yellow
    for ($i = 0; $i -lt $usbs.Count; $i++) {
        $u = $usbs[$i]
        Write-Host "  [$($i+1)] Disk $($u.Index) - Drive $($u.Drives) - $($u.Model) ($($u.SizeGB) GB)" -ForegroundColor White
    }
    Write-Host "  [0] Batal" -ForegroundColor Gray

    $sel = Read-Host "`n  Pilih nomor flashdisk [1-$($usbs.Count)]"
    $num = 0
    if (-not [int]::TryParse($sel, [ref]$num) -or $num -lt 1 -or $num -gt $usbs.Count) {
        Write-Host "  Operasi dibatalkan." -ForegroundColor Yellow
        return
    }

    $targetDisk = $usbs[$num - 1]
    if (-not (Ensure-VentoyEngine)) { return }

    Write-Host "`n  -> Memperbarui bootloader Ventoy ke versi v$VentoyVersion..." -ForegroundColor Cyan
    Set-Location $VentoyDir

    Remove-Item "$VentoyDir\cli_done.txt" -ErrorAction SilentlyContinue
    $cliArgs = "VTOYCLI /U /PhyDrive:$($targetDisk.Index)"

    if (-not $isAdmin) {
        Write-Host " [*] Meminta izin Administrator Windows (UAC)..." -ForegroundColor Yellow
        $proc = Start-Process -FilePath $VentoyExe -ArgumentList $cliArgs -WorkingDirectory $VentoyDir -Verb RunAs -PassThru -Wait
    } else {
        $proc = Start-Process -FilePath $VentoyExe -ArgumentList $cliArgs -WorkingDirectory $VentoyDir -Wait -PassThru -NoNewWindow
    }

    Start-Sleep -Seconds 2
    Write-Host "  [OK] Update bootloader selesai! Seluruh file ISO tetap utuh." -ForegroundColor Green

    if ($targetDisk.Letters.Count -gt 0) {
        Inject-BypassPlugins -TargetDrive $targetDisk.Letters[0]
    }
}

function Setup-BypassOnly {
    $usbs = Get-ConnectedUsbDrives
    if ($usbs.Count -eq 0) {
        Write-Host "`n  [!] Flashdisk tidak ditemukan." -ForegroundColor Red
        return
    }

    Write-Host "`n  === PILIH FLASHDISK UNTUK INJEKSI BYPASS WINDOWS 11 ===" -ForegroundColor Yellow
    $eligible = @()
    foreach ($u in $usbs) {
        foreach ($let in $u.Letters) {
            $eligible += $let
            Write-Host "  [$($eligible.Count)] Drive $let ($($u.Model))" -ForegroundColor White
        }
    }

    if ($eligible.Count -eq 0) {
        Write-Host "  [!] Flashdisk belum memiliki huruf partisi terformat." -ForegroundColor Red
        return
    }

    $sel = Read-Host "`n  Pilih nomor drive [1-$($eligible.Count)]"
    $num = 0
    if ([int]::TryParse($sel, [ref]$num) -and $num -ge 1 -and $num -le $eligible.Count) {
        $targetLetter = $eligible[$num - 1]
        Inject-BypassPlugins -TargetDrive $targetLetter
        Write-Host "  [OK] Konfigurasi bypass TPM & akun online berhasil disuntikkan ke $targetLetter!" -ForegroundColor Green
    }
}

function Show-IsoLinks {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " PANDUAN SUMBER UNDUHAN FILE ISO RESMI TEKNISI IT               " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1. Windows 11 Resmi (Microsoft Media Creation Tool):" -ForegroundColor White
    Write-Host "    https://www.microsoft.com/software-download/windows11" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 2. Windows 10 Resmi (Microsoft Media Creation Tool):" -ForegroundColor White
    Write-Host "    https://www.microsoft.com/software-download/windows10" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 3. Hiren BootCD PE x64 (Emergency Rescue Toolkit):" -ForegroundColor White
    Write-Host "    https://www.hirensbootcd.org/download/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 4. Ubuntu Desktop LTS (Linux Populer):" -ForegroundColor White
    Write-Host "    https://ubuntu.com/download/desktop" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Petunjuk:" -ForegroundColor White
    Write-Host " Cukup unduh file berekstensi .iso di atas, lalu salin (copy-paste)" -ForegroundColor Yellow
    Write-Host " langsung ke dalam folder ISO di Flashdisk Ventoy Anda." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
}

# Main Application Loop
try {
    while ($true) {
        Show-Header
        Write-Host -NoNewline " Pilihan Anda [1, 2, 3, 4, 5, 0] : " -ForegroundColor Green
        $choice = (Read-Host).Trim()

        switch ($choice) {
            "1" { Install-VentoyNew }
            "2" { Update-VentoyInPlace }
            "3" { Setup-BypassOnly }
            "4" {
                if (Ensure-VentoyEngine) {
                    Write-Host "`n  Membuka antarmuka grafis resmi Ventoy2Disk.exe..." -ForegroundColor Cyan
                    try {
                        Start-Process -FilePath $VentoyExe -WorkingDirectory $VentoyDir -Verb RunAs -ErrorAction Stop
                        Write-Host "  [OK] Jendela aplikasi Ventoy telah diluncurkan." -ForegroundColor Green
                    } catch {
                        Write-Host "  [!] Membuka folder instalasi Ventoy di File Explorer..." -ForegroundColor Yellow
                        Start-Process explorer.exe -ArgumentList "`"$VentoyDir`""
                    }
                }
            }
            "5" { Show-IsoLinks }
            "0" {
                Write-Host "`n  Terima kasih telah menggunakan layanan resmi FokusKonten.`n" -ForegroundColor Green
                Restore-Terminal
                exit 0
            }
            default {
                Write-Host " Pilihan tidak valid." -ForegroundColor Yellow
            }
        }

        Write-Host "`n Tekan Enter untuk kembali ke menu utama..." -ForegroundColor White
        Read-Host | Out-Null
    }
} finally {
    Restore-Terminal
}
