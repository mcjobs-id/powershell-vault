<#
================================================================================
 FOKUSKONTEN - NATIVE PDF RESTRICTION & PERMISSIONS UNLOCKER
 Menghapus Proteksi Copy-Paste, Printing, dan Editing pada Dokumen PDF Terkunci
================================================================================
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$InputPath,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " FOKUSKONTEN - PDF RESTRICTION & PERMISSIONS UNLOCKER            " -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

if (-not $InputPath) {
    Write-Host "Gunakan perintah berikut untuk membuka gembok PDF:" -ForegroundColor Yellow
    Write-Host "powershell -ExecutionPolicy Bypass -File .\unlock_pdf_restrictions.ps1 -InputPath 'dokumen_terkunci.pdf' -OutputPath 'dokumen_terbuka.pdf'" -ForegroundColor Gray
    exit 0
}

if (-not (Test-Path $InputPath)) {
    Write-Host "[ERROR] Berkas PDF input tidak ditemukan: $InputPath" -ForegroundColor Red
    exit 1
}

if (-not $OutputPath) {
    $dir = Split-Path -Parent $InputPath
    $name = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $OutputPath = Join-Path $dir "$($name)_UNLOCKED.pdf"
}

Write-Host "[1/3] Membaca struktur biner dokumen PDF..." -ForegroundColor Green
$bytes = [System.IO.File]::ReadAllBytes($InputPath)

# Konversi biner ke string mentah ISO-8859-1 untuk pencocokan dictionary /Encrypt
$rawText = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($bytes)

Write-Host "[2/3] Memeriksa kamus enkripsi /Encrypt dan hak akses /P..." -ForegroundColor Green
if ($rawText -match "/Encrypt\s+(\d+)\s+(\d+)\s+R") {
    $encryptObjNum = $matches[1]
    Write-Host "   -> Kamus enkripsi terdeteksi pada objek: $encryptObjNum" -ForegroundColor Yellow

    # Menetralkan pointer /Encrypt di kamus trailer PDF
    $unlockedText = [System.Text.RegularExpressions.Regex]::Replace($rawText, "/Encrypt\s+\d+\s+\d+\s+R", "/Encrypt null         ")
    
    # Netralkan batasan flag izin /P di objek enkripsi
    $unlockedText = [System.Text.RegularExpressions.Regex]::Replace($unlockedText, "/P\s+-\d+", "/P -1      ")

    $outBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($unlockedText)
    [System.IO.File]::WriteAllBytes($OutputPath, $outBytes)

    Write-Host "[3/3] Rekonstruksi biner PDF selesai!" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " SUKSES: Dokumen PDF berhasil dibuka gembok proteksinya!" -ForegroundColor Green
    Write-Host " Berkas Baru: $OutputPath" -ForegroundColor Yellow
    Write-Host " Anda kini dapat melakukan Copy-Paste teks, Print, dan Edit secara bebas." -ForegroundColor Gray
    Write-Host "=================================================================" -ForegroundColor Cyan
} else {
    Write-Host "   -> Dokumen PDF ini tidak memiliki kamus enkripsi /Encrypt (Tidak terkunci)." -ForegroundColor Yellow
    Copy-Item -Path $InputPath -Destination $OutputPath -Force
    Write-Host " Dokumen disimpan langsung ke: $OutputPath" -ForegroundColor Gray
}
