# PROMPT_TEMPLATES.md: Prompt Siap Pakai untuk Agent Gratisan

Model gratis punya konteks pendek dan mudah "lupa" atau mengarang. Strateginya: **tugas kecil, konteks sedikit, satu sesi per tugas, commit sering.**

## Aturan emas

1. **Satu tugas = satu sesi chat baru.** Jangan melanjutkan chat panjang; kualitas turun seiring panjang chat.
2. **Sebut ID tugas dan file yang harus dibaca.** Jangan menyuruh "baca semua dokumen".
3. **Commit sebelum dan sesudah** setiap tugas. Hasil buruk? `git restore .` lalu ulangi dengan prompt lebih jelas.
4. **Periksa diff** (`git diff`) sebelum commit: apakah ada file di luar tugas yang berubah? Jika ya, batalkan file itu.
5. **Tempel error apa adanya** (teks lengkap), bukan ringkasan.
6. Bila model berulang kali gagal pada satu tugas, **pecah tugas itu jadi dua** (tulis sendiri di `TASKS.md` dengan nomor T-xxa, T-xxb).

---

## A. Memulai tugas (paling sering dipakai)

```
Baca AGENTS.md. Lalu kerjakan tugas T-__ di docs/TASKS.md.
Baca hanya file yang tertulis di bagian "Baca" pada tugas itu.
Tulis rencana maksimal 5 baris dulu, lalu kerjakan.
Jangan mengerjakan tugas lain. Setelah selesai, jalankan npm run lint dan npm run build,
lalu laporkan dengan format di AGENTS.md §1 langkah 6.
```

## B. Bila tool tidak bisa membaca file otomatis (tempel manual)

```
Konteks proyek: POS kasir C'Bowl.id (Next.js App Router + TypeScript + Tailwind + Supabase).
Aturan wajib saya tempel di bawah. Ikuti persis.

[tempel isi AGENTS.md]

Dokumen pendukung untuk tugas ini:
[tempel hanya bagian yang disebut di "Baca" pada tugas, misalnya API §3 dan UI §3.3]

Tugas: [tempel teks tugas T-__ dari TASKS.md]
```

## C. Memperbaiki error build atau runtime

```
Saat mengerjakan T-__, muncul error ini:

[tempel error lengkap]

Baca AGENTS.md §6. Cari penyebab akarnya di file yang bersangkutan saja.
Jelaskan penyebabnya dalam 1-2 kalimat, lalu perbaiki dengan perubahan sekecil mungkin.
Jangan menulis ulang file dan jangan mengubah file lain.
```

## D. Memperbaiki bug perilaku

```
Tugas T-__ sudah selesai, tetapi saat diuji hasilnya salah.
Yang saya lakukan: [langkah]
Yang seharusnya terjadi (dari "Selesai jika" T-__ atau BUSINESS_RULES): [harapan]
Yang terjadi: [kenyataan]

Baca file terkait, jelaskan dugaan penyebab dalam 2 kalimat, tunggu saya jawab "lanjut", lalu perbaiki
dengan perubahan sekecil mungkin.
```

## E. Meninjau hasil agent (pakai di sesi baru)

```
Tinjau perubahan terakhir (git diff) dengan checklist AGENTS.md §7 dan larangan di §2.
Jangan mengubah kode. Tampilkan daftar pelanggaran (file:baris, aturan yang dilanggar).
Bila tidak ada, tulis "Tidak ada pelanggaran".
```

## F. Agent keluar jalur (menambah fitur, mengubah banyak file)

```
Berhenti. Kamu mengubah file di luar tugas T-__ atau menambah fitur yang tidak diminta.
Batalkan semua perubahan di luar tugas (hanya file yang tertulis di rencanamu).
Baca ulang AGENTS.md §1-§2 dan kerjakan HANYA T-__.
```

## G. Agent mengarang tabel, kolom, atau endpoint

```
Kolom/tabel/endpoint "[nama]" tidak ada di supabase/migrations/*.sql maupun docs/API.md.
Jangan mengarang. Gunakan hanya yang ada di dokumen tersebut.
Bila memang dibutuhkan sesuatu yang belum ada, berhenti dan ajukan PERTANYAAN
dengan format di AGENTS.md §5.
```

## H. Meminta agent menulis migrasi baru

```
Kita butuh perubahan skema: [jelaskan kebutuhan dan alasannya].
Buat file BARU supabase/migrations/000X_nama.sql (nomor berikutnya). Jangan ubah file lama.
Sertakan RLS untuk tabel baru dan fungsi RPC bila menyangkut uang/kas.
Setelah itu daftar dokumen mana yang perlu diperbarui (API.md, BUSINESS_RULES.md).
Jangan jalankan apa pun; saya yang menjalankan SQL di Supabase.
```

## I. Meminta agent memperbarui dokumen setelah keputusan baru

```
Pemilik memutuskan: [keputusan, mis. batas diskon kasir jadi 5%].
Perbarui dokumen yang terdampak (cari di docs/PRD.md §3, BUSINESS_RULES.md, UI_SCREENS.md, TASKS.md).
Tampilkan daftar perubahan per file sebagai diff. Jangan mengubah kode aplikasi.
```

---

## Tips khusus model gratis

- **Konteks pendek:** jangan menempel file besar. Tempel bagian relevan saja (nomor bagian sudah disediakan di setiap tugas).
- **Minta rencana dulu**, baru kode: model lemah jauh lebih akurat bila diminta merencanakan singkat.
- **Satu file per permintaan** bila hasil terpotong atau berantakan: "Buat hanya file `X`. File berikutnya nanti."
- **Beri contoh:** semua pola kode ada di `ARCHITECTURE.md`; katakan "salin pola dari ARCHITECTURE §5".
- **Bandingkan dengan contoh angka** di `BUSINESS_RULES.md` §9 untuk menangkap kesalahan hitung.
- **Jangan percaya "sudah selesai"**: uji manual langkah "Selesai jika" sendiri.
- **Bila model terus-menerus salah** pada satu gaya (mis. memakai `getSession`), tambahkan satu baris larangan di `AGENTS.md` §2 supaya terbaca di sesi berikutnya.
- **Hindari:** "buatkan seluruh aplikasi", "perbaiki semuanya", "rapikan kode" tanpa batas.
