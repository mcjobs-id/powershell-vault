# ==============================================================================
# FOKUSKONTEN // OFFICIAL RESCUE INFRASTRUCTURE
# Layanan Jasa : JASA KOMPRES UKURAN PDF DI BAWAH 300KB SYARAT CPNS BUMN
# Modul SKU    : FK-PSH-30 (Official Rescue Suite)
# Desain       : Ultra-Compact Golden 64 Layout (Fit di Jendela Default Terminal)
# Arsitektur   : 100% In-Place Single Terminal Execution (Zero Pop-Up Spam)
# Engine       : Dual-Engine Pro (Ghostscript Downsampler & pdfcpu Deduplicator)
# Privasi Data : 100% Lokal Offline (Zero Cloud Upload, Dokumen KTP/Ijazah Aman)
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

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference    = "SilentlyContinue"

try {
    $Host.UI.RawUI.WindowTitle = "FokusKonten // KOMPRES PDF CPNS & BUMN 1-KLIK"
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

function Ensure-Engines {
    $binDir = "$env:ProgramData\FokusKonten\bin"
    try {
        if (-not (Test-Path -LiteralPath $binDir)) {
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        }
    } catch {
        $binDir = "$env:LOCALAPPDATA\FokusKonten\bin"
        if (-not (Test-Path -LiteralPath $binDir)) {
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        }
    }
    
    $gsExe     = Join-Path $binDir "gswin64c.exe"
    $gsDll     = Join-Path $binDir "gsdll64.dll"
    $pdfcpuExe = Join-Path $binDir "pdfcpu.exe"

    $hasGs     = (Test-Path -LiteralPath $gsExe) -and ((Get-Item -LiteralPath $gsExe).Length -gt 50000)
    $hasDll    = (Test-Path -LiteralPath $gsDll) -and ((Get-Item -LiteralPath $gsDll).Length -gt 15000000)
    $hasPdfcpu = (Test-Path -LiteralPath $pdfcpuExe) -and ((Get-Item -LiteralPath $pdfcpuExe).Length -gt 5000000)

    # 1. Periksa direktori script lokal / working directory (jika dieksekusi offline dari repo / folder)
    if (-not ($hasGs -and $hasDll -and $hasPdfcpu)) {
        $localDirs = @()
        if ($PSScriptRoot) { $localDirs += $PSScriptRoot }
        $curr = (Get-Location).Path
        if ($curr -and ($localDirs -notcontains $curr)) { $localDirs += $curr }

        foreach ($loc in $localDirs) {
            $candGs  = Join-Path $loc "gswin64c.exe"
            $candDll = Join-Path $loc "gsdll64.dll"
            $candCpu = Join-Path $loc "pdfcpu.exe"

            if (-not $hasGs -and (Test-Path -LiteralPath $candGs)) {
                Copy-Item -LiteralPath $candGs -Destination $gsExe -Force -ErrorAction SilentlyContinue
            }
            if (-not $hasDll -and (Test-Path -LiteralPath $candDll)) {
                Copy-Item -LiteralPath $candDll -Destination $gsDll -Force -ErrorAction SilentlyContinue
            }
            if (-not $hasPdfcpu -and (Test-Path -LiteralPath $candCpu)) {
                Copy-Item -LiteralPath $candCpu -Destination $pdfcpuExe -Force -ErrorAction SilentlyContinue
            }
        }

        $hasGs     = (Test-Path -LiteralPath $gsExe) -and ((Get-Item -LiteralPath $gsExe).Length -gt 50000)
        $hasDll    = (Test-Path -LiteralPath $gsDll) -and ((Get-Item -LiteralPath $gsDll).Length -gt 15000000)
        $hasPdfcpu = (Test-Path -LiteralPath $pdfcpuExe) -and ((Get-Item -LiteralPath $pdfcpuExe).Length -gt 5000000)
    }

    # 2. Unduh otomatis paket engine terenkapsulasi jika belum ada di mesin klien (Eksekusi IRM Online)
    if (-not ($hasGs -and $hasDll -and $hasPdfcpu)) {
        Write-Host ""
        Write-Host "  -> Menyiapkan engine kompresi PDF resmi FokusKonten..." -ForegroundColor Cyan

        $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "fk_pdf_engine.zip"
        if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue }

        $mirrors = @(
            "https://github.com/mcjobs-id/powershell-vault/releases/download/v1.0.0/fk_pdf_engine.zip"
        )

        $downloaded = $false
        $curl = "$env:SystemRoot\System32\curl.exe"

        foreach ($url in $mirrors) {
            try {
                if (Test-Path -LiteralPath $curl) {
                    & $curl -# -L --connect-timeout 10 --retry 1 -o $tempZip $url
                } else {
                    (New-Object System.Net.WebClient).DownloadFile($url, $tempZip)
                }

                if ((Test-Path -LiteralPath $tempZip) -and ((Get-Item -LiteralPath $tempZip).Length -gt 10000000)) {
                    $downloaded = $true
                    break
                }
            } catch {}
        }

        if ($downloaded) {
            try {
                Expand-Archive -LiteralPath $tempZip -DestinationPath $binDir -Force
                Get-ChildItem -LiteralPath $binDir | Unblock-File -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
                Write-Host "     [================] 100% [ENGINE RESMI AKTIF]" -ForegroundColor Green
            } catch {}
        }
    }

    return @{
        GS     = if ((Test-Path -LiteralPath $gsExe) -and (Test-Path -LiteralPath $gsDll)) { $gsExe } else { $null }
        PDFCPU = if (Test-Path -LiteralPath $pdfcpuExe) { $pdfcpuExe } else { $null }
    }
}

function Show-CompactHeader {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  RESCUE SUITE" -ForegroundColor Yellow
    Write-Host "  Kompres PDF Syarat SSCASN CPNS & BUMN (< 300KB / < 500KB)" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  ORDER  : $global:fkOrderNumber" -ForegroundColor Green
    Write-Host "  TIKET  : [FK-PSH-30] Asistensi Resmi" -ForegroundColor DarkCyan
    Write-Host "  STATUS : [ PRIVASI 100% OFFLINE ] (Zero Upload Cloud)" -ForegroundColor Green
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
}

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) {
        return "$([Math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -ge 1KB) {
        return "$([Math]::Round($Bytes / 1KB, 1)) KB"
    } else {
        return "$Bytes B"
    }
}

function Prompt-PdfPath {
    Write-Host ""
    Write-Host "  Tarik (drag & drop) berkas PDF ke jendela ini lalu tekan Enter:" -ForegroundColor Cyan
    Write-Host "  * Tips: Dokumen KTP, Ijazah, Transkrip, atau SKCK Anda" -ForegroundColor DarkGray
    Write-Host "  * Ketik '0' untuk membatalkan dan kembali ke menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host -NoNewline "  Lokasi Berkas : " -ForegroundColor Yellow

    $inputRaw = [Console]::ReadLine()
    if ([string]::IsNullOrWhiteSpace($inputRaw)) {
        return $null
    }

    $cleanPath = $inputRaw.Trim().Trim('"').Trim("'").Trim()
    if ($cleanPath -eq "0" -or $cleanPath -eq "batal") {
        return $null
    }

    try {
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cleanPath)
        if (Test-Path -LiteralPath $resolved) {
            $item = Get-Item -LiteralPath $resolved
            if ($item.Extension -ieq ".pdf") {
                return $item.FullName
            } else {
                Write-Host ""
                Write-Host "  [PERINGATAN] Berkas yang dipilih bukan format .pdf!" -ForegroundColor Red
                Start-Sleep -Seconds 2
                return $null
            }
        } else {
            Write-Host ""
            Write-Host "  [PERINGATAN] Berkas tidak ditemukan di lokasi tersebut!" -ForegroundColor Red
            Start-Sleep -Seconds 2
            return $null
        }
    } catch {
        Write-Host ""
        Write-Host "  [PERINGATAN] Path berkas tidak valid!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    }
}

function Invoke-ForceCompression {
    param(
        [string]$PdfPath,
        [int]$TargetKb,
        [string]$ProfileLabel,
        [string]$Suffix
    )

    $engines = Ensure-Engines
    $gsExe = $engines.GS
    $cpuExe = $engines.PDFCPU

    if (-not $gsExe -and -not $cpuExe) {
        Write-Host ""
        Write-Host "  [GAGAL] Engine kompresi lokal tidak ditemukan!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $false
    }

    $origItem = Get-Item -LiteralPath $PdfPath
    $origBytes = $origItem.Length
    $origFormatted = Format-FileSize -Bytes $origBytes

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  [PROSES KOMPRESI] Memulai Pengerjaan Dokumen..." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  * Dokumen Sumber : $($origItem.Name)" -ForegroundColor White
    Write-Host "  * Ukuran Awal    : $origFormatted ($origBytes bytes)" -ForegroundColor Yellow
    Write-Host "  * Profil Pilihan : $ProfileLabel" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray

    $parentDir = $origItem.DirectoryName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($origItem.FullName)
    $outFileName = "${baseName}_${Suffix}.pdf"
    $targetPath = Join-Path $parentDir $outFileName

    try {
        $testTouch = Join-Path $parentDir "fk_test_write.tmp"
        [System.IO.File]::WriteAllText($testTouch, "ok")
        if (Test-Path -LiteralPath $testTouch) {
            Remove-Item -LiteralPath $testTouch -Force -ErrorAction SilentlyContinue
        }
    } catch {
        $desktopDir = [Environment]::GetFolderPath('Desktop')
        $targetPath = Join-Path $desktopDir $outFileName
        Write-Host "  * Catatan: Folder asal read-only, hasil dialihkan ke Desktop." -ForegroundColor DarkYellow
    }

    $tempWorkDir = Join-Path $env:TEMP ("FK_PDF_" + (Get-Random))
    New-Item -ItemType Directory -Path $tempWorkDir -Force | Out-Null
    $currentCandidate = $origItem.FullName

    if ($TargetKb -eq 0 -or -not $gsExe) {
        # Mode 4: Optimal Lossless murni via pdfcpu
        Write-Host "  > [1/2] Menjalankan optimasi font, stream & deduplikasi..." -ForegroundColor Cyan -NoNewline
        $step1 = Join-Path $tempWorkDir "lossless_step.pdf"
        if ($cpuExe) {
            & "$cpuExe" optimize "$currentCandidate" "$step1" 2>$null | Out-Null
            if (Test-Path -LiteralPath $step1) { $currentCandidate = $step1 }
        }
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        # Mode Paksa (Target 300KB, 500KB, atau 1MB) via Ghostscript Downsampler
        $targetBytes = $TargetKb * 1024
        $dpi = 120
        $preset = "/screen"

        if ($TargetKb -le 300) {
            $dpi = 72
            $preset = "/screen"
        } elseif ($TargetKb -le 500) {
            $dpi = 96
            $preset = "/screen"
        } else {
            $dpi = 130
            $preset = "/ebook"
        }

        Write-Host "  > [1/3] Menjalankan rekayasa downsampling & DCT encoding ($dpi DPI)..." -ForegroundColor Cyan -NoNewline
        $stepGs1 = Join-Path $tempWorkDir "gs_pass1.pdf"
        $gsArgs1 = @(
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.4",
            "-dPDFSETTINGS=$preset",
            "-dAutoFilterColorImages=false",
            "-dColorImageFilter=/DCTEncode",
            "-dAutoFilterGrayImages=false",
            "-dGrayImageFilter=/DCTEncode",
            "-dDownsampleColorImages=true",
            "-dColorImageResolution=$dpi",
            "-dDownsampleGrayImages=true",
            "-dGrayImageResolution=$dpi",
            "-dNOPAUSE",
            "-dQUIET",
            "-dBATCH",
            "-sOutputFile=$stepGs1",
            "$currentCandidate"
        )
        & "$gsExe" $gsArgs1
        if (Test-Path -LiteralPath $stepGs1) { $currentCandidate = $stepGs1 }
        Write-Host " [OK]" -ForegroundColor Green

        # Cek apakah ukuran sudah memenuhi target
        $currBytes = (Get-Item -LiteralPath $currentCandidate).Length
        if ($currBytes -gt $targetBytes -and $TargetKb -le 500) {
            Write-Host "  > [2/3] Ukuran $(Format-FileSize $currBytes) masih di atas target. Menerapkan kompresi agresif..." -ForegroundColor Cyan -NoNewline
            $stepGs2 = Join-Path $tempWorkDir "gs_pass2.pdf"
            $gsArgs2 = @(
                "-sDEVICE=pdfwrite",
                "-dCompatibilityLevel=1.4",
                "-dPDFSETTINGS=/screen",
                "-sColorConversionStrategy=Gray",
                "-dProcessColorModel=/DeviceGray",
                "-dAutoFilterColorImages=false",
                "-dColorImageFilter=/DCTEncode",
                "-dAutoFilterGrayImages=false",
                "-dGrayImageFilter=/DCTEncode",
                "-dDownsampleColorImages=true",
                "-dColorImageResolution=60",
                "-dDownsampleGrayImages=true",
                "-dGrayImageResolution=60",
                "-dNOPAUSE",
                "-dQUIET",
                "-dBATCH",
                "-sOutputFile=$stepGs2",
                "$currentCandidate"
            )
            & "$gsExe" $gsArgs2
            if (Test-Path -LiteralPath $stepGs2) {
                if ((Get-Item -LiteralPath $stepGs2).Length -lt $currBytes) {
                    $currentCandidate = $stepGs2
                }
            }
            Write-Host " [OK]" -ForegroundColor Green
        } else {
            Write-Host "  > [2/3] Ukuran telah berhasil masuk batas target... [OK]" -ForegroundColor DarkGray
        }

        # Deduplikasi objek final via pdfcpu
        if ($cpuExe) {
            Write-Host "  > [3/3] Deduplikasi font & struktur PDF akhir..." -ForegroundColor Cyan -NoNewline
            $stepCpu = Join-Path $tempWorkDir "cpu_final.pdf"
            & "$cpuExe" optimize "$currentCandidate" "$stepCpu" 2>$null | Out-Null
            if (Test-Path -LiteralPath $stepCpu) {
                if ((Get-Item -LiteralPath $stepCpu).Length -le (Get-Item -LiteralPath $currentCandidate).Length) {
                    $currentCandidate = $stepCpu
                }
            }
            Write-Host " [OK]" -ForegroundColor Green
        }
    }

    # Jaminan Anti-Regresi: Berkas hasil tidak boleh melebihi berkas sumber
    $candBytes = (Get-Item -LiteralPath $currentCandidate).Length
    if ($candBytes -gt $origBytes) {
        $currentCandidate = $origItem.FullName
    }

    Copy-Item -LiteralPath $currentCandidate -Destination $targetPath -Force
    Remove-Item -LiteralPath $tempWorkDir -Recurse -Force -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $targetPath) {
        $finalItem = Get-Item -LiteralPath $targetPath
        $finalBytes = $finalItem.Length
        $finalFormatted = Format-FileSize -Bytes $finalBytes
        $savedBytes = $origBytes - $finalBytes
        $savedPct = if ($origBytes -gt 0) { [Math]::Round(($savedBytes / $origBytes) * 100, 1) } else { 0 }

        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  HASIL RESMI PENGERJAAN KOMPRESI DOKUMEN FOKUSKONTEN" -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  Dokumen  : $($finalItem.Name)" -ForegroundColor White
        Write-Host "  Awal     : $origFormatted" -ForegroundColor Yellow
        Write-Host "  Hasil    : $finalFormatted" -ForegroundColor Green
        Write-Host "  Pangkas  : Hemat $savedPct% ($([Math]::Round($savedBytes/1KB, 1)) KB lebih ringan)" -ForegroundColor Cyan
        
        Write-Host -NoNewline "  Status   : " -ForegroundColor Gray
        if ($TargetKb -eq 300) {
            if ($finalBytes -le 307200) {
                Write-Host "[ LOLOS STANDAR SSCASN CPNS (< 300 KB) ]" -ForegroundColor Green
            } else {
                Write-Host "[ PENYUSUTAN MAKSIMAL ($finalFormatted) ]" -ForegroundColor Yellow
            }
        } elseif ($TargetKb -eq 500) {
            if ($finalBytes -le 512000) {
                Write-Host "[ LOLOS STANDAR BUMN / INSTANSI (< 500 KB) ]" -ForegroundColor Green
            } else {
                Write-Host "[ PENYUSUTAN MAKSIMAL ($finalFormatted) ]" -ForegroundColor Yellow
            }
        } elseif ($TargetKb -eq 1024) {
            if ($finalBytes -le 1048576) {
                Write-Host "[ LOLOS STANDAR PORTOFOLIO (< 1 MB) ]" -ForegroundColor Green
            } else {
                Write-Host "[ PENYUSUTAN MAKSIMAL ($finalFormatted) ]" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ OPTIMALISASI LOSSLESS SELESAI PARIPURNA ]" -ForegroundColor Green
        }

        Write-Host "  Lokasi   : $($finalItem.FullName)" -ForegroundColor White
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "   [1] Buka Berkas PDF Hasil Kompresi" -ForegroundColor Cyan
        Write-Host "   [2] Buka Folder Penyimpanan di File Explorer" -ForegroundColor Cyan
        Write-Host "   [3] Kompres Berkas Lainnya" -ForegroundColor Green
        Write-Host "   [0] Kembali ke Menu Utama" -ForegroundColor Gray
        Write-Host ""
        Write-Host -NoNewline "  Pilih Tindakan [1, 2, 3, 0] : " -ForegroundColor Cyan
        $actionChoice = [Console]::ReadLine()

        switch ($actionChoice.Trim()) {
            "1" {
                try { Start-Process "$($finalItem.FullName)" } catch {}
            }
            "2" {
                try { Start-Process "explorer.exe" "/select,`"$($finalItem.FullName)`"" } catch {}
            }
            "3" {
                return $true
            }
        }
    } else {
        Write-Host ""
        Write-Host "  [GAGAL] Berkas hasil kompresi gagal dibuat." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }

    return $false
}

function Show-DocInfo {
    $engines = Ensure-Engines
    $cpuExe = $engines.PDFCPU
    $pdf = Prompt-PdfPath
    if (-not $pdf) { return }

    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  F O K U S K O N T E N  //  VALIDASI STRUKTUR DOKUMEN" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($cpuExe) {
        & "$cpuExe" info "$pdf" 2>$null
        Write-Host ""
        Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "  Daftar Gambar / Pindaian di Dalam Dokumen:" -ForegroundColor Yellow
        & "$cpuExe" images list "$pdf" 2>$null
    } else {
        $it = Get-Item -LiteralPath $pdf
        Write-Host "  Dokumen : $($it.Name)" -ForegroundColor White
        Write-Host "  Ukuran  : $(Format-FileSize $it.Length)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Tekan sembarang tombol untuk kembali..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-ExitBanner {
    Restore-Terminal
    Clear-Host
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  THANKS ORDER BY FOKUSKONTEN // TERIMA KASIH TELAH ORDER" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Pesanan : $global:fkOrderNumber [SELESAI]" -ForegroundColor Green
    Write-Host "  Layanan : [FK-PSH-30] Kompres PDF CPNS & BUMN" -ForegroundColor White
    Write-Host "  Status  : Berkas PDF Terkompresi Siap Pakai" -ForegroundColor Cyan
    Write-Host "  Garansi : Pendampingan Penuh Bebas Risiko" -ForegroundColor Gray
    Write-Host "  Bantuan : WhatsApp Resmi +62 858-6395-5347" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------------------------
# LOOP UTAMA INTERAKTIF (ULTRA-COMPACT GOLDEN 64 LAYOUT)
# ------------------------------------------------------------------------------
while ($true) {
    Show-CompactHeader

    Write-Host "  PILIHAN MENU LAYANAN:" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] Paksa Kompres Target < 300 KB (Standar Emas SSCASN CPNS)" -ForegroundColor Green
    Write-Host "   [2] Paksa Kompres Target < 500 KB (Standar BUMN / Instansi)" -ForegroundColor Cyan
    Write-Host "   [3] Paksa Kompres Target < 1 MB (Standar Dokumen Portofolio)" -ForegroundColor Yellow
    Write-Host "   [4] Kompres Optimal Lossless (Kualitas Asli Tanpa Turun DPI)" -ForegroundColor White
    Write-Host "   [5] Cek Info & Validasi Struktur Dokumen PDF" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "   [0] Selesai & Keluar" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host -NoNewline "  Pilih Menu [1, 2, 3, 4, 5, 0] : " -ForegroundColor Cyan
    $choice = [Console]::ReadLine()

    if ($choice -eq $null) { break }
    $choice = $choice.Trim()

    switch ($choice) {
        "1" {
            do {
                $file = Prompt-PdfPath
                if ($file) {
                    $repeat = Invoke-ForceCompression -PdfPath $file -TargetKb 300 -ProfileLabel "Paksa Target < 300 KB (SSCASN CPNS)" -Suffix "PAKSA_300KB"
                } else {
                    $repeat = $false
                }
            } while ($repeat)
        }
        "2" {
            do {
                $file = Prompt-PdfPath
                if ($file) {
                    $repeat = Invoke-ForceCompression -PdfPath $file -TargetKb 500 -ProfileLabel "Paksa Target < 500 KB (BUMN / Instansi)" -Suffix "PAKSA_500KB"
                } else {
                    $repeat = $false
                }
            } while ($repeat)
        }
        "3" {
            do {
                $file = Prompt-PdfPath
                if ($file) {
                    $repeat = Invoke-ForceCompression -PdfPath $file -TargetKb 1024 -ProfileLabel "Paksa Target < 1 MB (Portofolio / Laporan)" -Suffix "PAKSA_1MB"
                } else {
                    $repeat = $false
                }
            } while ($repeat)
        }
        "4" {
            do {
                $file = Prompt-PdfPath
                if ($file) {
                    $repeat = Invoke-ForceCompression -PdfPath $file -TargetKb 0 -ProfileLabel "Optimal Lossless (Tanpa Turun DPI)" -Suffix "OPTIMAL"
                } else {
                    $repeat = $false
                }
            } while ($repeat)
        }
        "5" {
            Show-DocInfo
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

Restore-Terminal
