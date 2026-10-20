# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Modul 101: CYBER TERMINAL & MATRIX HACKER SUITE
# Engine   : Native In-Memory Dynamic Terminal Simulation Engine
# ==============================================================================
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
} catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // CYBER TERMINAL & MATRIX HACKER SUITE"
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

function Show-Header {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "  Cyber Terminal & Matrix Hacker Simulation Suite" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Solusi visual interaktif 1-klik untuk presentasi, live streaming," -ForegroundColor White
    Write-Host "  latar konten video edukasi, dan modding terminal profesional." -ForegroundColor Gray
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  RINGKASAN MODUL:" -ForegroundColor White
    Write-Host "  * Layanan        : MATRIX CYBERPUNK TERMINAL SIMULATOR" -ForegroundColor Cyan
    Write-Host "  * Status Lisensi : AKTIF - MENGIKUTI KEBIJAKAN RESMI FOKUSKONTEN" -ForegroundColor Green
    Write-Host "  * Metode Inti    : In-Memory Native PowerShell (Zero Third-Party Binary)" -ForegroundColor White
    Write-Host "  * Tingkat Risiko : 0% (100% Aman, Ringan, Tidak Mengubah Sistem)" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PILIHAN MODEL ANIMASI (LOOPING TINGGAL TEKAN TOMBOL UNTUK KEMBALI):" -ForegroundColor White
    Write-Host ""
    Write-Host "      [1] Matrix Rain Hijau Klasik (Digital Code Stream Vertikal)" -ForegroundColor Green
    Write-Host "          Hujan kode digital mengalir deras dengan karakter dinamis." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [2] Cyberpunk Data Stream (Cyan & Magenta High-Speed Hex Dump)" -ForegroundColor Cyan
    Write-Host "          Aliran blok memori, paket data, dan protokol jaringan cepat." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [3] Red Alert Breach Simulator (Simulasi Alarm & Penetrasi Cyber)" -ForegroundColor Red
    Write-Host "          Simulasi alarm intrusi, bypass firewall, dan visual hack dramatis." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [4] Realtime Cyber HUD System Monitor (Sci-Fi Hardware Gauges)" -ForegroundColor Yellow
    Write-Host "          Pemantau metrik CPU, RAM, Disk, dan Uptime bergaya kokpit hacker." -ForegroundColor Gray
    Write-Host ""
    Write-Host "      [0] Keluar (Kembali ke Terminal Normal)" -ForegroundColor DarkGray
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
}

function Get-UserChoice {
    try {
        Write-Host -NoNewline "  Pilihan Model [1, 2, 3, 4, 0] (Tekan Enter untuk [1]) : " -ForegroundColor Green
        while ($true) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Enter) {
                Write-Host "1" -ForegroundColor Green
                return "1"
            }
            $c = $k.KeyChar.ToString()
            if ($c -in @('1','2','3','4','0')) {
                Write-Host $c -ForegroundColor Green
                return $c
            }
        }
    } catch {
        $c = Read-Host "  Pilihan Model [1, 2, 3, 4, 0] (Tekan Enter untuk [1])"
        if ([string]::IsNullOrWhiteSpace($c)) { return "1" }
        return $c.Trim()
    }
}

function Run-MatrixRain {
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

    Write-Host "=== TEKAN TOMBOL APAPUN DI KEYBOARD UNTUK BERHENTI & KEMBALI KE MENU ===" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800
    Clear-Host

    while ($true) {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }

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
                    Write-Host -NoNewline $c -ForegroundColor White
                } catch {}
            }

            if (($y - 1) -ge 0 -and ($y - 1) -lt $h) {
                try {
                    [Console]::SetCursorPosition($x, $y - 1)
                    $c = $chars[$rnd.Next(0, $chars.Length)]
                    Write-Host -NoNewline $c -ForegroundColor Green
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

function Run-CyberpunkStream {
    Clear-Host
    Write-Host "=== TEKAN TOMBOL APAPUN DI KEYBOARD UNTUK BERHENTI & KEMBALI KE MENU ===" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800
    Clear-Host

    $rnd = New-Object System.Random
    $tags = @("NET-IN", "SYS-CORE", "MEM-DUMP", "CRYPTO-AES", "PROXY-NODE", "ROUTER-RX", "SOCKET-TCP", "AUTH-TOKEN")
    $colors = @("Cyan", "DarkCyan", "Magenta", "White", "DarkGray")

    while ($true) {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }

        $tag = $tags[$rnd.Next(0, $tags.Length)]
        $addr = "0x" + ($rnd.Next(0x1000, 0xFFFF)).ToString("X4") + ":" + ($rnd.Next(0x1000, 0xFFFF)).ToString("X4")
        $ip = "$($rnd.Next(10,250)).$($rnd.Next(1,250)).$($rnd.Next(1,250)).$($rnd.Next(1,250))"
        $bytes = ""
        for ($b = 0; $b -lt 8; $b++) {
            $bytes += ($rnd.Next(0, 255)).ToString("X2") + " "
        }

        Write-Host -NoNewline "[$tag] " -ForegroundColor Cyan
        Write-Host -NoNewline "$addr " -ForegroundColor DarkGray
        Write-Host -NoNewline "IP:$ip " -ForegroundColor White
        Write-Host -NoNewline "DATA:[$bytes] " -ForegroundColor DarkCyan
        $stat = if ($rnd.Next(0, 10) -gt 2) { "SYN_ACK_OK" } else { "BYPASS_ROUTE" }
        Write-Host "$stat" -ForegroundColor Magenta

        Start-Sleep -Milliseconds ($rnd.Next(20, 60))
    }

    Restore-Terminal
}

function Run-RedAlertBreach {
    Clear-Host
    Write-Host "=== TEKAN TOMBOL APAPUN DI KEYBOARD UNTUK BERHENTI & KEMBALI KE MENU ===" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800
    Clear-Host

    $rnd = New-Object System.Random
    $nodes = @("GATEWAY_ROOT", "FIREWALL_KRNL", "SEC_VAULT_NODE", "AUTH_KEYSTONE", "DATA_STORAGE_C")
    $steps = @(
        "Initiating target connection handshake...",
        "Probing defensive vector on open ports [80, 443, 8080, 9222]...",
        "Payload staging: Exploit buffer injection into memory space...",
        "Bypassing behavioral heuristics and active guard policies...",
        "Elevating token privileges: SeDebugPrivilege -> ENABLED",
        "Breaching core system security perimeter...",
        "Root authorization key acquired: [0xCAFEBABE-FOKUSKONTEN]",
        "Extracting target payload stream...",
        "Access Granted. System under operator control."
    )

    while ($true) {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }

        Clear-Host
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host "  [!] RED ALERT: CYBER PENETRATION SEQUENCE ACTIVE [!]" -ForegroundColor Yellow
        Write-Host "  TARGET NODE: $($nodes[$rnd.Next(0, $nodes.Length)]) | PROTOCOL: ZERO-DAY SIM" -ForegroundColor Red
        Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        Write-Host ""

        foreach ($step in $steps) {
            if ([Console]::KeyAvailable) { break }
            Write-Host -NoNewline "  [*] " -ForegroundColor DarkRed
            Write-Host -NoNewline "$step " -ForegroundColor White
            Start-Sleep -Milliseconds ($rnd.Next(80, 200))
            Write-Host "[OK]" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "  >>> BREACH CONFIRMED - OPERATOR CONTROL ACTIVE <<<" -ForegroundColor Red
        Write-Host ""
        
        for ($i = 0; $i -lt 15; $i++) {
            if ([Console]::KeyAvailable) { break }
            $hex = ($rnd.Next(10000000, 99999999)).ToString("X8")
            Write-Host "  STREAM_DUMP: 0x$hex 0x$($rnd.Next(1000,9999).ToString('X4')) :: INTEGRITY 100%" -ForegroundColor DarkRed
            Start-Sleep -Milliseconds 50
        }

        Start-Sleep -Milliseconds 1000
    }

    Restore-Terminal
}

function Run-CyberHudMonitor {
    Clear-Host
    try { [Console]::CursorVisible = $false } catch {}
    Write-Host "=== TEKAN TOMBOL APAPUN DI KEYBOARD UNTUK BERHENTI & KEMBALI KE MENU ===" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $totalRamMb = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
    $driveC = Get-PSDrive C -ErrorAction SilentlyContinue

    while ($true) {
        if ([Console]::KeyAvailable) {
            $null = [Console]::ReadKey($true)
            break
        }

        $freeRamMb = [math]::Round($os.FreePhysicalMemory / 1024, 0)
        $usedRamMb = $totalRamMb - $freeRamMb
        $ramPercent = if ($totalRamMb -gt 0) { [math]::Round(($usedRamMb / $totalRamMb) * 100, 1) } else { 0 }

        $diskTotalGb = [math]::Round(($driveC.Used + $driveC.Free) / 1GB, 1)
        $diskUsedGb = [math]::Round($driveC.Used / 1GB, 1)
        $diskPercent = if ($diskTotalGb -gt 0) { [math]::Round(($diskUsedGb / $diskTotalGb) * 100, 1) } else { 0 }

        $timeStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $uptime = (Get-Date) - $os.LastBootUpTime
        $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s"

        $ramBars = [int]($ramPercent / 5)
        $ramGauge = "[" + ("=" * $ramBars) + ("." * (20 - $ramBars)) + "]"

        $diskBars = [int]($diskPercent / 5)
        $diskGauge = "[" + ("=" * $diskBars) + ("." * (20 - $diskBars)) + "]"

        Clear-Host
        Write-Host "==================================================================" -ForegroundColor Green
        Write-Host "  FOKUSKONTEN // CYBER HUD SYSTEM MONITOR" -ForegroundColor Green
        Write-Host "  Live Hardware & Realtime Operational Telemetry" -ForegroundColor Yellow
        Write-Host "==================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  [TIMESTAMP]  : $timeStr" -ForegroundColor Cyan
        Write-Host "  [UPTIME]     : $uptimeStr" -ForegroundColor White
        Write-Host "  [HOST]       : $env:COMPUTERNAME" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  RAM USAGE    : $ramGauge $ramPercent% ($usedRamMb MB / $totalRamMb MB)" -ForegroundColor Green
        Write-Host "  DISK C:      : $diskGauge $diskPercent% ($diskUsedGb GB / $diskTotalGb GB)" -ForegroundColor Cyan
        Write-Host "  STATUS       : SYSTEM NORMAL // OPERATIONAL 100%" -ForegroundColor Green
        Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Tekan sembarang tombol di keyboard untuk kembali ke menu..." -ForegroundColor Yellow

        Start-Sleep -Milliseconds 500
    }

    Restore-Terminal
}

# --- MAIN CONTROLLER LOOP ---
while ($true) {
    Show-Header
    $choice = Get-UserChoice

    switch ($choice) {
        "1" { Run-MatrixRain }
        "2" { Run-CyberpunkStream }
        "3" { Run-RedAlertBreach }
        "4" { Run-CyberHudMonitor }
        "0" {
            Restore-Terminal
            Clear-Host
            Write-Host "==================================================================" -ForegroundColor Green
            Write-Host "  FokusKonten Cyber Terminal Suite ditutup secara bersih." -ForegroundColor Green
            Write-Host "  Terima kasih telah menggunakan utilitas resmi FokusKonten!" -ForegroundColor Yellow
            Write-Host "==================================================================" -ForegroundColor Green
            Write-Host ""
            return
        }
        default {
            Restore-Terminal
            return
        }
    }
}
