# PRD: POS C'Bowl.id

**Versi:** 0.2 (diperbaiki dari 0.1; angka bertanda *asumsi* harus dikonfirmasi pemilik)
**Tanggal:** [isi tanggal]
**Tim:** [isi nama kelompok]

> Dokumen ini adalah **sumber kebenaran** untuk apa yang dibuat. Detail "bagaimana" ada di `ARCHITECTURE.md`, `BUSINESS_RULES.md`, `API.md`, `UI_SCREENS.md`, dan migrasi SQL. Jika dokumen bertentangan, urutan prioritas: **BUSINESS_RULES > PRD > API > UI_SCREENS**.

---

## 0. Perubahan dari v0.1

| # | Perubahan | Alasan |
|---|---|---|
| 1 | Ditambah **Keputusan Default (D-01..D-12)** | Tim tidak berhenti menunggu pemilik; semua bisa diubah lewat v0.3 |
| 2 | Setiap kebutuhan Must punya **kriteria penerimaan** yang bisa diuji | Agar "selesai" tidak ambigu |
| 3 | FR-20 dipecah: kasir **mengajukan** void (FR-20), admin **memproses antrean** (FR-29) | Alur void di v0.1 tidak punya layar untuk admin |
| 4 | Ditambah FR-30 (batas diskon), FR-31 (lihat shift), FR-32 (lihat log) | Log dan batas diskon tadinya dicatat tapi tidak bisa dilihat/diatur |
| 5 | Ditambah **matriks hak akses**, **status data**, **glosarium** | Mengurangi tebakan saat implementasi |
| 6 | Target kuantitatif diberi nilai awal (*asumsi*) | v0.1 hanya berisi `[x]` |
| 7 | Risiko ditambah: keterbatasan AI gratis, kesalahan hak akses | Relevan dengan cara pengembangan |
| 8 | Aturan uang, zona waktu, dan penomoran order dikunci | Sumber bug paling umum di POS |

## 1. Ringkasan Produk

POS C'Bowl.id adalah aplikasi web internal untuk satu outlet: mencatat penjualan, mengendalikan kas dan pembatalan (void), dan memberi laporan kepada pemilik. Pengguna: **kasir** dan **admin/pemilik**.

## 2. Latar Belakang dan Masalah

C'Bowl.id menjual tujuh rice bowl, menu pendamping, dan minuman (Rp28.000-Rp38.000). Tiap rice bowl mendapat satu pilihan sambal gratis. Pelanggan didominasi siswa, sehingga antrean menumpuk saat istirahat dan pulang sekolah. Pembayaran tunai dan QRIS.

| # | Hipotesis | Status |
|---|---|---|
| H1 | Input transaksi harus cepat dan terstruktur, termasuk sambal per porsi | [validasi Minggu 2] |
| H2 | Pesanan dari beberapa kanal perlu dicatat dan dibandingkan | [validasi] |
| H3 | Void, diskon, dan selisih kas perlu pengendalian dan jejak | [validasi] |
| H4 | Pemilik butuh laporan untuk evaluasi menu dan jam ramai | [validasi] |

## 3. Keputusan Default (bisa diubah setelah wawancara)

Tiap keputusan menjawab satu pertanyaan terbuka v0.1. Pengembangan **memakai nilai ini** sampai pemilik menjawab.

| ID | Keputusan | Menjawab |
|---|---|---|
| D-01 | Batas diskon kasir: **10%** dari subtotal. Di atas itu hanya admin yang boleh menginput. Nilai disimpan di tabel `app_settings` | Q1 |
| D-02 | QRIS hanya **dicatat sebagai metode bayar**. Tidak ada gambar QRIS dan tidak ada verifikasi otomatis | Q2 |
| D-03 | Struk **tampil di layar dan dicetak lewat browser** (`window.print()`, lebar 58 mm lewat CSS print). Printer thermal langsung = di luar lingkup | Q3 |
| D-04 | Perangkat utama: tablet/HP **landscape** dan laptop; internet seluler | Q4 |
| D-05 | Satu outlet; **satu shift terbuka per kasir** pada satu waktu | Q5 |
| D-06 | Laporan wajib harian: omzet, jumlah transaksi, per metode bayar, menu terlaris, jam ramai | Q6 |
| D-07 | **Tidak ada harga paket/promo otomatis** di v1. Potongan ditangani lewat diskon manual | Q7 |
| D-08 | Zona waktu **Asia/Jakarta (WIB)** untuk tanggal, nomor order, dan laporan | - |
| D-09 | Uang disimpan sebagai **bilangan bulat Rupiah**; tidak ada desimal, tidak ada pajak/service charge | - |
| D-10 | Satu baris keranjang = menu + sambal. Sambal berbeda berarti baris berbeda | - |
| D-11 | Void **tidak menghapus** data; order berstatus `void` dan dikeluarkan dari omzet | - |
| D-12 | Sambal gratis tidak mengubah harga dan tidak memengaruhi stok | - |

## 4. Tujuan dan Indikator Keberhasilan

| Tujuan | Indikator (*asumsi awal*) |
|---|---|
| Transaksi cepat dan akurat | Satu transaksi 2 item selesai ≤ **45 detik** pada UAT; salah input ≤ 5% |
| Kas dan void terkendali | 100% void punya alasan dan persetujuan admin; selisih kas tercatat tiap shift |
| Laporan membantu keputusan | Pemilik melihat omzet harian, menu terlaris, dan jam ramai **tanpa bantuan tim** |
| Layak dipakai | Skor kepuasan UAT ≥ **4 dari 5**; bug critical = 0 saat rilis |

## 5. Pengguna dan Hak Akses

| Persona | Deskripsi | Kebutuhan utama |
|---|---|---|
| **Kasir** | Operator harian, di bawah tekanan waktu | Layar sederhana, tombol besar, input cepat |
| **Admin/Pemilik** | Pengambil keputusan | Kontrol, laporan, kelola menu dan pengguna |

| Aksi | Kasir | Admin |
|---|:-:|:-:|
| Login/logout | ✅ | ✅ |
| Buka/tutup shift sendiri | ✅ | ✅ |
| Buat transaksi (butuh shift terbuka) | ✅ | ✅ |
| Lihat riwayat | milik sendiri | semua |
| Ajukan void | ✅ (order sendiri) | ✅ |
| Setujui/tolak void | ❌ | ✅ |
| Diskon sampai batas (D-01) | ✅ | ✅ |
| Diskon di atas batas | ❌ | ✅ |
| Kelola menu, kategori, sambal | ❌ | ✅ |
| Kelola pengguna dan batas diskon | ❌ | ✅ |
| Laporan dan log aktivitas | ❌ | ✅ |

## 6. Ruang Lingkup

**In-scope:** autentikasi dan role, data master, transaksi kasir, pencatatan kanal, pembayaran tunai dan QRIS (dicatat), struk, void dan diskon dengan otorisasi, shift dan rekap kas, laporan, log aktivitas.

**Out-of-scope:** pre-order dan web pelanggan, bazar/event, integrasi API platform lain, payment gateway otomatis, aplikasi native, multi-cabang, akuntansi penuh, mode offline penuh, stok bahan berbasis resep, harga paket otomatis, printer thermal langsung, pajak/service charge, refund parsial, edit transaksi yang sudah dibayar.

## 7. Kebutuhan Fungsional

MoSCoW: **M** Must, **S** Should, **C** Could. Kolom terakhir adalah **kriteria penerimaan**: kebutuhan dianggap selesai bila semuanya benar.

| ID | Kebutuhan | P | Kriteria penerimaan |
|---|---|:-:|---|
| **Autentikasi dan pengguna** | | | |
| FR-01 | Pengguna dapat login dan logout | M | Email+password benar → masuk; salah → pesan "Email atau password salah"; logout mengembalikan ke `/login`; halaman lain tanpa login → redirect `/login` |
| FR-02 | Sistem membedakan role kasir dan admin | M | Kasir membuka `/admin/*` → ditolak (redirect + 403 di API); menu navigasi menyesuaikan role |
| FR-03 | Admin menambah, mengubah, menonaktifkan pengguna | M | Pengguna nonaktif tidak bisa login/transaksi; tidak ada tombol hapus; admin tidak bisa menonaktifkan dirinya sendiri |
| **Data master** | | | |
| FR-04 | Admin mengelola kategori dan menu (nama, harga, ketersediaan) | M | Harga bilangan bulat ≥ 0; menu "nonaktif" tidak tampil di mana pun; perubahan harga tercatat di log (FR-22) |
| FR-05 | Admin mengelola sambal dan ketersediaannya | M | Sambal tidak tersedia tidak muncul di pilihan kasir |
| FR-06 | Menu tidak tersedia tidak tampil di layar kasir | M | Menu `is_available=false` atau `is_active=false` tidak ada di grid kasir |
| **Shift** | | | |
| FR-07 | Kasir membuka shift dengan kas awal | M | Kas awal ≥ 0; tidak bisa membuka shift kedua saat satu masih terbuka |
| FR-08 | Transaksi hanya saat ada shift terbuka | M | Tanpa shift: halaman kasir menampilkan ajakan "Buka shift"; API menolak dengan pesan jelas |
| FR-09 | Kasir menutup shift; sistem hitung selisih dan tampilkan rekap | M | Kas seharusnya = kas awal + total transaksi **tunai berstatus paid** pada shift; selisih = kas hitung − kas seharusnya; rekap menampilkan jumlah order, tunai, QRIS, void |
| **Transaksi** | | | |
| FR-10 | Pilih menu, atur jumlah, lihat keranjang | M | Tambah, kurang, hapus baris; jumlah 1-99; total berubah langsung |
| FR-11 | Rice bowl wajib satu pilihan sambal | M | Tombol bayar nonaktif bila ada rice bowl tanpa sambal; server juga menolak |
| FR-12 | Pilih tipe pesanan (dine-in/takeaway) | M | Wajib dipilih; default `dine_in` |
| FR-13 | Tandai kanal (langsung, WhatsApp, GoFood, GrabFood) | S | Default `direct`; tersimpan di order |
| FR-14 | Hitung subtotal dan total otomatis | M | total = Σ(harga × jumlah) − diskon; dihitung ulang di server, bukan dipercaya dari klien |
| FR-15 | Tunai: input uang diterima, hitung kembalian | M | Uang diterima < total → ditolak; kembalian = diterima − total; tersedia tombol nominal cepat (uang pas, 50.000, 100.000) |
| FR-16 | QRIS: catat metode bayar | M | Tidak ada input uang diterima |
| FR-17 | Nomor order berurutan per hari | M | Mulai 1 setiap tanggal WIB baru; tidak ada nomor ganda walau dua kasir menyimpan bersamaan |
| FR-18 | Struk tampil dan bisa dicetak lewat browser | M | Isi struk sesuai `BUSINESS_RULES.md` §8; tombol Cetak membuka dialog print; ukuran 58 mm |
| FR-19 | Kasir melihat riwayat transaksinya | S | Daftar order shift/hari ini milik sendiri; bisa buka struk dan ajukan void |
| **Pengendalian** | | | |
| FR-20 | Kasir mengajukan void order yang sudah dibayar | M | Wajib alasan ≥ 5 karakter; hanya order berstatus paid; satu permintaan pending per order |
| FR-29 | Admin menyetujui/menolak void pada antrean | M | Disetujui → status order `void`, keluar dari omzet; ditolak → order tetap paid; keduanya tercatat |
| FR-21 | Diskon dicatat dengan alasan | S | Diskon > 0 wajib alasan ≥ 3 karakter; ≤ subtotal |
| FR-30 | Admin mengatur batas diskon kasir | S | Ubah persen di layar pengaturan; berlaku untuk transaksi berikutnya |
| FR-22 | Void, diskon, perubahan harga tercatat di log | M | Setiap peristiwa menghasilkan satu baris log: siapa, kapan, apa, detail |
| FR-32 | Admin melihat log aktivitas | M | Daftar terbaru dulu, bisa filter jenis aksi |
| **Laporan** | | | |
| FR-23 | Laporan penjualan harian | M | Omzet, jumlah transaksi, per metode bayar, total diskon, jumlah void; order void **tidak** masuk omzet |
| FR-24 | Menu terlaris | S | Urut jumlah terjual, rentang tanggal bisa dipilih |
| FR-25 | Jam ramai | S | Jumlah transaksi per jam (WIB) |
| FR-26 | Perbandingan per kanal | S | Jumlah order dan omzet per kanal |
| FR-31 | Admin melihat daftar shift beserta selisih kas | S | Per tanggal; menampilkan kasir, kas awal, seharusnya, hitung, selisih |
| FR-27 | Ekspor laporan ke Excel/PDF | C | Setidaknya CSV |
| FR-28 | Stok bahan sederhana | C | Ditunda; tidak dikerjakan sebelum semua M dan S selesai |

## 8. Kebutuhan Non-Fungsional

Target adalah *asumsi awal*, diukur saat UAT.

| ID | Kategori | Kebutuhan |
|---|---|---|
| NFR-01 | Performa | Halaman kasir tampil ≤ 3 dtk pada 4G normal; simpan transaksi ≤ 2 dtk |
| NFR-02 | Usability | Transaksi 1 item tunai ≤ 6 ketukan; area ketuk ≥ 44×44 px; nyaman di tablet dan HP |
| NFR-03 | Keamanan | Password dikelola Supabase Auth; RLS aktif di semua tabel; kunci `service_role` hanya di server; tidak ada rahasia di kode klien atau repo |
| NFR-04 | Integritas data | Nama dan harga menu di-snapshot di `order_items`; order tidak dapat dihapus (diblokir trigger DB); operasi bernilai uang dilakukan atomik di fungsi database |
| NFR-05 | Ketersediaan | Dapat diakses lewat tautan publik selama jam operasional dan masa UAT |
| NFR-06 | Kompatibilitas | Chrome, Edge, Safari versi terbaru |
| NFR-07 | Auditabilitas | Setiap perubahan penting punya jejak siapa, kapan, apa; log tidak bisa diubah/dihapus |
| NFR-08 | Pemeliharaan | Kode di GitHub, satu commit per tugas, dokumentasi dalam repo |

## 9. Alur Pengguna Utama

**Transaksi:** login → buka shift → pilih menu → (rice bowl: pilih sambal) → atur jumlah → pilih tipe dan kanal → pilih pembayaran (tunai: input uang) → simpan → struk.

**Void:** kasir buka riwayat → pilih order → ajukan void + alasan → status *pending* → admin melihat antrean → setuju/tolak → status order dan log diperbarui.

**Tutup shift:** kasir hitung kas fisik → input jumlah → sistem membandingkan → rekap tersimpan dan ditampilkan → shift berstatus closed.

## 10. Arsitektur dan Teknologi

Next.js (App Router, TypeScript, Tailwind) di Vercel, Supabase (Postgres, Auth, RLS), GitHub. Logika yang menyentuh uang dan kas (buat order, void, shift) ada di **fungsi Postgres** agar atomik dan tidak bergantung pada ketelitian kode klien. Detail: `ARCHITECTURE.md`.

## 11. Asumsi, Dependensi, Risiko

| Jenis | Isi | Mitigasi |
|---|---|---|
| Asumsi | Pemilik memberi waktu wawancara dan data | Konfirmasi minggu pertama |
| Asumsi | Perangkat kasir tersedia dan ada internet | Tanyakan perangkat dan koneksi |
| Dependensi | Paket gratis Vercel dan Supabase | Cek batas dan ketentuan terbaru |
| Risiko | Proyek Supabase gratis di-pause saat tidak aktif | Buka rutin; cek sehari sebelum demo |
| Risiko | Cakupan membengkak | Kunci fitur Must; Could baru setelah semua M dan S selesai |
| Risiko | Data riil sulit didapat | UAT dengan data uji yang disepakati |
| Risiko | Gangguan operasional bila error | Uji bertahap; tidak menggantikan alur pemilik tanpa persetujuan |
| Risiko | **AI agent gratis keluar jalur** (menambah fitur, mengubah file lain, mengarang API) | `AGENTS.md`, tugas kecil di `TASKS.md`, commit per tugas, review diff sebelum commit |
| Risiko | **Kebocoran hak akses** (kasir mengakses data admin) | RLS + cek role di API + uji manual di `TASKS.md` T-62 |
| Risiko | Salah hitung uang | Hitung di server/DB, uang integer, uji dengan contoh di `BUSINESS_RULES.md` §9 |

## 12. Rencana Rilis

| Minggu | Tahap | Hasil | Tugas (`TASKS.md`) |
|---|---|---|---|
| 1-3 | Inisiasi, kebutuhan, desain | Proposal, dokumen kebutuhan, desain sistem | - |
| 4 | Sprint 1 | Login, role, data master | S0, S1 |
| 5 | Sprint 2 | Shift dan transaksi inti | S2 |
| 6 | Sprint 3 | Void, diskon, kanal, log | S3 |
| 7 | Sprint 4 | Tutup shift, rekap kas (beta 1) | S4 |
| 8 | Sprint 5 | Laporan (beta 2) | S5 |
| 9 | Sprint 6 | Feature complete, UAT awal | S6 |
| 10-12 | Testing, deployment, UAT | Dokumen uji, pilot, dokumen UAT | S6 |
| 13-14 | Dokumentasi dan presentasi | Aplikasi final dan laporan | - |

## 13. Pertanyaan Terbuka untuk Pemilik

Jawaban akan menggantikan Keputusan Default yang bersangkutan (kolom "Menjawab" di §3).

1. Berapa batas diskon yang boleh diberikan kasir sendiri? (D-01)
2. QRIS cukup dicatat, atau perlu menampilkan gambar QRIS toko? (D-02)
3. Format struk: layar, cetak biasa, atau printer thermal? (D-03)
4. Perangkat kasir dan kualitas internet di lokasi? (D-04)
5. Berapa kasir dan bagaimana pembagian shift? (D-05)
6. Laporan apa yang paling dibutuhkan setiap hari? (D-06)
7. Ada paket atau harga khusus (mis. rice bowl + minuman)? (D-07)
8. Apakah ada biaya tambahan (pajak, kemasan) yang harus tampil di struk?
9. Apakah kasir boleh melihat omzet total, atau hanya milik sendiri?

## 14. Glosarium

| Istilah | Arti |
|---|---|
| Order | Satu transaksi penjualan yang sudah dibayar |
| Shift | Periode kerja satu kasir, dari buka (kas awal) sampai tutup (kas hitung) |
| Void | Pembatalan order yang sudah dibayar; data tetap ada, status jadi `void` |
| Kanal | Asal pesanan: `direct`, `whatsapp`, `gofood`, `grabfood` |
| Snapshot | Salinan nama dan harga menu saat transaksi, tidak berubah walau menu diubah |
| RLS | Row Level Security: aturan akses per baris di database |
| RPC | Pemanggilan fungsi Postgres dari aplikasi (`supabase.rpc(...)`) |

## 15. Riwayat Dokumen

| Versi | Tanggal | Perubahan | Penulis |
|---|---|---|---|
| 0.1 | [ ] | Draft awal | [ ] |
| 0.2 | [ ] | Keputusan default, kriteria penerimaan, FR baru, hak akses, glosarium | [ ] |

**Catatan:** nilai `[ ]` diisi tim. Versi 0.3 dibuat setelah wawancara pemilik: hipotesis H1-H4 diberi status "terbukti / ditolak / diubah", dan §3 diperbarui.
