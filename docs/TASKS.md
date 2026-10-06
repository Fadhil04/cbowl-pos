# TASKS.md: Daftar Tugas Kecil

Aturan pakai: kerjakan **satu tugas per sesi chat**, berurutan. Setelah "Selesai jika" lolos uji manual → commit → centang ☐ jadi ☑ → sesi baru untuk tugas berikutnya.

Singkatan: **BR** = `BUSINESS_RULES.md`, **API** = `API.md`, **UI** = `UI_SCREENS.md`, **ARS** = `ARCHITECTURE.md`. Tugas bertanda 🧑 dikerjakan **manusia**, bukan agent.

---

## Sprint 0: Persiapan

☐ **T-00 🧑 Buat proyek dan repo**
Jalankan perintah di ARS §1, buat repo GitHub, salin folder `docs/`, `supabase/`, `AGENTS.md` ke proyek, buat `.env.example` (isi dari README paket ini), pastikan `.env.local` ada di `.gitignore`.
Selesai jika: `npm run dev` menampilkan halaman awal Next.js; repo ter-push.

☐ **T-01 🧑 Siapkan Supabase**
Buat proyek Supabase. Di SQL Editor jalankan berurutan: `0001_init.sql`, `0002_reports.sql`, `seed.sql`. Buat admin pertama (instruksi di akhir `seed.sql`). Salin URL dan anon key ke `.env.local`; service role key juga (rahasia).
Selesai jika: tabel terlihat di Table Editor; `profiles` berisi 1 admin; menu contoh ada. Bila SQL error, kirim pesan error ke agent/pengguna lain untuk diperbaiki **sebelum** lanjut.

☐ **T-02 Util dasar**
Baca: ARS §3-§8, AGENTS.md. Buat: `src/lib/supabase/{client,server,admin}.ts`, `src/lib/{api,auth,api-client,format,constants}.ts`, `middleware.ts` (salin persis dari ARS). `constants.ts` berisi `OUTLET_NAME = "C'Bowl.id"`, `OUTLET_ADDRESS = "[isi alamat]"`, dan label Indonesia untuk kanal dan tipe pesanan.
Selesai jika: `npm run build` bersih; tidak ada error TypeScript.

☐ **T-03 Tipe database** 🧑
Jalankan perintah di ARS §9 untuk membuat `src/types/database.ts`. Opsional: agent menambahkan generic `Database` ke tiga klien Supabase.
Selesai jika: file ada dan `npm run build` tetap bersih.

---

## Sprint 1: Login, role, data master

☐ **T-10 Login dan logout**
Baca: PRD FR-01, UI §3.1, ARS §4. Buat `src/app/login/page.tsx` (klien: `supabase.auth.signInWithPassword`), tombol "Keluar" di navigasi (`signOut` lalu ke `/login`), dan `src/app/(app)/page.tsx` yang mengarahkan sesuai role (admin→`/admin/menu`, kasir→`/kasir`).
Selesai jika: login benar masuk; salah → "Email atau password salah"; tanpa login membuka `/kasir` → ke `/login`; keluar → `/login`; akun `is_active=false` ditolak dengan pesan di UI §3.1.

☐ **T-11 Layout aplikasi dan navigasi per role**
Baca: UI §2, ARS §8. Buat `src/app/(app)/layout.tsx` (Server Component: ambil profil, tampilkan nama + role, menu sesuai role) dan `src/app/(app)/admin/layout.tsx` (salin dari ARS §8). Buat halaman kosong sementara untuk setiap rute di ARS §3 dengan judul saja.
Selesai jika: kasir tidak melihat menu admin; kasir mengetik `/admin/menu` → dialihkan ke `/kasir`; admin melihat semua menu.

☐ **T-12 Kelola pengguna**
Baca: PRD FR-02, FR-03; API §6; UI §3.8. Buat route `/api/admin/users` (GET, POST), `/api/admin/users/[id]` (PATCH), skema zod di `lib/validators/user.ts`, komponen UI dasar yang dibutuhkan (`Button`, `Modal`, `Input`, `Spinner`, `EmptyState`, `ErrorState`, `Badge`, `Banner`), dan halaman `/admin/pengguna`.
Selesai jika: admin membuat kasir baru dan kasir itu bisa login; menonaktifkan kasir → tidak bisa login; admin tidak bisa menonaktifkan dirinya sendiri; kasir yang memanggil `/api/admin/users` mendapat 403.

☐ **T-13 Kategori dan menu**
Baca: PRD FR-04, FR-06; BR §2; API §5; UI §3.6. Buat route `/api/admin/categories`, `/api/admin/menu-items` (+`[id]`), validator, halaman `/admin/menu`, dan `MoneyInput`.
Selesai jika: tambah menu "Rice Bowl X" 30.000; ubah harga → muncul baris di tabel `activity_logs` (cek di Supabase); toggle "Tersedia" bekerja; harga negatif atau desimal ditolak.

☐ **T-14 Pilihan sambal**
Baca: PRD FR-05; API §5; UI §3.7. Buat route `/api/admin/sambals` (+`[id]`) dan halaman `/admin/sambal`.
Selesai jika: tambah, ubah nama, dan nonaktifkan "Tersedia" bekerja.

---

## Sprint 2: Shift dan transaksi inti

☐ **T-20 API menu untuk kasir**
Baca: API §1. Buat `/api/menu`.
Selesai jika: respons sesuai contoh API §1; menu `is_available=false` tidak ada di respons; kasir bisa memanggilnya.

☐ **T-21 Buka shift**
Baca: PRD FR-07, FR-08; BR §3; API §2; UI §3.2. Buat route `/api/shifts/current`, `/api/shifts/open`, halaman `/kasir/shift` (hanya bagian buka shift dulu).
Selesai jika: kasir membuka shift dengan kas awal 100.000; membuka lagi → pesan "Masih ada shift yang terbuka"; kas awal negatif ditolak.

☐ **T-22 Layar kasir: menu dan keranjang (belum menyimpan)**
Baca: PRD FR-10, FR-14; BR §2 (BR-14, BR-15); UI §3.3 (hingga keranjang). Buat `/kasir/page.tsx` (cek shift; bila tidak ada tampilkan ajakan buka shift), komponen `MenuGrid`, `Cart`, tipe `CartLine` di `types/app.ts`, hook state keranjang di `components/pos/use-cart.ts` (`useReducer`: add, increment, decrement, remove, clear).
Selesai jika: tab kategori berganti; ketuk menu menambah ke keranjang; jumlah dan subtotal benar sesuai contoh BR §9 (C1 subtotal 36.000); tanpa shift terbuka layar menu tidak muncul.

☐ **T-23 Pilih sambal untuk rice bowl**
Baca: PRD FR-11; BR-10, BR-11, BR-14; UI §3.3 (modal sambal). Buat `SambalPicker` (modal) dan hubungkan: menambah item dari kategori `requires_sambal` membuka modal; hasilnya masuk keranjang dengan `sambal_option_id`.
Selesai jika: rice bowl yang sama dengan sambal berbeda menjadi 2 baris; sambal sama menambah jumlah; menu non-rice-bowl tidak meminta sambal.

☐ **T-24 Panel pembayaran (belum menyimpan)**
Baca: PRD FR-12, FR-13, FR-15, FR-16; BR-34; UI §3.3 (panel pembayaran). Buat `PaymentPanel` (modal): tipe, kanal, metode, input uang diterima (`MoneyInput`), tombol cepat, kembalian. Tombol "Simpan Transaksi" untuk sementara hanya menutup modal (belum menyimpan apa pun; disambung ke API di T-25).
Selesai jika: contoh BR §9 C1 (tunai 50.000 → kembali 14.000) dan C6 (tunai kurang → tombol nonaktif + tulisan "Kurang") sesuai.

☐ **T-25 Simpan order**
Baca: PRD FR-14, FR-17; BR §4; API §3 (POST /api/orders). Buat `/api/orders` (POST) dengan zod, sambungkan `PaymentPanel` ke API (hanya mengirim `menu_item_id`, `quantity`, `sambal_option_id`, tidak mengirim harga).
Selesai jika: transaksi tersimpan di tabel `orders` dan `order_items` dengan snapshot nama/harga; nomor order 1 lalu 2 dst pada hari yang sama; dua tab browser menyimpan hampir bersamaan tidak menghasilkan nomor ganda; klik ganda tombol hanya membuat satu order; setelah sukses keranjang kosong.

☐ **T-26 Struk**
Baca: PRD FR-18; BR §8; API §3 (GET /api/orders/[id]); UI §3.4. Buat `/api/orders/[id]` (GET), `Receipt` (komponen), halaman `/struk/[id]`, CSS print 58 mm. Setelah T-25 sukses → pindah ke struk.
Selesai jika: isi struk sama dengan contoh BR §8; tombol Cetak membuka dialog print dan pratinjau tidak menampilkan navigasi/tombol; QRIS menampilkan "QRIS" tanpa kembalian.

---

## Sprint 3: Riwayat, void, diskon, log

☐ **T-30 Riwayat transaksi**
Baca: PRD FR-19; API §3 (GET /api/orders); UI §3.5. Buat `/api/orders` (GET), halaman `/riwayat`.
Selesai jika: kasir A tidak melihat order kasir B; admin melihat semua; urutan terbaru dulu; ketuk baris → struk.

☐ **T-31 Ajukan void**
Baca: PRD FR-20; BR §6; API §3 (void-request); UI §3.5 (modal void). Buat `/api/orders/[id]/void-request`, modal ajukan void di struk dan riwayat, badge "Menunggu void".
Selesai jika: alasan < 5 karakter ditolak; pengajuan kedua pada order yang sama ditolak; kasir tidak bisa mengajukan void order kasir lain; muncul log `void_requested`.

☐ **T-32 Antrean void admin**
Baca: PRD FR-29; BR-53..BR-55; API §4; UI §3.9. Buat `/api/admin/void-requests` (GET), `/api/admin/void-requests/[id]/decide` (POST), halaman `/admin/void`.
Selesai jika: setuju → order berstatus VOID di riwayat dan struk; tolak → order tetap paid; kasir tidak bisa memanggil endpoint (403); log `void_approved`/`void_rejected` tercatat; keputusan kedua pada pengajuan yang sama ditolak.

☐ **T-33 Diskon**
Baca: PRD FR-21, FR-30; BR §5; API §7; UI §3.3 (bagian diskon), §3.13. Tambahkan bagian diskon di `PaymentPanel`; buat `/api/admin/settings` (GET, PATCH) dan halaman `/admin/pengaturan`.
Selesai jika: contoh BR §9 C3 lolos untuk kasir, C4 ditolak untuk kasir tetapi lolos untuk admin; tanpa alasan ditolak; total di struk memuat baris diskon; ubah batas jadi 5% → C3 sekarang ditolak untuk kasir.

☐ **T-34 Log aktivitas**
Baca: PRD FR-22, FR-32; BR §7; API §9; UI §3.12. Buat `/api/admin/logs` (GET), halaman `/admin/log` dengan filter dan "Muat lebih banyak".
Selesai jika: log dari T-13, T-31, T-32, T-33 tampil dengan label Indonesia; kasir tidak bisa mengakses.

---

## Sprint 4: Tutup shift

☐ **T-40 Tutup shift dan rekap**
Baca: PRD FR-09; BR §3 dan contoh shift di BR §9; API §2; UI §3.2. Buat `/api/shifts/summary` (GET), `/api/shifts/close` (POST), lengkapi `/kasir/shift` (ringkasan, input kas hitung, modal konfirmasi, rekap).
Selesai jika: contoh shift di BR §9 menghasilkan selisih −2.000; setelah tutup, kasir tidak bisa membuat order sebelum membuka shift baru; menutup dua kali ditolak.

☐ **T-41 Admin: daftar shift**
Baca: PRD FR-31; API §2 (admin/shifts); UI §3.10. Buat `/api/admin/shifts` (GET) dan halaman `/admin/shift`.
Selesai jika: shift tampil dengan selisih berwarna; shift terbuka ditandai "Berjalan".

---

## Sprint 5: Laporan

☐ **T-50 Laporan: ringkasan harian**
Baca: PRD FR-23; BR-55; API §8 (daily); UI §3.11. Buat `/api/admin/reports/daily`, halaman `/admin/laporan` (pemilih tanggal + kartu ringkasan + tabel per tanggal).
Selesai jika: omzet sama dengan penjumlahan manual; order void tidak masuk omzet tetapi masuk "Void"; kasir mendapat 403.

☐ **T-51 Laporan: menu terlaris**
Baca: PRD FR-24; API §8 (top-items). Tambahkan bagian di halaman laporan.
Selesai jika: urutan sesuai jumlah terjual; order void tidak dihitung.

☐ **T-52 Laporan: jam ramai**
Baca: PRD FR-25; API §8 (peak-hours); UI §3.11. Tambahkan bagian tabel + batang `div`.
Selesai jika: jam sesuai WIB (bukan UTC): order yang dibuat pukul 12:xx WIB muncul di baris 12.

☐ **T-53 Laporan: per kanal**
Baca: PRD FR-26; API §8 (by-channel).
Selesai jika: order GoFood dan langsung terpisah dengan benar.

☐ **T-54 (Could) Ekspor CSV**
Baca: PRD FR-27. Tombol "Unduh CSV" di laporan harian, dibuat di sisi klien dari data yang sudah dimuat (tanpa paket baru).
Selesai jika: file terbuka di Excel dengan kolom benar. Kerjakan hanya bila semua tugas M dan S selesai.

---

## Sprint 6: Penyempurnaan, uji, rilis

☐ **T-60 Poles UX kasir**
Baca: UI §1. Periksa semua layar: tiga keadaan, ukuran tombol 44 px, teks Indonesia, tampilan HP (375 px) dan tablet landscape (1024 px), tombol nonaktif saat menyimpan.
Selesai jika: tidak ada layar yang meluber horizontal di 375 px; semua daftar punya keadaan kosong.

☐ **T-61 Bersih-bersih kode**
Hapus kode mati, `console.log`, komponen ganda; jalankan `npm run lint` bersih; pastikan `README.md` proyek menjelaskan cara menjalankan.
Selesai jika: lint dan build bersih; `git grep "console.log"` tidak menemukan apa pun di `src/`.

☐ **T-62 🧑 Uji manual akhir (checklist UAT teknis)**
Lakukan semua dengan dua akun (kasir A, kasir B) dan satu admin:
1. Kasir membuka `/admin/menu` dan memanggil `/api/admin/users` → ditolak.
2. Kasir A tidak melihat order kasir B di riwayat.
3. Semua contoh BR §9 (C1-C6 dan contoh shift) menghasilkan angka yang tepat.
4. Order tidak bisa dihapus: di Supabase SQL Editor jalankan `delete from orders;` → error "Data ini tidak boleh dihapus".
5. Alur void lengkap: ajukan, setujui, cek omzet turun, cek log.
6. Akun nonaktif tidak bisa login dan tidak bisa memanggil API.
7. Tutup tab saat menyimpan order lalu cek tidak ada order setengah jadi (order tanpa item).
8. Cetak struk dari HP dan laptop.
Selesai jika: semua poin lolos; catat hasil di dokumen uji.

☐ **T-63 🧑 Deploy ke Vercel**
Impor repo di Vercel, isi tiga variabel lingkungan, deploy. Di Supabase → Authentication → URL Configuration, isi Site URL dengan domain Vercel.
Selesai jika: login dan satu transaksi penuh berhasil dari tautan publik di HP.

☐ **T-64 🧑 UAT dengan pemilik**
Jalankan skenario nyata dengan pemilik/kasir, catat temuan, perbarui PRD ke v0.3 (jawaban pertanyaan terbuka), buat tugas perbaikan baru bernomor T-7x dengan format yang sama.
