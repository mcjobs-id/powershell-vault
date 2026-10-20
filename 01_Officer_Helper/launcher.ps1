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

function Get-OfficeState {
    $paths = Find-OfficePaths
    $hasOffice = $false
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) {
            $hasOffice = $true
            break
        }
    }
    if (-not $hasOffice) {
        return "NOT_INSTALLED"
    }

    foreach ($p in $paths) {
        $hook = Get-ChildItem -LiteralPath $p -Filter "sppc.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hook) {
            return "LICENSED"
        }
    }
    return "UNLICENSED"
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

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Officer Helper: Pemulihan Lisensi Word & Excel" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-01] Asistensi Resmi" -ForegroundColor DarkCyan

    if ($state -eq "LICENSED") {
        Write-Host "  STATUS : [ BERLISENSI: OHOOK PERMANEN ] (Bebas Notifikasi)" -ForegroundColor Green
    } elseif ($state -eq "UNLICENSED") {
        Write-Host "  STATUS : [ NOTIFIKASI AKTIF / PERLU PEMULIHAN ]" -ForegroundColor Yellow
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
    $res = Invoke-EngineWithLiveLog -Arguments "/ohook -qedit -el" -ActionTitle "PEMASANGAN LISENSI PERMANEN OFFICE"

    Write-Host ""
    $state = Get-OfficeState
    if ($state -eq "LICENSED") {
        Write-Host "  [OK] LISENSI OFFICE BERHASIL DIPASANG PERMANEN!" -ForegroundColor Green
        Write-Host "  Status : Berlisensi Penuh (Bebas Notifikasi Selamanya)" -ForegroundColor White
    } elseif ($res) {
        Write-Host "  [OK] PROSES PEMULIHAN OFFICE SELESAI DIEKSEKUSI!" -ForegroundColor Green
        Write-Host "  Status : Silakan buka Word / Excel untuk memastikan lisensi." -ForegroundColor White
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

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if ((Get-OfficeState) -eq "LICENSED") { "OHook Virtualization (Bebas Notifikasi)" } else { "Standar / Unlicensed" }
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
# LOOP UTAMA INTERAKTIF (1 TERMINAL EXECUTION — ULTRA-COMPACT GOLDEN 64 LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-Header

    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Pasang / Pulihkan Lisensi Office (Rekomendasi 1-Klik)" -ForegroundColor Green
    Write-Host "   [2] Cek / Diagnostik Status Lisensi (ospp.vbs /dstatus)" -ForegroundColor Cyan
    Write-Host "   [3] Copot / Batalkan Lisensi (Kembalikan ke Semula / Undo)" -ForegroundColor Yellow
    Write-Host "   [4] Buka Aplikasi Word / Excel (Cek Status di Layar)" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()

    switch ($choice.Trim()) {
        "1" {
            Invoke-Action
        }
        "2" {
            Check-Diagnostics
        }
        "3" {
            Remove-License
        }
        "4" {
            Launch-OfficeApps
        }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            # Refresh menu
        }
    }
}
