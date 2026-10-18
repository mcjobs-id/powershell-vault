# ==============================================================================
# FOKUSKONTEN - WINRAR LICENSE REMOVER (RESTORE TO TRIAL)
# ==============================================================================

$targetPaths = @(
    "$env:ProgramFiles\WinRAR\rarreg.key",
    "${env:ProgramFiles(x86)}\WinRAR\rarreg.key",
    "$env:APPDATA\WinRAR\rarreg.key"
)

foreach ($f in $targetPaths) {
    if (Test-Path $f) {
        Remove-Item -Path $f -Force
        Write-Host "Menghapus lisensi dari: $f" -ForegroundColor Yellow
    }
}

Write-Host "Lisensi WinRAR telah dihapus. Status kembali ke evaluasi standar." -ForegroundColor Green
