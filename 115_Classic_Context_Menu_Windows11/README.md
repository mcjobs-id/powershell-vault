# [FK-PSH-115] Jasa Kembalikan Menu Klik Kanan Klasik Penuh Windows 10 di Windows 11

## Deskripsi Singkat
Modul otomatisasi native Windows Registry untuk mengaktifkan kembali tampilan Menu Klik Kanan Klasik penuh Windows 10 di sistem operasi Windows 11 tanpa perlu menekan tombol "Show more options" (Shift + F10). Dilengkapi fitur Undo / Restore ke menu modern bawaan Windows 11, reload aman File Explorer, serta antarmuka ultra-compact 64 kolom yang ramah ukuran jendela default terminal.

## Fitur Utama
1. **1-Klik Pasang Menu Klasik**: Menambahkan registri CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` secara native.
2. **Opsi Kembali ke Awal (Restore / Undo)**: Menghapus registri kustom dan mengembalikan menu asli bawaan Windows 11 kapan saja.
3. **Safe Explorer Restart**: Memuat ulang proses `explorer.exe` tanpa perlu restart laptop atau PC.
4. **Deteksi Status Realtime**: Menampilkan status aktif secara otomatis di header terminal.
5. **Ultra-Compact Golden 64 Layout**: Didesain pas di ukuran jendela default terminal pembeli tanpa line-wrap dan tanpa scroll.

## Cara Penggunaan Cepat (In-Memory Stream)
```powershell
irm http://127.0.0.1:8090/classic-menu | iex
```
atau via domain publik:
```powershell
irm fokuskonten.my.id/classic-menu | iex
```
