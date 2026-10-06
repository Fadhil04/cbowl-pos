# API.md: Kontrak Endpoint

Semua endpoint di bawah `/api`. Respons selalu:
```json
{ "ok": true, "data": ... }
{ "ok": false, "error": { "code": "RULE_VIOLATION", "message": "Uang diterima kurang dari total" } }
```
Kode error: `UNAUTHORIZED` 401 · `FORBIDDEN` 403 · `VALIDATION` 422 · `RULE_VIOLATION` 400 (pesan dari fungsi database) · `NOT_FOUND` 404 · `INTERNAL` 500.

**Tidak ada endpoint lain.** Butuh endpoint baru → tanya pengguna dulu. Pola kode: `ARCHITECTURE.md` §5. Kolom "Akses": `login` = semua pengguna aktif, `admin` = hanya admin.

## 1. Data untuk kasir

| Method & path | Akses | Fungsi |
|---|---|---|
| `GET /api/menu` | login | Kategori + menu tersedia + sambal tersedia |

Respons `data`:
```json
{
  "categories": [
    { "id": "uuid", "name": "Rice Bowl", "requires_sambal": true,
      "items": [ { "id": "uuid", "name": "Rice Bowl Contoh 1", "price": 28000 } ] }
  ],
  "sambals": [ { "id": "uuid", "name": "Sambal Matah" } ]
}
```
Query: kategori `is_active=true` urut `sort_order`; menu `is_active=true AND is_available=true` urut `sort_order`; sambal `is_available=true` urut `sort_order`. Kategori tanpa menu tetap dikirim dengan `items: []`.

## 2. Shift

| Method & path | Akses | Body | Fungsi |
|---|---|---|---|
| `GET /api/shifts/current` | login | - | Shift terbuka milik pengguna, atau `null` |
| `POST /api/shifts/open` | login | `{ "opening_cash": 100000 }` | RPC `open_shift` → `{ shift_id }` (201) |
| `POST /api/shifts/close` | login | `{ "counted_cash": 210000, "note": "opsional" }` | RPC `close_shift` → rekap |
| `GET /api/shifts/summary` | login | - | Ringkasan berjalan shift terbuka (lihat di bawah) |
| `GET /api/admin/shifts?date=YYYY-MM-DD` | admin | - | Daftar shift + nama kasir pada tanggal tersebut (WIB) |

`GET /api/shifts/current` → `data`: `{ "id", "opened_at", "opening_cash" }` atau `null`.

`GET /api/shifts/summary` → `data` (dihitung dari order shift terbuka, order `paid` saja): `{ "opening_cash", "cash_sales", "qris_sales", "order_count", "void_count", "expected_cash" }` dengan `expected_cash = opening_cash + cash_sales`. Dipakai di layar tutup shift untuk preview sebelum kasir mengisi kas hitung.

Rekap `close`: `{ shift_id, opening_cash, cash_sales, qris_sales, order_count, void_count, expected_cash, counted_cash, cash_difference }`.

## 3. Order

| Method & path | Akses | Fungsi |
|---|---|---|
| `POST /api/orders` | login | Buat order via RPC `create_order` → `{ order_id }` (201) |
| `GET /api/orders?scope=today` | login | Riwayat (lihat di bawah) |
| `GET /api/orders/[id]` | login | Detail order + item (untuk struk) |
| `POST /api/orders/[id]/void-request` | login | Ajukan void via RPC `request_void` |

`POST /api/orders` body:
```json
{
  "items": [
    { "menu_item_id": "uuid", "quantity": 2, "sambal_option_id": "uuid" },
    { "menu_item_id": "uuid", "quantity": 1, "sambal_option_id": null }
  ],
  "order_type": "dine_in",
  "channel": "direct",
  "payment_method": "cash",
  "cash_received": 100000,
  "discount_amount": 0,
  "discount_reason": null
}
```
Skema zod: `items` array 1-100 elemen; `quantity` int 1-99; `order_type` ∈ `dine_in|takeaway`; `channel` ∈ `direct|whatsapp|gofood|grabfood` (default `direct`); `payment_method` ∈ `cash|qris`; `cash_received` int ≥ 0 atau `null`; `discount_amount` int ≥ 0 (default 0). **Tidak ada** field harga/total di body.
Pemetaan RPC: `p_items`, `p_order_type`, `p_channel`, `p_payment_method`, `p_cash_received`, `p_discount_amount`, `p_discount_reason`.

`GET /api/orders?scope=today` (`scope`: `today` = hari ini WIB; `shift` = shift terbuka). Kasir hanya melihat miliknya (dijaga RLS); admin melihat semua. Urut terbaru dulu. Tiap baris: `id, order_number, order_date, created_at, total, payment_method, channel, order_type, status`, ditambah `has_pending_void: boolean` (ada `void_requests.status='pending'`).

`GET /api/orders/[id]` → `data`:
```json
{
  "id": "uuid", "order_number": 12, "order_date": "2026-10-06", "created_at": "iso",
  "cashier_name": "Sari", "order_type": "dine_in", "channel": "direct",
  "payment_method": "cash", "subtotal": 64000, "discount_amount": 5000,
  "discount_reason": "Pelanggan tetap", "total": 59000,
  "cash_received": 60000, "change_amount": 1000, "status": "paid",
  "items": [ { "item_name": "Rice Bowl Contoh 1", "sambal_name": "Sambal Matah",
               "unit_price": 28000, "quantity": 2, "line_total": 56000 } ]
}
```

`POST /api/orders/[id]/void-request` body `{ "reason": "Salah input menu" }` (string 5-300). → `{ request_id }` (201).

## 4. Void (admin)

| Method & path | Akses | Fungsi |
|---|---|---|
| `GET /api/admin/void-requests?status=pending` | admin | Antrean. `status` ∈ `pending|approved|rejected|all` |
| `POST /api/admin/void-requests/[id]/decide` | admin | Body `{ "approve": true, "note": "opsional" }` → RPC `decide_void` |

Baris antrean: `id, status, reason, created_at, requested_by_name, order: { id, order_number, order_date, total, payment_method }`.

## 5. Data master (admin)

Pola sama untuk tiga sumber daya. Hanya admin. Tidak ada DELETE; nonaktifkan lewat PATCH.

| Path | GET | POST (body) | PATCH `/[id]` (body, semua opsional) |
|---|---|---|---|
| `/api/admin/categories` | daftar semua | `{ name, requires_sambal, sort_order }` | `{ name, requires_sambal, sort_order, is_active }` |
| `/api/admin/menu-items` | daftar semua + nama kategori | `{ category_id, name, price, sort_order }` | `{ category_id, name, price, sort_order, is_available, is_active }` |
| `/api/admin/sambals` | daftar semua | `{ name, sort_order }` | `{ name, sort_order, is_available }` |

Validasi: `name` 1-60 karakter (trim); `price` int 0-10.000.000; `sort_order` int. Perubahan harga otomatis dicatat oleh trigger database.

## 6. Pengguna (admin, memakai service role)

| Method & path | Body | Catatan |
|---|---|---|
| `GET /api/admin/users` | - | `id, full_name, role, is_active, email` |
| `POST /api/admin/users` | `{ email, password, full_name, role }` | Buat user di Supabase Auth (`email_confirm: true`) lalu insert `profiles`. Bila insert profil gagal, hapus user Auth yang baru dibuat. Password ≥ 8 karakter |
| `PATCH /api/admin/users/[id]` | `{ full_name?, role?, is_active? }` | Admin tidak boleh menonaktifkan atau menurunkan role dirinya sendiri → `RULE_VIOLATION` |

Setelah POST/PATCH sukses, tulis log (`user_created` / `user_updated`) lewat insert langsung memakai klien service role **hanya** untuk tabel `activity_logs` (`actor_id` = admin pemanggil).

## 7. Pengaturan (admin)

| Method & path | Body |
|---|---|
| `GET /api/admin/settings` | - → `{ discount_cashier_max_percent: number }` |
| `PATCH /api/admin/settings` | `{ discount_cashier_max_percent }` int 0-100. Update `app_settings` dan tulis log `setting_changed` (service role untuk log) |

## 8. Laporan (admin)

Semua `GET`, parameter `from` dan `to` format `YYYY-MM-DD` (default keduanya hari ini WIB; `from ≤ to`; maksimal rentang 92 hari).

| Path | RPC | Baris |
|---|---|---|
| `/api/admin/reports/daily` | `report_daily(p_from, p_to)` | `order_date, order_count, revenue, cash_total, qris_total, discount_total, void_count` |
| `/api/admin/reports/top-items` (+ `limit`) | `report_top_items` | `item_name, qty_sold, revenue` |
| `/api/admin/reports/peak-hours` | `report_peak_hours` | `hour_of_day, order_count, revenue` |
| `/api/admin/reports/by-channel` | `report_by_channel` | `channel, order_count, revenue` |

Angka bigint dikirim sebagai number (aman untuk skala outlet ini).

## 9. Log (admin)

`GET /api/admin/logs?limit=50&before=<ISO created_at>&action=<opsional>` → baris terbaru dulu: `id, created_at, action, entity_type, entity_id, details, actor_name`. `limit` 1-100. Halaman berikutnya memakai `before` = `created_at` baris terakhir.
