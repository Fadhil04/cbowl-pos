# AGENTS.md: Aturan Wajib untuk AI Agent

Kamu membantu membangun **POS C'Bowl.id**, aplikasi kasir web untuk satu outlet rice bowl. Baca file ini **setiap sesi baru**. Salin isinya juga ke `CLAUDE.md`, `.cursorrules`, atau `.github/copilot-instructions.md` sesuai tool yang dipakai.

## 1. Cara kerja (WAJIB, urut)

1. Pengguna akan menyebut satu **ID tugas** (mis. `T-22`). Buka `docs/TASKS.md`, baca hanya tugas itu.
2. Baca file di bagian **"Baca"** pada tugas tersebut. Jangan membaca atau mengubah yang lain.
3. Tulis **rencana maksimal 5 baris**: file yang akan dibuat/diubah dan urutannya. Tunggu pengguna menjawab "lanjut" **hanya jika** tugas mengubah lebih dari 4 file.
4. Kerjakan **hanya** tugas itu. Jangan menambah fitur, "perbaikan kecil", atau refactor di luar tugas.
5. Jalankan `npm run lint` dan `npm run build`. Perbaiki error sampai bersih.
6. Laporkan dengan format ini lalu **berhenti**:
   ```
   SELESAI T-xx
   File dibuat: ...
   File diubah: ...
   Cara uji manual: (langkah singkat dari bagian "Selesai jika")
   Hal yang belum pasti: ... (atau "tidak ada")
   ```
7. Jangan mulai tugas berikutnya tanpa diminta.

## 2. Larangan keras

- ❌ Jangan mengarang tabel, kolom, endpoint, atau fungsi yang tidak ada di `supabase/migrations/*.sql` dan `docs/API.md`. Tidak ada di dokumen = tanya pengguna.
- ❌ Jangan memasang paket baru di luar daftar di `docs/ARCHITECTURE.md` §1 tanpa izin.
- ❌ Jangan mengubah file migrasi yang sudah dijalankan. Perubahan skema = file migrasi baru bernomor berikutnya.
- ❌ Jangan memakai `any`, `@ts-ignore`, atau `eslint-disable` untuk menutupi error. Perbaiki penyebabnya.
- ❌ Jangan memakai data palsu/hardcode untuk menggantikan data database ("sementara").
- ❌ Jangan memakai `float` atau `toFixed` untuk uang. Uang = integer Rupiah (`docs/BUSINESS_RULES.md` BR-01).
- ❌ Jangan `insert`/`update`/`delete` langsung ke `orders`, `order_items`, `shifts`, `void_requests`, `activity_logs`. Gunakan fungsi RPC (`create_order`, `open_shift`, `close_shift`, `request_void`, `decide_void`).
- ❌ Jangan memakai `SUPABASE_SERVICE_ROLE_KEY` di kode klien (`'use client'`), atau memberi awalan `NEXT_PUBLIC_`. Hanya `src/lib/supabase/admin.ts` yang boleh memakainya, dan hanya dari route API.
- ❌ Jangan menyimpan data bisnis di `localStorage`. Keranjang boleh disimpan di state React saja.
- ❌ Jangan menghapus data transaksi. Menu "dihapus" = `is_active=false`.
- ❌ Jangan menulis `console.log` berisi password, token, atau data pelanggan.
- ❌ Jangan percaya harga/total dari klien. Server/DB menghitung ulang.
- ❌ Jangan memakai `localhost` atau URL tertulis langsung di kode; pakai variabel lingkungan.

## 3. Aturan wajib

- ✅ Bahasa: **teks UI dalam Bahasa Indonesia**; nama variabel, fungsi, file, kolom dalam Bahasa Inggris.
- ✅ TypeScript ketat. Semua input API divalidasi dengan **zod**.
- ✅ Semua route API memakai pola di `docs/ARCHITECTURE.md` §5 (`requireUser` → validasi → RPC/query → `ok()`/`handleError()`).
- ✅ Format respons API selalu `{ ok: true, data }` atau `{ ok: false, error: { code, message } }`.
- ✅ Setiap halaman/komponen data punya tiga keadaan: **memuat**, **kosong**, **error** (teks di `docs/UI_SCREENS.md`).
- ✅ Tombol yang memicu simpan **dinonaktifkan** selama proses berjalan (cegah klik ganda = order ganda).
- ✅ Area ketuk minimal 44×44 px (`min-h-11 min-w-11` Tailwind).
- ✅ Nama file: komponen `PascalCase.tsx`, selain itu `kebab-case.ts`. Satu komponen utama per file.
- ✅ Pesan error untuk pengguna ramah dan jelas (Indonesia), tanpa jejak teknis.
- ✅ Jika menemukan konflik antar dokumen: ikuti urutan **BUSINESS_RULES > PRD > API > UI_SCREENS**, dan sebutkan konfliknya di laporan.

## 4. Stack (tetap, jangan diganti)

Next.js (App Router) + TypeScript + Tailwind CSS · Supabase (Postgres, Auth, RLS) lewat `@supabase/ssr` · zod · Vercel. Detail dan pola kode: `docs/ARCHITECTURE.md`.

Kesalahan umum yang HARUS dihindari:
- Jangan pakai paket `@supabase/auth-helpers-*` (usang). Pakai `@supabase/ssr`.
- Di Next.js terbaru, `cookies()`, `headers()`, dan `params` pada route/page adalah **async**, jadi pakai `await`.
- Di server, pakai `supabase.auth.getUser()`, bukan `getSession()`, untuk memeriksa login.
- Komponen yang memakai `useState`/`onClick` wajib diawali `'use client'`. Halaman yang mengambil data sebaiknya Server Component.
- Cek versi Next.js di `package.json`. Bila 16 ke atas, file `middleware.ts` mungkin bernama `proxy.ts`; ikuti dokumentasi resmi versi terpasang.

## 5. Bila tidak yakin

Jangan menebak. Berhenti dan tanya dengan format:
```
PERTANYAAN: (satu kalimat)
Pilihan: A) ... B) ...
Saran saya: A karena ...
```

## 6. Bila ada error

1. Baca pesan error **sampai habis**, cari nama file dan baris.
2. Perbaiki penyebab akarnya, jangan dibungkus try/catch yang menelan error.
3. Bila sudah 2 kali mencoba dan masih gagal: berhenti, tampilkan error lengkap + yang sudah dicoba, minta arahan.

## 7. Checklist "selesai" (periksa sebelum melapor)

- [ ] Hanya file yang relevan dengan tugas yang berubah
- [ ] `npm run lint` dan `npm run build` bersih
- [ ] Tidak ada `any`, `console.log` sisa, atau komentar TODO tanpa nomor tugas
- [ ] Uang integer; teks UI Indonesia; tiga keadaan UI ada
- [ ] Hak akses dicek di API (`requireUser`) dan, bila halaman admin, di layout
- [ ] Semua poin "Selesai jika" pada tugas terpenuhi
