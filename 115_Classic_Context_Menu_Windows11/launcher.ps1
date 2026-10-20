# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : KEMBALIKAN MENU KLIK KANAN KLASIK WINDOWS 10 DI WINDOWS 11
# Modul SKU    : FK-PSH-115 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden Layout (Fit di Jendela Default Terminal)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // MENU KLIK KANAN KLASIK WIN 11"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

$global:regCLSID = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
$global:regInproc = "$global:regCLSID\InprocServer32"

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Get-ContextMenuState {
    if (Test-Path -LiteralPath $global:regInproc) {
        return "CLASSIC"
    }
    return "MODERN"
}

function Show-CompactHeader {
    Clear-Host
    $state = Get-ContextMenuState

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Menu Klik Kanan Klasik Windows 10 di Windows 11" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-115] Asistensi Resmi" -ForegroundColor DarkCyan
    
    if ($state -eq "CLASSIC") {
        Write-Host "  STATUS : [ MENU KLASIK WIN 10 AKTIF ] (Penuh 1x Klik)" -ForegroundColor Green
    } else {
        Write-Host "  STATUS : [ MENU MODERN WIN 11 AKTIF ] (Perlu Klik 2x)" -ForegroundColor Yellow
    }
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Restart-ExplorerSafe {
    Write-Host "  > Memuat ulang File Explorer..." -ForegroundColor Cyan -NoNewline
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
    Start-Sleep -Milliseconds 1000
    Write-Host " [OK]" -ForegroundColor Green
}

function Enable-ClassicMenu {
    Write-Host ""
    Write-Host "  [PROSES] Memasang Menu Klik Kanan Klasik Win 10..." -ForegroundColor Cyan
    try {
        if (-not (Test-Path -LiteralPath $global:regInproc)) {
            New-Item -Path $global:regInproc -Force | Out-Null
        }
        Set-ItemProperty -Path $global:regInproc -Name "(Default)" -Value "" -Force | Out-Null
        Write-Host "  > Update Registri Windows... [OK]" -ForegroundColor Green
        
        Restart-ExplorerSafe
        
        Write-Host ""
        Write-Host "  [BERHASIL] Menu Klasik Windows 10 sekarang AKTIF!" -ForegroundColor Green
        Write-Host "  Silakan coba klik kanan di Desktop atau File Explorer." -ForegroundColor White
    } catch {
        Write-Host "  [GAGAL] Registri error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Restore-ModernMenu {
    Write-Host ""
    Write-Host "  [PROSES] Mengembalikan ke Menu Asli Windows 11..." -ForegroundColor Yellow
    try {
        if (Test-Path -LiteralPath $global:regCLSID) {
            Remove-Item -Path $global:regCLSID -Recurse -Force -ErrorAction Stop
            Write-Host "  > Hapus Registri Kustom... [OK]" -ForegroundColor Green
        } else {
            Write-Host "  > Sistem sudah di kondisi default bawaan... [OK]" -ForegroundColor Cyan
        }
        
        Restart-ExplorerSafe
        
        Write-Host ""
        Write-Host "  [BERHASIL] Menu Asli Windows 11 telah dipulihkan!" -ForegroundColor Green
        Write-Host "  Tampilan klik kanan kembali ke format ringkas bawaan." -ForegroundColor White
    } catch {
        Write-Host "  [GAGAL] Registri error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SystemGuide {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  INFO & PANDUAN TEKNIS" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  * OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor White
    Write-Host "  * Mode Klasik: Menu lengkap langsung terbuka tanpa klik 2x." -ForegroundColor Gray
    Write-Host "  * Mode Modern: Bawaan Win 11 (harus 'Show More Options')." -ForegroundColor Gray
    Write-Host "  * Kapan pun bisa ditukar bolak-balik via menu [1] dan [2]." -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    $finalStatus = if (Test-Path $global:regInproc) { "Menu Klasik Win 10 Aktif" } else { "Menu Modern Win 11 Aktif" }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-115] Menu Klik Kanan Win 11" -ForegroundColor White
    Write-Host "  Status  : $finalStatus (Siap Pakai)" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------------------------
# LOOP UTAMA INTERAKTIF (ULTRA-COMPACT GOLDEN LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-CompactHeader
    
    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Pasang Menu Klasik Win 10 (Penuh Tanpa Klik 2x)" -ForegroundColor Green
    Write-Host "   [2] Kembalikan ke Menu Asli Win 11 (Restore / Undo)" -ForegroundColor Yellow
    Write-Host "   [3] Refresh File Explorer Saja" -ForegroundColor Cyan
    Write-Host "   [4] Cek Info & Panduan Sistem" -ForegroundColor White
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()
    
    switch ($choice.Trim()) {
        "1" {
            Enable-ClassicMenu
        }
        "2" {
            Restore-ModernMenu
        }
        "3" {
            Write-Host ""
            Restart-ExplorerSafe
            Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" {
            Show-SystemGuide
        }
        "0" {
            Show-ExitBanner
            return
        }
        default {
            # Refresh menu jika input di luar opsi
        }
    }
}
