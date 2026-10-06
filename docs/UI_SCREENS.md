# UI_SCREENS.md

Semua teks UI Bahasa Indonesia. Gaya sederhana dan konsisten; jangan menambah elemen dekoratif.

## 1. Aturan desain umum

- **Warna** (Tailwind): utama `emerald-600` (hover `emerald-700`), bahaya `red-600`, peringatan `amber-500`, latar `slate-50`, kartu putih berbingkai `slate-200`, teks `slate-900`/`slate-600`.
- **Ukuran**: teks isi `text-base`, judul `text-xl font-semibold`, angka uang di kasir `text-lg font-semibold tabular-nums`.
- **Tombol**: tinggi min 44 px (`min-h-11`), sudut `rounded-lg`, tombol utama emerald solid, sekunder putih berbingkai. Tombol nonaktif `opacity-50 cursor-not-allowed`.
- **Tata letak**: mobile-first. Layar kasir di tablet landscape (≥ 768 px) dua kolom: menu kiri (±60%), keranjang kanan; di HP: menu penuh dengan bilah keranjang melayang di bawah yang membuka panel penuh.
- **Tiga keadaan wajib** untuk setiap data:
  - Memuat: spinner + "Memuat..."
  - Kosong: ikon sederhana (teks) + kalimat, mis. "Belum ada transaksi hari ini."
  - Error: pesan merah + tombol "Coba lagi"
- **Konfirmasi** untuk aksi tak terbalik (tutup shift, setujui void, nonaktifkan pengguna): modal "Yakin?" dengan tombol "Batal" dan tombol aksi.
- **Umpan balik**: sukses = banner hijau singkat di atas (hilang 3 dtk); gagal = pesan merah di dekat tombol.
- Uang selalu `formatRupiah()`; input uang menampilkan angka berformat titik dan mengirim integer.

## 2. Navigasi (layout `(app)`)

Bilah atas: nama outlet "C'Bowl.id", nama pengguna + role, tombol "Keluar".
Menu kasir: **Kasir · Riwayat · Shift**.
Menu admin tambahan: **Menu · Sambal · Pengguna · Void · Shift Semua · Laporan · Log · Pengaturan**. Di HP, menu tampil sebagai baris yang bisa digeser horizontal.

## 3. Layar

### 3.1 Login `/login` (publik)
Kartu tengah: judul "Masuk ke POS C'Bowl.id", field Email, Password, tombol "Masuk". Gagal: "Email atau password salah". Akun nonaktif: "Akun tidak aktif. Hubungi admin." Setelah masuk → `/`.

### 3.2 Shift `/kasir/shift`
- **Tanpa shift terbuka**: kartu "Buka Shift", field "Kas awal (Rp)", tombol "Buka Shift".
- **Dengan shift terbuka**: ringkasan (dibuka pukul, kas awal, jumlah order, penjualan tunai, penjualan QRIS), field "Uang tunai di laci (hitung manual)", tombol "Tutup Shift" → modal konfirmasi → setelah sukses tampil **Rekap**: kas seharusnya, kas dihitung, selisih (hijau 0, kuning lebih, merah kurang), tombol "Selesai".

### 3.3 Kasir `/kasir`
Jika tidak ada shift terbuka: kartu "Anda belum membuka shift" + tombol "Buka Shift" (ke 3.2), layar menu tidak ditampilkan.

```
┌───────────────────────────────┬──────────────────────┐
│ [Rice Bowl][Pendamping][Minum]│ Keranjang            │
│ ┌────────┐┌────────┐┌────────┐│ ──────────────────── │
│ │Nama    ││Nama    ││Nama    ││ Rice Bowl Contoh 1   │
│ │Rp28.000││Rp30.000││Rp32.000││  Sambal Matah        │
│ └────────┘└────────┘└────────┘│  [-] 2 [+]  Rp56.000 │
│ ...                           │ ──────────────────── │
│                               │ Subtotal   Rp64.000  │
│                               │ [ Dine-in | Takeaway]│
│                               │ Kanal: [Langsung ▾]  │
│                               │ [ Tunai | QRIS ]     │
│                               │ [ Bayar Rp64.000 ]   │
└───────────────────────────────┴──────────────────────┘
```
Perilaku:
- Tab kategori; ketuk kartu menu = tambah 1 ke keranjang. Rice bowl → **modal Pilih Sambal** (daftar tombol besar satu pilihan, wajib) lalu masuk keranjang. Menu + sambal sama → jumlah bertambah.
- Keranjang: tiap baris nama, sambal (bila ada), tombol − dan +, jumlah, total baris, tombol hapus. Jumlah turun ke 0 = baris hilang.
- Tombol "Kosongkan" (dengan konfirmasi bila ada isi).
- "Bayar" aktif bila keranjang tidak kosong dan semua rice bowl bersambal. Membuka **Panel Pembayaran** (modal).

**Panel Pembayaran** (modal): ringkasan total; pilihan Tipe (Dine-in/Takeaway, default Dine-in); Kanal (Langsung/WhatsApp/GoFood/GrabFood, default Langsung); bagian Diskon (opsional, tombol "Tambah diskon" → field Rp + alasan); metode Tunai/QRIS.
- Tunai: field "Uang diterima", tombol cepat **Uang pas**, **50.000**, **100.000**; tampil "Kembalian: Rp…" atau "Kurang: Rp…" (merah). Tombol "Simpan Transaksi" aktif hanya bila diterima ≥ total.
- QRIS: teks "Pastikan pembayaran QRIS sudah masuk." lalu "Simpan Transaksi".
- Sukses → pindah ke Struk `/struk/[id]`; keranjang dikosongkan. Gagal → pesan error di modal, keranjang tetap.
- Menu yang sudah tidak tersedia saat simpan → pesan dari server, tawarkan memuat ulang menu.

### 3.4 Struk `/struk/[id]`
Tampilan sesuai `BUSINESS_RULES.md` §8, lebar maks 58 mm (±220 px) di tengah. Tombol "Cetak" (`window.print()`), "Transaksi Baru" (ke `/kasir`), dan bila bukan VOID: "Ajukan Void". CSS `@media print`: sembunyikan navigasi dan tombol, lebar 58 mm, tanpa margin.

### 3.5 Riwayat `/riwayat`
Filter: tombol "Hari ini" | "Shift ini". Daftar kartu: `#012`, jam, total, metode, badge status (VOID merah, "Menunggu void" kuning). Ketuk → Struk. Admin melihat semua kasir (ada nama kasir). Kosong: "Belum ada transaksi."

**Modal Ajukan Void**: textarea "Alasan void" (min 5 karakter), tombol "Kirim Pengajuan". Sukses: banner "Pengajuan dikirim. Menunggu persetujuan admin."

### 3.6 Admin: Menu `/admin/menu`
Tabel/daftar: nama, kategori, harga, toggle "Tersedia", tombol "Ubah", "Nonaktifkan". Tombol "Tambah Menu" → modal (nama, kategori, harga, urutan). Kategori dikelola di panel kecil di atas (tambah/ubah nama, centang "Wajib sambal"). Menu nonaktif disembunyikan secara default; ada saklar "Tampilkan yang nonaktif".

### 3.7 Admin: Sambal `/admin/sambal`
Daftar: nama, toggle "Tersedia", Ubah. Tombol "Tambah Sambal".

### 3.8 Admin: Pengguna `/admin/pengguna`
Daftar: nama, email, role, status. "Tambah Pengguna" (email, password, nama, role). Aksi: Ubah nama/role, Nonaktifkan/Aktifkan (konfirmasi). Baris diri sendiri: tombol nonaktif tidak ada.

### 3.9 Admin: Void `/admin/void`
Tab Menunggu (default) | Selesai. Kartu: order `#012`, total, kasir pengaju, waktu, alasan. Tombol "Setujui" (hijau) dan "Tolak" (merah), keduanya membuka modal konfirmasi dengan catatan opsional. Kosong: "Tidak ada pengajuan void."

### 3.10 Admin: Shift `/admin/shift`
Pilih tanggal (default hari ini). Tabel: kasir, buka, tutup, kas awal, seharusnya, dihitung, selisih (berwarna). Shift terbuka ditandai "Berjalan".

### 3.11 Admin: Laporan `/admin/laporan`
Pemilih rentang tanggal (default hari ini, preset "Hari ini", "7 hari", "Bulan ini"). Empat bagian: **Ringkasan** (kartu: Omzet, Jumlah transaksi, Tunai, QRIS, Diskon, Void), **Menu Terlaris** (tabel top 10), **Jam Ramai** (tabel jam 00-23 dengan batang horizontal dari `div` berlebar persentase; tanpa library grafik), **Per Kanal** (tabel). Bila rentang > 1 hari tampilkan juga tabel per tanggal.

### 3.12 Admin: Log `/admin/log`
Daftar terbaru dulu: waktu, pelaku, aksi (label Indonesia), ringkasan detail. Filter aksi (dropdown). Tombol "Muat lebih banyak".
Label aksi: `shift_opened` Buka shift · `shift_closed` Tutup shift · `discount_applied` Diskon · `void_requested` Pengajuan void · `void_approved` Void disetujui · `void_rejected` Void ditolak · `price_changed` Harga diubah · `user_created` Pengguna dibuat · `user_updated` Pengguna diubah · `setting_changed` Pengaturan diubah.

### 3.13 Admin: Pengaturan `/admin/pengaturan`
Satu field: "Batas diskon kasir (%)" 0-100, tombol "Simpan".

## 4. Komponen bersama (`src/components/ui`)

`Button` (varian primary/secondary/danger, prop `loading`), `Card`, `Modal` (judul, isi, tutup dengan Esc dan klik latar), `Input` (label + pesan error), `MoneyInput` (menampilkan titik ribuan, mengembalikan integer), `Spinner`, `EmptyState`, `ErrorState` (dengan tombol "Coba lagi"), `Badge`, `Banner`. Buat sekali, pakai ulang; jangan menggandakan.
