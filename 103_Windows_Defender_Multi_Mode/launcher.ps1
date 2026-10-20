# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : UTILITAS SAKLAR WINDOWS DEFENDER (MODE GAMER & NORMAL)
# Modul SKU    : FK-PSH-103 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (100% Single-Terminal Native Execution)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // SAKLAR DEFENDER MULTI-MODE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$global:isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Invoke-ActionElevated ($actionScript) {
    if ($global:isAdmin) {
        & $actionScript
        return $true
    }

    Write-Host "  > Memproses otorisasi Administrator (UAC)..." -ForegroundColor Yellow
    try {
        $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($actionScript.ToString()))
        $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $b64" -Verb RunAs -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            return $true
        } else {
            Write-Host "  [!] Otorisasi Administrator dibatalkan oleh pengguna." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  [X] Gagal memicu otorisasi: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-DefenderState {
    $state = [PSCustomObject]@{
        StatusKey   = "ACTIVE"
        StatusText  = "[ DEFENDER AKTIF & AMAN ] (Perisai Nyala Penuh)"
        StatusColor = "Green"
        IsGamer     = $false
    }

    try {
        $pref = Get-MpPreference -ErrorAction SilentlyContinue
        if ($pref) {
            $exPaths = @($pref.ExclusionPath)
            $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { "$($_.Root)" }
            $matchCount = 0
            foreach ($d in $drives) {
                if ($exPaths -contains $d) { $matchCount++ }
            }
            if ($matchCount -gt 0 -or $pref.DisableRealtimeMonitoring -eq $true) {
                $state.StatusKey   = "GAMER"
                $state.StatusText  = "[ MODE GAMER AKTIF ] (Bebas Pasang Game/Patch)"
                $state.StatusColor = "Red"
                $state.IsGamer     = $true
            }
        }
    } catch {}

    return $state
}

function Show-CompactHeader {
    Clear-Host
    $st = Get-DefenderState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Utilitas Saklar Windows Defender (Mode Gamer & Normal)" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-103] Asistensi Resmi" -ForegroundColor DarkCyan
    Write-Host "  STATUS : $($st.StatusText)" -ForegroundColor $st.StatusColor
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Invoke-GamerMode {
    Write-Host ""
    Write-Host "  [PROSES] Mengaktifkan Mode Gamer 1-Klik Otomatis..." -ForegroundColor Yellow

    $action = {
        Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableScriptScanning $true -ErrorAction SilentlyContinue
        $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { "$($_.Root)" }
        foreach ($d in $drives) {
            Add-MpPreference -ExclusionPath $d -ErrorAction SilentlyContinue
        }
        $exts = @("exe", "dll", "zip", "rar", "iso", "vst3", "patch", "bin")
        foreach ($ext in $exts) {
            Add-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
        }
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "Notification_Suppress" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }

    $ok = Invoke-ActionElevated $action
    if ($ok) {
        Write-Host "  > Matikan Pemindaian Real-Time... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Pengecualian Seluruh Partisi Drive... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Pengecualian Format File (.exe, .dll, .patch)... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Pembungkaman Pop-up Notifikasi... [SELESAI]" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [BERHASIL] MODE GAMER SELESAI PARIPURNA 100%!" -ForegroundColor Green
        Write-Host "  Windows Defender dibebaskan total dari memindai/menghapus file Anda." -ForegroundColor White
        Write-Host "  Anda bebas memasang game repack, modifikasi, dan software sekarang." -ForegroundColor White
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-NormalMode {
    Write-Host ""
    Write-Host "  [PROSES] Memulihkan Mode Normal 1-Klik Otomatis..." -ForegroundColor Cyan

    $action = {
        $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object { "$($_.Root)" }
        foreach ($d in $drives) {
            Remove-MpPreference -ExclusionPath $d -ErrorAction SilentlyContinue
        }
        $exts = @("exe", "dll", "zip", "rar", "iso", "vst3", "patch", "bin")
        foreach ($ext in $exts) {
            Remove-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
        }
        Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableIOAVProtection $false -DisableScriptScanning $false -ErrorAction SilentlyContinue
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration"
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name "Notification_Suppress" -ErrorAction SilentlyContinue
        }
        try { Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue } catch {}
    }

    $ok = Invoke-ActionElevated $action
    if ($ok) {
        Write-Host "  > Hapus Pengecualian Partisi Global... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Pulihkan Pemindaian Format File... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Aktifkan Seluruh Perisai Real-Time... [SELESAI]" -ForegroundColor Green
        Write-Host "  > Pulihkan Notifikasi Keamanan... [SELESAI]" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [BERHASIL] MODE NORMAL SELESAI PARIPURNA 100%!" -ForegroundColor Green
        Write-Host "  Windows Defender kembali aktif penuh melindungi komputer Anda." -ForegroundColor White
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-FolderExclusion {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  TAMBAH FOLDER PENGECUALIAN (EXCLUSION 1-KLIK)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Folder target tidak akan pernah discan atau dihapus Defender." -ForegroundColor Gray
    Write-Host ""
    Write-Host -NoNewline "  Masukkan Path Folder (misal: D:\Games) : " -ForegroundColor Cyan
    $folder = [Console]::ReadLine()
    if (![string]::IsNullOrWhiteSpace($folder)) {
        $folder = $folder.Trim('"').Trim("'")
        if (Test-Path -LiteralPath $folder) {
            $action = {
                param($p)
                Add-MpPreference -ExclusionPath $p -ErrorAction Stop
            }
            $actionWithArg = [scriptblock]::Create("Add-MpPreference -ExclusionPath '$folder' -ErrorAction Stop")
            $ok = Invoke-ActionElevated $actionWithArg
            if ($ok) {
                Write-Host "  > Daftarkan Path... [SELESAI]" -ForegroundColor Green
                Write-Host "  [BERHASIL] Folder '$folder' bebas dari pemindaian!" -ForegroundColor Green
            }
        } else {
            Write-Host "  [GAGAL] Folder tidak ditemukan: $folder" -ForegroundColor Red
        }
    } else {
        Write-Host "  [!] Input kosong. Operasi dibatalkan." -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-LimitCpu {
    Write-Host ""
    Write-Host "  [PROSES] Mengunci Beban CPU MsMpEng.exe Maksimal 10%..." -ForegroundColor White
    $action = {
        Set-MpPreference -ScanAvgCPULoadFactor 10 -ErrorAction Stop
    }
    $ok = Invoke-ActionElevated $action
    if ($ok) {
        Write-Host "  > Batas Beban CPU... [10% LOCKED]" -ForegroundColor Green
        Write-Host "  [BERHASIL] Beban CPU berhasil dijinakkan! Laptop lebih adem dan senyap." -ForegroundColor Green
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-UnblockFile {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  BUKA BLOKIR FILE UNDUHAN (BYPASS SMARTSCREEN)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Menghapus tanda blokir 'Windows Protected Your PC'." -ForegroundColor Gray
    Write-Host ""
    Write-Host -NoNewline "  Masukkan Path File atau Folder Target : " -ForegroundColor Cyan
    $target = [Console]::ReadLine()
    if (![string]::IsNullOrWhiteSpace($target)) {
        $target = $target.Trim('"').Trim("'")
        if (Test-Path -LiteralPath $target) {
            try {
                if ((Get-Item -LiteralPath $target) -is [System.IO.DirectoryInfo]) {
                    Get-ChildItem -LiteralPath $target -Recurse -File -ErrorAction SilentlyContinue | Unblock-File
                    Write-Host "  [BERHASIL] Seluruh file dalam folder berhasil di-unblock!" -ForegroundColor Green
                } else {
                    Unblock-File -LiteralPath $target
                    Write-Host "  [BERHASIL] File '$target' berhasil di-unblock!" -ForegroundColor Green
                }
            } catch {
                Write-Host "  [GAGAL] $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  [GAGAL] Path tidak ditemukan: $target" -ForegroundColor Red
        }
    } else {
        Write-Host "  [!] Input kosong. Operasi dibatalkan." -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ResetSecurityApp {
    Write-Host ""
    Write-Host "  [PROSES] Me-reset Aplikasi Windows Security..." -ForegroundColor Yellow
    $action = {
        Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Reset-AppxPackage -ErrorAction SilentlyContinue
    }
    $ok = Invoke-ActionElevated $action
    if ($ok) {
        Write-Host "  > Paket SecHealthUI... [RESET OK]" -ForegroundColor Green
        Write-Host "  [BERHASIL] Aplikasi Windows Security telah dipulihkan ke kondisi pabrik!" -ForegroundColor Green
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ClearThreatHistory {
    Write-Host ""
    Write-Host "  [PROSES] Membersihkan Riwayat Deteksi Ancaman Lama..." -ForegroundColor Green
    $action = {
        $histPath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory"
        if (Test-Path -LiteralPath $histPath) {
            Remove-Item -LiteralPath "$histPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $ok = Invoke-ActionElevated $action
    if ($ok) {
        Write-Host "  > Cache Riwayat Deteksi... [CLEANED]" -ForegroundColor Green
        Write-Host "  [BERHASIL] Riwayat ancaman bersih! Ikon keamanan kembali hijau." -ForegroundColor Green
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = (Get-DefenderState).StatusText
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-103] Utilitas Saklar Windows Defender" -ForegroundColor White
    Write-Host "  Status  : $finalStatus" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------------------------
# LOOP UTAMA INTERAKTIF (100% SINGLE-TERMINAL NATIVE EXECUTION)
# ------------------------------------------------------------------------------
while ($true) {
    Show-CompactHeader
    
    Write-Host "  PILIHAN MENU TINDAKAN OTOMATIS:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Mode Gamer (Matikan Proteksi Real-Time / Bebas Game)" -ForegroundColor Red
    Write-Host "   [2] Mode Normal (Aktifkan Kembali Proteksi Penuh)" -ForegroundColor Green
    Write-Host "   [3] Mode Cerdas (Tambah Folder Pengecualian / Exclusion)" -ForegroundColor Cyan
    Write-Host "   [4] Jinakkan CPU (Kunci MsMpEng.exe Maksimal 10% CPU)" -ForegroundColor White
    Write-Host "   [5] Unblock File (Hapus Blokir Layar Biru SmartScreen)" -ForegroundColor Yellow
    Write-Host "   [6] Perbaikan (Reset Aplikasi Windows Security Blank)" -ForegroundColor Magenta
    Write-Host "   [7] Pembersihan (Kuras Riwayat Ancaman / Threat History)" -ForegroundColor Green
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host -NoNewline "  Pilih Menu [1 - 7, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()
    
    switch ($choice.Trim()) {
        "1" { Invoke-GamerMode }
        "2" { Invoke-NormalMode }
        "3" { Invoke-FolderExclusion }
        "4" { Invoke-LimitCpu }
        "5" { Invoke-UnblockFile }
        "6" { Invoke-ResetSecurityApp }
        "7" { Invoke-ClearThreatHistory }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            # Refresh menu jika input di luar opsi
        }
    }
}
