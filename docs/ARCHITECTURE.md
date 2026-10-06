# ARCHITECTURE.md

Pola kode di sini adalah **template**. Agent: salin polanya, jangan membuat gaya baru.

## 1. Stack dan paket

| Keperluan | Paket |
|---|---|
| Framework | `next` (App Router), `react`, `typescript` |
| Gaya | `tailwindcss` |
| Supabase | `@supabase/supabase-js`, `@supabase/ssr` |
| Validasi | `zod` |
| Server-only | `server-only` |

Hanya paket di atas. Tambahan (mis. ikon, tanggal) harus seizin pengguna. Untuk tanggal, pakai `Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta' })`, tanpa library.

Setup awal (Tugas T-00):
```bash
npx create-next-app@latest cbowl-pos --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
cd cbowl-pos
npm install @supabase/supabase-js @supabase/ssr zod server-only
```

## 2. Variabel lingkungan

File `.env.local` (jangan di-commit; `.env.example` di-commit):
```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=      # boleh diisi publishable key bila dashboard menampilkan itu
SUPABASE_SERVICE_ROLE_KEY=          # RAHASIA. Tanpa awalan NEXT_PUBLIC_
```
Di Vercel: isi ketiganya di Settings → Environment Variables.

## 3. Struktur folder

```
src/
  app/
    layout.tsx
    login/page.tsx
    (app)/                       # semua halaman setelah login
      layout.tsx                 # navigasi sesuai role
      page.tsx                   # redirect: kasir→/kasir, admin→/admin
      kasir/page.tsx             # layar kasir
      kasir/shift/page.tsx       # buka/tutup shift
      riwayat/page.tsx
      struk/[id]/page.tsx
      admin/
        layout.tsx               # wajib admin
        menu/page.tsx
        sambal/page.tsx
        pengguna/page.tsx
        void/page.tsx
        shift/page.tsx
        laporan/page.tsx
        log/page.tsx
        pengaturan/page.tsx
    api/                         # route handler, lihat docs/API.md
  components/
    ui/                          # Button, Card, Modal, Input, Spinner, EmptyState, ErrorState
    pos/                         # MenuGrid, Cart, PaymentPanel, SambalPicker, Receipt
    admin/
  lib/
    supabase/{client,server,admin}.ts
    api.ts                       # ok(), fail(), ApiError, handleError()
    auth.ts                      # requireUser()
    api-client.ts                # apiFetch() untuk komponen klien
    format.ts                    # formatRupiah, formatDateTime, todayWIB
    constants.ts                 # nama outlet, alamat, label kanal
    validators/                  # skema zod per domain
  types/
    database.ts                  # hasil `supabase gen types` (jangan diedit manual)
    app.ts                       # tipe bantu (CartLine, dll)
middleware.ts                    # (atau proxy.ts, lihat AGENTS.md §4)
supabase/migrations/*.sql
docs/*.md
```

## 4. Klien Supabase

`src/lib/supabase/client.ts` (untuk komponen `'use client'`):
```ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

`src/lib/supabase/server.ts` (untuk route handler dan Server Component):
```ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // dipanggil dari Server Component: boleh diabaikan, middleware yang menyegarkan sesi
          }
        },
      },
    }
  );
}
```

`src/lib/supabase/admin.ts` (HANYA untuk route `/api/admin/users`):
```ts
import 'server-only';
import { createClient } from '@supabase/supabase-js';

export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );
}
```

`middleware.ts` (menyegarkan sesi + melindungi halaman):
```ts
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  const path = request.nextUrl.pathname;
  const isApi = path.startsWith('/api');
  const isLogin = path.startsWith('/login');

  if (!user && !isLogin && !isApi) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  if (user && isLogin) {
    return NextResponse.redirect(new URL('/', request.url));
  }
  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

## 5. Pola API (salin untuk SETIAP route)

`src/lib/api.ts`:
```ts
import { NextResponse } from 'next/server';
import { ZodError } from 'zod';

export class ApiError extends Error {
  constructor(public code: string, message: string, public status = 400) {
    super(message);
  }
}

export function ok<T>(data: T, status = 200) {
  return NextResponse.json({ ok: true, data }, { status });
}

export function fail(code: string, message: string, status = 400) {
  return NextResponse.json({ ok: false, error: { code, message } }, { status });
}

// Error dari fungsi Postgres (raise exception) punya kode P0001 dan pesan Indonesia yang aman ditampilkan.
export function handleError(e: unknown) {
  if (e instanceof ApiError) return fail(e.code, e.message, e.status);
  if (e instanceof ZodError) {
    return fail('VALIDATION', e.issues.map((i) => i.message).join(', '), 422);
  }
  if (typeof e === 'object' && e !== null && 'code' in e && 'message' in e) {
    const pg = e as { code: string; message: string };
    if (pg.code === 'P0001') return fail('RULE_VIOLATION', pg.message, 400);
  }
  console.error(e);
  return fail('INTERNAL', 'Terjadi kesalahan. Coba lagi.', 500);
}
```

`src/lib/auth.ts`:
```ts
import { createClient } from '@/lib/supabase/server';
import { ApiError } from '@/lib/api';

export async function requireUser(requiredRole?: 'admin') {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new ApiError('UNAUTHORIZED', 'Silakan login dulu', 401);

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, full_name, role, is_active')
    .eq('id', user.id)
    .single();

  if (!profile || !profile.is_active) throw new ApiError('FORBIDDEN', 'Akun tidak aktif', 403);
  if (requiredRole === 'admin' && profile.role !== 'admin') {
    throw new ApiError('FORBIDDEN', 'Khusus admin', 403);
  }
  return { supabase, user, profile };
}
```

Contoh route lengkap `src/app/api/shifts/open/route.ts`:
```ts
import { z } from 'zod';
import { ok, handleError } from '@/lib/api';
import { requireUser } from '@/lib/auth';

const bodySchema = z.object({
  opening_cash: z.number().int('Harus bilangan bulat').min(0, 'Tidak boleh negatif'),
});

export async function POST(request: Request) {
  try {
    const { supabase } = await requireUser();
    const body = bodySchema.parse(await request.json());
    const { data, error } = await supabase.rpc('open_shift', { p_opening_cash: body.opening_cash });
    if (error) throw error;
    return ok({ shift_id: data }, 201);
  } catch (e) {
    return handleError(e);
  }
}
```

Route dengan parameter dinamis (Next terbaru: `params` adalah Promise):
```ts
export async function GET(
  _req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  // ...
}
```

## 6. Pola klien

`src/lib/api-client.ts`:
```ts
type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: { code: string; message: string } };

export async function apiFetch<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
  });
  const json = (await res.json()) as ApiResult<T>;
  if (!json.ok) throw new Error(json.error.message);
  return json.data;
}
```

Pola komponen yang menyimpan data:
```tsx
'use client';
import { useState } from 'react';
import { apiFetch } from '@/lib/api-client';

export function Example() {
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    setSaving(true);
    setError(null);
    try {
      await apiFetch('/api/....', { method: 'POST', body: JSON.stringify({ /* ... */ }) });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Terjadi kesalahan');
    } finally {
      setSaving(false);
    }
  }
  return <button disabled={saving} onClick={handleSave}>{saving ? 'Menyimpan...' : 'Simpan'}</button>;
}
```

## 7. Util wajib (`src/lib/format.ts`)

```ts
export function formatRupiah(value: number): string {
  return 'Rp' + new Intl.NumberFormat('id-ID').format(value);
}

export function formatDateTime(iso: string): string {
  return new Intl.DateTimeFormat('id-ID', {
    timeZone: 'Asia/Jakarta', dateStyle: 'short', timeStyle: 'short',
  }).format(new Date(iso));
}

// "YYYY-MM-DD" untuk hari ini di WIB
export function todayWIB(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jakarta' }).format(new Date());
}

export function formatOrderNumber(n: number): string {
  return '#' + String(n).padStart(3, '0');
}

export function parseRupiahInput(text: string): number {
  const digits = text.replace(/\D/g, '');
  return digits === '' ? 0 : parseInt(digits, 10);
}
```

## 8. Hak akses (tiga lapis)

1. **Database**: RLS dan pengecekan di fungsi RPC (sudah di migrasi).
2. **API**: `requireUser()` / `requireUser('admin')` di baris pertama setiap route.
3. **UI**: `src/app/(app)/admin/layout.tsx` memeriksa role di server; kasir di-`redirect('/kasir')`.

Layout admin:
```tsx
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');
  const { data: profile } = await supabase.from('profiles').select('role, is_active').eq('id', user.id).single();
  if (!profile?.is_active || profile.role !== 'admin') redirect('/kasir');
  return <>{children}</>;
}
```

## 9. Tipe database

Setelah migrasi dijalankan:
```bash
npx supabase gen types typescript --project-id <PROJECT_ID> > src/types/database.ts
```
Ulangi tiap ada migrasi baru. Jangan mengedit `database.ts` manual.

## 10. Pengujian

- Setiap tugas punya "Selesai jika" yang diuji **manual** di browser.
- Untuk `format.ts` boleh ditambah uji unit **hanya bila** pengguna meminta (butuh paket baru).
- Sebelum UAT: jalankan checklist `TASKS.md` T-62.

## 11. Git

Satu tugas = satu commit: `git add -A && git commit -m "T-22: grid menu dan keranjang"`. Bila agent merusak sesuatu: `git restore .` atau `git reset --hard HEAD`.
