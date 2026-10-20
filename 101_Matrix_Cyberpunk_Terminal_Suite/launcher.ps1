# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : SETUP TAMPILAN TERMINAL MATRIX & CYBER SIMULATOR
# Modul SKU    : FK-PSH-101 (Official Rescue Suite)
# Engineer     : FokusKonten Enterprise Automation & Cybersecurity Systems
# Arsitektur   : Native In-Memory Dynamic Terminal Simulation (Zero Binary Risk)
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
    $Host.UI.RawUI.WindowTitle = "FokusKonten // ENTERPRISE TERMINAL MODDING & CYBER RESCUE SUITE"
} catch {}

$origFg = $Host.UI.RawUI.ForegroundColor
$origBg = $Host.UI.RawUI.BackgroundColor

# State Palette Default: Green Matrix
$global:themePrimary   = "Green"
$global:themeSecondary = "DarkGreen"
$global:themeHighlight = "White"
$global:themeAccent    = "Cyan"
$global:themeName      = "Emerald Matrix (Default)"

function Restore-Terminal {
    try {
        $Host.UI.RawUI.ForegroundColor = $origFg
        $Host.UI.RawUI.BackgroundColor = $origBg
        [Console]::CursorVisible = $true
    } catch {}
}

function Show-CinematicOpening {
    Clear-Host
    try { [Console]::CursorVisible = $false } catch {}

    Write-Host ""
    Write-Host " [BOOT]   Inisialisasi Terminal Cyber Enterprise FokusKonten..." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 80
    Write-Host " [THANKS] Terima kasih sudah menggunakan jasa layanan FokusKonten!" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 80
    Write-Host " [ORDER]  Verifikasi Pesanan : $global:fkOrderNumber [VERIFIED RESMI]" -ForegroundColor Green
    Start-Sleep -Milliseconds 80
    Write-Host " [TIKET]  Nomor Tiket Jasa   : [FK-PSH-101] (Matrix Cyberpunk Suite)" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 80
    Write-Host " [HOST]   Arsitektur Sistem  : $([System.Environment]::OSVersion.VersionString) (x64 Native)" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 80
    Write-Host " [NET]    Jalur Terhubung    : http://127.0.0.1:8090" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 100

    Write-Host ""
    Write-Host -NoNewline " [LOAD] Membuka Modul Visual Terminal: [" -ForegroundColor DarkCyan
    for ($i = 0; $i -lt 30; $i++) {
        Write-Host -NoNewline "=" -ForegroundColor Green
        Start-Sleep -Milliseconds 12
    }
    Write-Host "] SIAP 100%" -ForegroundColor White
    Start-Sleep -Milliseconds 200

    # Quick Cascade Intro
    Clear-Host
    $w = 80
    try { $w = [Console]::WindowWidth } catch {}
    $rnd = New-Object System.Random
    for ($line = 0; $line -lt 4; $line++) {
        $hexLine = ""
        for ($k = 0; $k -lt [Math]::Min(36, [int]($w/2)); $k++) {
            $hexLine += ($rnd.Next(0, 255)).ToString("X2") + " "
        }
        Write-Host " :: INITIALIZING STREAM :: $hexLine" -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 25
    }
    Start-Sleep -Milliseconds 100
    Clear-Host
}

function Show-GrandBanner {
    Clear-Host
    Write-Host ""
    # Banner FOKUSKONTEN 11 Karakter Lengkap (Anti-Wrap)
    Write-Host "  ██████╗ ██████╗ ██╗  ██╗██╗   ██╗███████╗██╗  ██╗ ██████╗ ███╗  ██╗████████╗███████╗███╗  ██╗" -ForegroundColor $global:themePrimary
    Write-Host "  ██╔═══╝██╔═══██╗██║ ██╔╝██║   ██║██╔════╝██║ ██╔╝██╔═══██╗████╗ ██║╚══██╔══╝██╔════╝████╗ ██║" -ForegroundColor $global:themePrimary
    Write-Host "  █████╗ ██║   ██║█████╔╝ ██║   ██║███████╗█████╔╝ ██║   ██║██╔██╗██║   ██║   █████╗  ██╔██╗██║" -ForegroundColor $global:themePrimary
    Write-Host "  ██╔══╝ ██║   ██║██╔═██╗ ██║   ██║╚════██║██╔═██╗ ██║   ██║██║╚████║   ██║   ██╔══╝  ██║╚████║" -ForegroundColor $global:themeSecondary
    Write-Host "  ██║    ╚██████╔╝██║  ██╗╚██████╔╝███████║██║  ██╗╚██████╔╝██║ ╚███║   ██║   ███████╗██║ ╚███║" -ForegroundColor $global:themeSecondary
    Write-Host "  ╚═╝     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚══╝   ╚═╝   ╚══════╝╚═╝  ╚══╝" -ForegroundColor $global:themeSecondary
    Write-Host "               ENTERPRISE CYBERSECURITY & TERMINAL RESCUE INFRASTRUCTURE               " -ForegroundColor $global:themeAccent
    Write-Host " ========================================================================================" -ForegroundColor $global:themeSecondary
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH MENGGUNAKAN JASA FOKUSKONTEN          " -ForegroundColor Yellow
    Write-Host " ----------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  NOMOR PESANAN : $global:fkOrderNumber (VERIFIED ORDER // ASISTENSI RESMI)        " -ForegroundColor Green
    Write-Host "  LAYANAN JASA  : SETUP TAMPILAN TERMINAL MATRIX & CYBER SIMULATOR                        " -ForegroundColor White
    Write-Host "  NOMOR TIKET   : [FK-PSH-101] (ASISTENSI RESMI FOKUSKONTEN)                              " -ForegroundColor Cyan
    Write-Host "  STATUS JASA   : AKTIF // PENGERJAAN MANDIRI BERBANTUAN OTOMASI RESMI                    " -ForegroundColor $global:themePrimary
    Write-Host "  TEMA AKTIF    : $global:themeName                                                       " -ForegroundColor Magenta
    Write-Host " ========================================================================================" -ForegroundColor $global:themeSecondary
    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Animasi Hujan Matrix (Hijau Klasik)" -ForegroundColor $global:themePrimary
    Write-Host "      [2] Simulasi Hacking Terminal (Nmap & Cyber Tools)" -ForegroundColor Red
    Write-Host "      [3] Aliran Kode Data Cepat (Cyberpunk Stream)" -ForegroundColor Cyan
    Write-Host "      [4] Monitor Layar Komputer (CPU, RAM & Disk Sci-Fi)" -ForegroundColor Yellow
    Write-Host "      [5] Ganti Warna Terminal (Hijau / Biru / Merah / Kuning)" -ForegroundColor Magenta
    Write-Host "      [6] Putar Otomatis Nonstop (Looping Bergantian)" -ForegroundColor White
    Write-Host ""
    Write-Host "      [0] Selesai & Keluar Layanan" -ForegroundColor DarkGray
    Write-Host " ========================================================================================" -ForegroundColor $global:themeSecondary
    Write-Host ""
}

function Get-UserChoice {
    try {
        Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 5, 6, 0] (Enter untuk [1]) : " -ForegroundColor $global:themePrimary
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Enter) {
                Write-Host "1" -ForegroundColor $global:themePrimary
                return "1"
            }
            $c = $k.KeyChar.ToString()
            if ($c -in @('1','2','3','4','5','6','0')) {
                Write-Host $c -ForegroundColor $global:themePrimary
                return $c
            }
        }
    } catch {
        $c = Read-Host "  Pilih Menu [1, 2, 3, 4, 5, 6, 0] (Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }
}

# --- MODEL 1: ANIMASI HUJAN MATRIX ---
function Run-MatrixRain ([int]$durationSeconds = 0) {
    Clear-Host
    try { [Console]::CursorVisible = $false } catch {}

    $width = 80
    $height = 25
    try {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight
    } catch {}

    $chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#$%&*+-=<>~"
    $drops = New-Object int[] $width
    $rnd = New-Object System.Random

    for ($i = 0; $i -lt $width; $i++) {
        $drops[$i] = $rnd.Next(-$height, 0)
    }

    Write-Host "=== [1] ANIMASI HUJAN MATRIX AKTIF ===" -ForegroundColor $global:themePrimary
    Write-Host "Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600
    Clear-Host

    $startTime = Get-Date

    while ($true) {
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        if ($durationSeconds -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $durationSeconds) { break }

        try {
            $w = [Console]::WindowWidth
            $h = [Console]::WindowHeight
        } catch {
            $w = $width
            $h = $height
        }

        for ($x = 0; $x -lt $w; $x += 2) {
            if ($x -ge $drops.Length) { break }
            $y = $drops[$x]

            if ($y -ge 0 -and $y -lt $h) {
                try {
                    [Console]::SetCursorPosition($x, $y)
                    $c = $chars[$rnd.Next(0, $chars.Length)]
                    Write-Host -NoNewline $c -ForegroundColor $global:themeHighlight
                } catch {}
            }

            if (($y - 1) -ge 0 -and ($y - 1) -lt $h) {
                try {
                    [Console]::SetCursorPosition($x, $y - 1)
                    $c = $chars[$rnd.Next(0, $chars.Length)]
                    Write-Host -NoNewline $c -ForegroundColor $global:themePrimary
                } catch {}
            }

            if (($y - 6) -ge 0 -and ($y - 6) -lt $h) {
                try {
                    [Console]::SetCursorPosition($x, $y - 6)
                    Write-Host -NoNewline " "
                } catch {}
            }

            $drops[$x]++
            if ($drops[$x] -ge $h + 6) {
                $drops[$x] = $rnd.Next(-10, 0)
            }
        }

        Start-Sleep -Milliseconds 30
    }

    Restore-Terminal
}

# --- MODEL 2: SIMULASI HACKING TERMINAL (KARYA MUHARI) ---
function Run-RedTeamC2Simulator ([int]$durationSeconds = 0) {
    Clear-Host
    try { [Console]::CursorVisible = $false } catch {}
    Write-Host "=== [2] SIMULASI HACKING TERMINAL AKTIF ===" -ForegroundColor Red
    Write-Host "Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600
    Clear-Host

    $rnd = New-Object System.Random
    $startTime = Get-Date

    while ($true) {
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        if ($durationSeconds -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $durationSeconds) { break }

        $targetIp = "$($rnd.Next(10,192)).$($rnd.Next(1,250)).$($rnd.Next(1,250)).$($rnd.Next(1,250))"
        $targetHost = "server-$($rnd.Next(100,999)).network.internal"

        Clear-Host
        Write-Host "====================================================================================" -ForegroundColor DarkGreen
        Write-Host " [SIMULASI CYBER TERMINAL] - REKAYASA PENETRASI JARINGAN OTOMATIS" -ForegroundColor Green
        Write-Host " TARGET : $targetHost ($targetIp) | STATUS: PEMINDAIAN REALTIME" -ForegroundColor Yellow
        Write-Host " TOOLS  : NMAP 7.95, SQLMAP 1.7, COBALT STRIKE, HASHCAT 6.2, GDB PWNDBG" -ForegroundColor Cyan
        Write-Host "====================================================================================" -ForegroundColor DarkGreen
        Write-Host ""

        # 1. NMAP SCAN
        Write-Host "[*] TAHAP 1: PEMINDAIAN PORT & LAYANAN (NMAP 7.95)" -ForegroundColor Yellow
        Write-Host "    Scanning target $targetIp..." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 250
        Write-Host "    PORT     STATE SERVICE       VERSION" -ForegroundColor White
        Write-Host "    22/tcp   open  ssh           OpenSSH 9.2p1" -ForegroundColor Green
        Write-Host "    80/tcp   open  http          nginx/1.22.1" -ForegroundColor Green
        Write-Host "    443/tcp  open  ssl/http      nginx/1.22.1" -ForegroundColor Green
        Write-Host "    8080/tcp open  http-proxy    Apache Tomcat/9.0.65" -ForegroundColor Green
        Write-Host ""
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Start-Sleep -Milliseconds 450

        # 2. SQLMAP INJECTION
        Write-Host "[*] TAHAP 2: PENGUJIAN KERENTANAN DATABASE (SQLMAP 1.7)" -ForegroundColor Yellow
        Write-Host "    [INFO] Memeriksa parameter URL target..." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 200
        Write-Host "    [+] Ditemukan celah: UNION Query Injection (4 Kolom)" -ForegroundColor Green
        Write-Host "    [+] Database aktif: PostgreSQL 15.2 (Linux x86_64)" -ForegroundColor Green
        Write-Host "    [+] Berhasil mengekstrak skema tabel pengguna [OK]" -ForegroundColor Green
        Write-Host ""
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Start-Sleep -Milliseconds 450

        # 3. C2 BEACON
        Write-Host "[*] TAHAP 3: AKSES KONSOL JARAK JAUH (C2 BEACON)" -ForegroundColor Yellow
        Write-Host "    [*] Mengirimkan paket terenkripsi AES-256..." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 250
        Write-Host "    [+] Sesi aktif terhubung: [BEACON-ID: #$($rnd.Next(10000,99999))]" -ForegroundColor Green
        Write-Host "    [+] Hak akses sistem: Administrator / Root [CONFIRMED]" -ForegroundColor Green
        Write-Host ""
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Start-Sleep -Milliseconds 450

        # 4. HASHCAT CRACKING
        Write-Host "[*] TAHAP 4: DEKRIPSI KATA SANDI (HASHCAT 6.2)" -ForegroundColor Yellow
        Write-Host "    Memulai benchmarking GPU NVIDIA RTX..." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 200
        for ($p = 20; $p -le 100; $p += 25) {
            $rate = ($rnd.Next(13500, 15500) / 1000).ToString("N2")
            Write-Host ("`r    [PROGRES] Dekripsi SHA-512 [" + $p + "%] | Kecepatan: " + $rate + " GH/s ") -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 120
        }
        Write-Host ""
        Write-Host "    [+] Kata sandi berhasil dipecahkan: admin:Pass2026! [MATCHED]" -ForegroundColor Green
        Write-Host ""
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Start-Sleep -Milliseconds 450

        # 5. GDB PWNDBG
        Write-Host "[*] TAHAP 5: VERIFIKASI INTEGRITAS MEMORI (GDB PWNDBG)" -ForegroundColor Yellow
        Write-Host "    pwndbg> checksec: CANARY=ON, NX=ON, PIE=ON, RELRO=FULL" -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 250
        Write-Host "    [+] ROP chain terpasang pada memori sistem [SUKSES]" -ForegroundColor Green
        Write-Host ""
        Write-Host "====================================================================================" -ForegroundColor DarkGreen
        Write-Host " [SELESAI] SIKLUS SIMULASI SELESAI -- MEMULAI TARGET BERIKUTNYA..." -ForegroundColor Green
        Write-Host " (Tekan sembarang tombol di keyboard untuk kembali ke menu)" -ForegroundColor Yellow
        Write-Host "====================================================================================" -ForegroundColor DarkGreen
        
        for ($cd = 3; $cd -ge 1; $cd--) {
            if ([Console]::KeyAvailable) { break }
            Write-Host -NoNewline ("`r Target berikutnya dalam " + $cd + " detik... ") -ForegroundColor Cyan
            Start-Sleep -Milliseconds 1000
        }
        Write-Host ""
    }

    Restore-Terminal
}

# --- MODEL 3: ALIRAN KODE DATA CEPAT ---
function Run-CyberpunkStream ([int]$durationSeconds = 0) {
    Clear-Host
    Write-Host "=== [3] ALIRAN KODE DATA CEPAT AKTIF ===" -ForegroundColor $global:themeAccent
    Write-Host "Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600
    Clear-Host

    $rnd = New-Object System.Random
    $tags = @("NET-IN", "SYS-CORE", "MEM-DUMP", "CRYPTO-AES", "PROXY-NODE", "ROUTER-RX", "SOCKET-TCP", "AUTH-TOKEN")
    $startTime = Get-Date

    while ($true) {
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        if ($durationSeconds -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $durationSeconds) { break }

        $tag = $tags[$rnd.Next(0, $tags.Length)]
        $addr = "0x" + ($rnd.Next(0x1000, 0xFFFF)).ToString("X4") + ":" + ($rnd.Next(0x1000, 0xFFFF)).ToString("X4")
        $ip = "$($rnd.Next(10,250)).$($rnd.Next(1,250)).$($rnd.Next(1,250)).$($rnd.Next(1,250))"
        $bytes = ""
        for ($b = 0; $b -lt 8; $b++) {
            $bytes += ($rnd.Next(0, 255)).ToString("X2") + " "
        }

        Write-Host -NoNewline "[$tag] " -ForegroundColor $global:themeAccent
        Write-Host -NoNewline "$addr " -ForegroundColor DarkGray
        Write-Host -NoNewline "IP:$ip " -ForegroundColor White
        Write-Host -NoNewline "DATA:[$bytes] " -ForegroundColor $global:themeSecondary
        $stat = if ($rnd.Next(0, 10) -gt 2) { "SYN_ACK_OK" } else { "BYPASS_ROUTE" }
        Write-Host "$stat" -ForegroundColor Magenta

        Start-Sleep -Milliseconds ($rnd.Next(20, 60))
    }

    Restore-Terminal
}

# --- MODEL 4: MONITOR LAYAR KOMPUTER (CPU, RAM, DISK) ---
function Run-CyberHudMonitor ([int]$durationSeconds = 0) {
    Clear-Host
    try { [Console]::CursorVisible = $false } catch {}
    Write-Host "=== [4] MONITOR KOMPUTER REALTIME AKTIF ===" -ForegroundColor Yellow
    Write-Host "Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $totalRamMb = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
    $driveC = Get-PSDrive C -ErrorAction SilentlyContinue
    $startTime = Get-Date

    while ($true) {
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        if ($durationSeconds -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $durationSeconds) { break }

        $freeRamMb = [math]::Round($os.FreePhysicalMemory / 1024, 0)
        $usedRamMb = $totalRamMb - $freeRamMb
        $ramPercent = if ($totalRamMb -gt 0) { [math]::Round(($usedRamMb / $totalRamMb) * 100, 1) } else { 0 }

        $diskTotalGb = [math]::Round(($driveC.Used + $driveC.Free) / 1GB, 1)
        $diskUsedGb = [math]::Round($driveC.Used / 1GB, 1)
        $diskPercent = if ($diskTotalGb -gt 0) { [math]::Round(($diskUsedGb / $diskTotalGb) * 100, 1) } else { 0 }

        $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $uptime = (Get-Date) - $os.LastBootUpTime
        $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

        $ramBars = [int]($ramPercent / 5)
        $ramGauge = "[" + ("=" * $ramBars) + ("." * (20 - $ramBars)) + "]"

        $diskBars = [int]($diskPercent / 5)
        $diskGauge = "[" + ("=" * $diskBars) + ("." * (20 - $diskBars)) + "]"

        Clear-Host
        Write-Host "==================================================================" -ForegroundColor $global:themePrimary
        Write-Host "  FOKUSKONTEN // MONITOR PERANGKAT KERAS KOMPUTER" -ForegroundColor $global:themePrimary
        Write-Host "  Telemetri Penggunaan Memori, Harddisk, dan Waktu Nyala Sistem" -ForegroundColor Yellow
        Write-Host "==================================================================" -ForegroundColor $global:themePrimary
        Write-Host ""
        Write-Host "  Waktu Sekarang : $timeStr" -ForegroundColor Cyan
        Write-Host "  Waktu Nyala PC : $uptimeStr" -ForegroundColor White
        Write-Host "  Nama Komputer  : $env:COMPUTERNAME" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ("  PENGGUNAAN RAM : " + $ramGauge + " " + $ramPercent + "% [" + $usedRamMb + " MB / " + $totalRamMb + " MB]") -ForegroundColor Green
        Write-Host ("  DISK DRIVE C:  : " + $diskGauge + " " + $diskPercent + "% [" + $diskUsedGb + " GB / " + $diskTotalGb + " GB]") -ForegroundColor Cyan
        Write-Host "  STATUS SISTEM  : NORMAL // BEKERJA 100%" -ForegroundColor Green
        Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow

        Start-Sleep -Milliseconds 500
    }

    Restore-Terminal
}

# --- MODEL 5: GANTI WARNA TERMINAL ---
function Show-ThemeSelector {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor $global:themePrimary
    Write-Host "  FOKUSKONTEN // GANTI WARNA TEMA TERMINAL" -ForegroundColor White
    Write-Host "==================================================================" -ForegroundColor $global:themePrimary
    Write-Host ""
    Write-Host "  PILIHAN WARNA TAMPILAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Emerald Matrix (Hijau Matrix Klasik)" -ForegroundColor Green
    Write-Host "      [2] Neon Cyberpunk (Cyan Biru Futuristik)" -ForegroundColor Cyan
    Write-Host "      [3] Blood Red Alert (Merah Peringatan)" -ForegroundColor Red
    Write-Host "      [4] Retro Amber (Kuning Oranye Komputer Jadul)" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "      [0] Kembali ke Menu Utama" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host -NoNewline "  Pilih Warna [1, 2, 3, 4, 0] : " -ForegroundColor $global:themePrimary

    try {
        $t = [Console]::ReadKey($true).KeyChar.ToString()
    } catch {
        $t = Read-Host
    }

    switch ($t) {
        "1" {
            $global:themePrimary   = "Green"
            $global:themeSecondary = "DarkGreen"
            $global:themeHighlight = "White"
            $global:themeAccent    = "Cyan"
            $global:themeName      = "Emerald Matrix"
        }
        "2" {
            $global:themePrimary   = "Cyan"
            $global:themeSecondary = "DarkCyan"
            $global:themeHighlight = "White"
            $global:themeAccent    = "Magenta"
            $global:themeName      = "Neon Cyberpunk"
        }
        "3" {
            $global:themePrimary   = "Red"
            $global:themeSecondary = "DarkRed"
            $global:themeHighlight = "Yellow"
            $global:themeAccent    = "White"
            $global:themeName      = "Blood Red Alert"
        }
        "4" {
            $global:themePrimary   = "Yellow"
            $global:themeSecondary = "DarkYellow"
            $global:themeHighlight = "White"
            $global:themeAccent    = "Gray"
            $global:themeName      = "Retro Amber"
        }
    }
}

# --- MODEL 6: MODE PUTAR OTOMATIS NONSTOP ---
function Run-BroadcastLoop {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "  MODE PUTAR OTOMATIS NONSTOP DIAKTIFKAN" -ForegroundColor Green
    Write-Host "  Animasi akan otomatis berganti model setiap beberapa detik." -ForegroundColor White
    Write-Host "  Sangat cocok untuk display layar meja, video konten, atau live." -ForegroundColor Gray
    Write-Host "  Tekan sembarang tombol di keyboard kapan saja untuk berhenti." -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Start-Sleep -Seconds 2

    while ($true) {
        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Run-MatrixRain -durationSeconds 25

        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Run-RedTeamC2Simulator -durationSeconds 35

        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Run-CyberpunkStream -durationSeconds 20

        if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); break }
        Run-CyberHudMonitor -durationSeconds 15
    }
}

# --- MAIN CONTROLLER LOOP ---
Show-CinematicOpening

while ($true) {
    Show-GrandBanner
    $choice = Get-UserChoice

    switch ($choice) {
        "1" { Run-MatrixRain }
        "2" { Run-RedTeamC2Simulator }
        "3" { Run-CyberpunkStream }
        "4" { Run-CyberHudMonitor }
        "5" { Show-ThemeSelector }
        "6" { Run-BroadcastLoop }
        "0" {
            Restore-Terminal
            Clear-Host
            Write-Host ""
            Write-Host " ===========================================================================" -ForegroundColor Green
            Write-Host "  THANKS ORDER BY FOKUSKONTEN" -ForegroundColor Yellow
            Write-Host "  Terima kasih sudah menggunakan jasa FokusKonten." -ForegroundColor White
            Write-Host "  Layanan Setup Tampilan Terminal Matrix telah selesai dengan sukses." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  [SERAH TERIMA LAYANAN JASA]" -ForegroundColor White
            Write-Host "  * Nomor Pesanan  : $global:fkOrderNumber [SELESAI PARIPURNA]" -ForegroundColor Green
            Write-Host "  * Tiket Layanan  : [FK-PSH-101] SELESAI PARIPURNA" -ForegroundColor Green
            Write-Host "  * Garansi Resmi  : Pendampingan Asistensi Bebas Risiko Sistem" -ForegroundColor Green
            Write-Host "  * Kontak Bantuan : WhatsApp Layanan Resmi +62 858-6395-5347" -ForegroundColor Yellow
            Write-Host " ===========================================================================" -ForegroundColor Green
            Write-Host ""
            return
        }
        default {
            Restore-Terminal
            return
        }
    }
}
