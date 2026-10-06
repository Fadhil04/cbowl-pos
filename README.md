# POS C'Bowl.id: Paket Dokumen untuk Pengembangan dengan AI Agent

Paket ini dirancang agar AI agent yang kemampuannya terbatas (model gratis) tetap menghasilkan kode yang benar: keputusan sudah dibuat, tugas dipecah kecil, pola kode disediakan, dan logika uang ada di database.

## Isi paket

| File | Fungsi | Dibaca agent kapan |
|---|---|---|
| `AGENTS.md` | Aturan wajib, larangan, format laporan | **Setiap sesi** |
| `docs/PRD.md` | Apa yang dibuat (v0.2): kebutuhan, hak akses, keputusan default | Sesuai tugas |
| `docs/BUSINESS_RULES.md` | Aturan bisnis, struk, contoh angka uji | Sesuai tugas |
| `docs/ARCHITECTURE.md` | Stack, struktur folder, **template kode** | Sesuai tugas |
| `docs/API.md` | Kontrak setiap endpoint | Sesuai tugas |
| `docs/UI_SCREENS.md` | Isi dan perilaku setiap layar | Sesuai tugas |
| `docs/TASKS.md` | ±35 tugas kecil dengan kriteria "selesai jika" | **Selalu**, satu tugas per sesi |
| `docs/PROMPT_TEMPLATES.md` | Prompt siap tempel (untuk manusia) | - |
| `supabase/migrations/0001_init.sql` | Tabel, RLS, trigger, fungsi buat order/void/shift | Dijalankan manusia |
| `supabase/migrations/0002_reports.sql` | Fungsi laporan | Dijalankan manusia |
| `supabase/seed.sql` | Data contoh dan petunjuk admin pertama | Dijalankan manusia |

## Cara mulai (urutan)

1. Kerjakan **T-00 sampai T-03** di `docs/TASKS.md` (persiapan; sebagian manual).
2. Salin `AGENTS.md` juga ke nama yang dibaca tool Anda: `CLAUDE.md`, `.cursorrules`, atau `.github/copilot-instructions.md`.
3. Buka sesi chat baru, tempel **Prompt A** dari `docs/PROMPT_TEMPLATES.md` dengan nomor tugas berikutnya.
4. Uji manual "Selesai jika" → `git diff` → commit → centang tugas → sesi baru.

## `.env.example`

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```
(Salin ke `.env.local` dan isi. Jangan pernah commit `.env.local`.)

## Ide desain yang perlu Anda tahu

- **Uang dan kas dihitung di database**, bukan di kode TypeScript. Agent lemah cenderung salah hitung; fungsi `create_order`, `close_shift`, `request_void`, `decide_void` membuatnya tidak mungkin menyimpan order dengan harga atau total yang salah.
- **Tabel transaksi tidak bisa ditulis langsung dari aplikasi** (RLS tanpa policy tulis) dan tidak bisa dihapus (trigger).
- **Keputusan default (PRD §3)** menggantikan pertanyaan terbuka sementara. Setelah wawancara pemilik, ubah nilainya dan buat PRD v0.3.
- Nama menu dan sambal di `seed.sql` hanya **contoh**; ganti dengan menu asli lewat layar admin.

## Yang belum diverifikasi

SQL belum dijalankan di Supabase asli. Saat T-01, bila ada error, tempel pesan error lengkapnya ke chat untuk diperbaiki sebelum lanjut. Cek juga versi Next.js terpasang terhadap catatan di `AGENTS.md` §4 (nama file `middleware.ts` vs `proxy.ts`).
