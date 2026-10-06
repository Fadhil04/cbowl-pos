# BUSINESS_RULES.md

Aturan di sini **mengalahkan** dokumen lain. Agent: jangan mengubah aturan ini; jangan menafsirkan sendiri. Jika ada yang tidak jelas, tanyakan.

## 1. Uang dan waktu

- BR-01 Semua uang adalah **integer Rupiah** (28000, bukan 28.000 atau 28000.00). Dilarang memakai `float`, `parseFloat`, atau `toFixed` untuk uang.
- BR-02 Tampilan: `Rp28.000` lewat `formatRupiah()` di `src/lib/format.ts`. Input angka dibersihkan dari titik dan non-digit sebelum dikirim.
- BR-03 Zona waktu bisnis: **Asia/Jakarta**. "Hari ini" = tanggal WIB, bukan UTC. Di database disimpan `timestamptz`; kolom `order_date` diisi dari WIB.
- BR-04 Tidak ada pajak, service charge, atau pembulatan.

## 2. Menu dan sambal

- BR-10 Kategori punya flag `requires_sambal`. Kategori "Rice Bowl" bernilai `true`; lainnya `false`.
- BR-11 Item dari kategori `requires_sambal=true` **wajib** punya tepat satu sambal. Item lain tidak boleh punya sambal.
- BR-12 Sambal gratis: tidak menambah harga.
- BR-13 Menu tampil di kasir hanya jika `is_active = true` **dan** `is_available = true`. `is_active=false` berarti "dihapus" (soft delete); menu tidak pernah dihapus permanen.
- BR-14 Satu baris keranjang = (menu, sambal). Menu sama + sambal sama → menambah jumlah. Sambal beda → baris baru.
- BR-15 Jumlah per baris: bilangan bulat 1-99.

## 3. Shift

- BR-20 Kasir hanya boleh punya **satu** shift berstatus `open`.
- BR-21 Order hanya bisa dibuat jika kasir punya shift `open`; order menempel pada shift itu.
- BR-22 Kas seharusnya = `opening_cash` + Σ `total` order **tunai** berstatus `paid` pada shift.
- BR-23 Selisih = `counted_cash` − `expected_cash`. Positif = lebih, negatif = kurang. Disimpan apa adanya, tidak dikoreksi.
- BR-24 Shift `closed` tidak bisa dibuka lagi. Shift tidak bisa ditutup dua kali.
- BR-25 Angka `expected_cash` dan `cash_difference` dibekukan saat tutup shift. Void yang disetujui **setelah** shift ditutup tidak mengubah angka beku, tetapi tercatat di log.

## 4. Order

- BR-30 Order dibuat hanya lewat fungsi database `create_order`. Klien tidak boleh `insert` langsung ke `orders` atau `order_items`.
- BR-31 Server menghitung ulang harga dari tabel `menu_items`. Harga dari klien **diabaikan**.
- BR-32 `subtotal = Σ(unit_price × quantity)`; `total = subtotal − discount_amount`.
- BR-33 Nomor order: urut per tanggal WIB, mulai 1. Format tampil: `#001` (tiga digit, bertambah bila lebih dari 999).
- BR-34 Tunai: `cash_received ≥ total`; `change_amount = cash_received − total`. QRIS: `cash_received` dan `change_amount` kosong.
- BR-35 Order tidak pernah diedit atau dihapus. Satu-satunya perubahan: status `paid → void` lewat persetujuan void.
- BR-36 Tipe: `dine_in` atau `takeaway`. Kanal: `direct`, `whatsapp`, `gofood`, `grabfood`. Default kanal `direct`.

## 5. Diskon

- BR-40 Diskon dalam **Rupiah** (bukan persen) di tingkat order, `0 ≤ diskon ≤ subtotal`.
- BR-41 Diskon > 0 wajib alasan (≥ 3 karakter).
- BR-42 Batas kasir: `diskon × 100 ≤ subtotal × discount_cashier_max_percent` (default 10, tabel `app_settings`). Di atas batas → hanya role admin yang boleh. Kasir yang mencoba mendapat pesan: "Diskon melebihi batas kasir. Minta admin."
- BR-43 Setiap diskon > 0 menghasilkan log `discount_applied`.

## 6. Void

Status permintaan: `pending → approved | rejected`. Status order: `paid → void`.

- BR-50 Hanya order `paid` yang dapat diajukan void.
- BR-51 Kasir hanya bisa mengajukan untuk order miliknya; admin untuk semua.
- BR-52 Alasan wajib (≥ 5 karakter). Satu order hanya boleh punya **satu** permintaan `pending`.
- BR-53 Hanya admin yang memutuskan. Admin boleh memutuskan permintaannya sendiri.
- BR-54 Disetujui → `orders.status='void'`, `voided_at` terisi, log `void_approved`. Ditolak → order tetap `paid`, log `void_rejected`. Order `void` tidak bisa diajukan lagi.
- BR-55 Order `void` **tidak** dihitung di omzet, laporan metode bayar, menu terlaris, maupun kas seharusnya. Order `void` tetap tampil di riwayat dengan label "VOID" dan dihitung di "jumlah void".

## 7. Log aktivitas

Aksi yang wajib dicatat (`activity_logs.action`):

`shift_opened`, `shift_closed`, `discount_applied`, `void_requested`, `void_approved`, `void_rejected`, `price_changed`, `user_created`, `user_updated`, `setting_changed`.

Log: hanya ditulis oleh fungsi/trigger database, tidak bisa diubah/dihapus, hanya admin yang bisa membaca.

## 8. Isi struk (58 mm)

```
        C'BOWL.ID
   (alamat outlet - dari konstanta di src/lib/constants.ts)
--------------------------------
No: #012          06/10/2026 12:41
Kasir: Sari       Dine-in
Kanal: Langsung
--------------------------------
Rice Bowl Contoh 1
  Sambal Matah
  2 x 28.000            56.000
Es Teh
  1 x 8.000              8.000
--------------------------------
Subtotal                64.000
Diskon (alasan)         -5.000
TOTAL                   59.000
Tunai                   60.000
Kembali                  1.000
--------------------------------
     Terima kasih!
```
Bila status `void`, tampilkan banner "VOID" di atas. QRIS: ganti baris Tunai/Kembali dengan "QRIS".

## 9. Contoh hitungan (dipakai sebagai uji manual)

Menu: Rice Bowl A 28.000; Rice Bowl B 38.000; Es Teh 8.000.

| Kasus | Keranjang | Diskon | Total | Bayar | Hasil |
|---|---|---|---|---|---|
| C1 | 1×A + 1×Es Teh | 0 | 36.000 | tunai 50.000 | kembali 14.000 |
| C2 | 2×B (sambal sama) | 0 | 76.000 | tunai 76.000 | kembali 0 |
| C3 | 1×A | 2.800 | 25.200 | QRIS | tanpa kembalian; kasir lolos (tepat 10%) |
| C4 | 1×A | 2.801 | - | - | **ditolak** untuk kasir (di atas 10%); admin boleh |
| C5 | 1×A tanpa sambal | 0 | - | - | **ditolak** (sambal wajib) |
| C6 | 1×A | 0 | 28.000 | tunai 20.000 | **ditolak** (uang kurang) |

Contoh shift: kas awal 100.000; dua order tunai 36.000 + 76.000; satu order QRIS 25.200; kas dihitung 210.000 → seharusnya 212.000, selisih **−2.000**. Bila order 76.000 di-void sebelum tutup shift → seharusnya 136.000.

## 10. Hak akses ringkas

Lihat matriks di `PRD.md` §5. Penegakan **ganda**: (1) RLS dan pengecekan di fungsi database, (2) `requireUser()` di API, (3) redirect di UI. UI saja tidak cukup.
