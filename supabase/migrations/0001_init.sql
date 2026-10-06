-- =====================================================================
-- 0001_init.sql  |  POS C'Bowl.id
-- Jalankan SEKALI di Supabase Dashboard > SQL Editor.
-- JANGAN diubah setelah dijalankan; perubahan = file migrasi baru (0003, dst).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- ENUM ----------
create type user_role       as enum ('admin', 'cashier');
create type order_type      as enum ('dine_in', 'takeaway');
create type order_channel   as enum ('direct', 'whatsapp', 'gofood', 'grabfood');
create type payment_method  as enum ('cash', 'qris');
create type order_status    as enum ('paid', 'void');
create type request_status  as enum ('pending', 'approved', 'rejected');
create type shift_status    as enum ('open', 'closed');

-- ---------- TABEL ----------
create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  role        user_role not null default 'cashier',
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table categories (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,
  requires_sambal boolean not null default false,
  sort_order      integer not null default 0,
  is_active       boolean not null default true
);

create table menu_items (
  id            uuid primary key default gen_random_uuid(),
  category_id   uuid not null references categories(id),
  name          text not null,
  price         integer not null check (price >= 0),
  is_available  boolean not null default true,
  is_active     boolean not null default true,
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table sambal_options (
  id            uuid primary key default gen_random_uuid(),
  name          text not null unique,
  is_available  boolean not null default true,
  sort_order    integer not null default 0
);

create table app_settings (
  key          text primary key,
  value        text not null,
  description  text
);
insert into app_settings(key, value, description) values
  ('discount_cashier_max_percent', '10', 'Batas diskon kasir (persen dari subtotal). Di atas ini hanya admin.');

create table shifts (
  id               uuid primary key default gen_random_uuid(),
  cashier_id       uuid not null references profiles(id),
  status           shift_status not null default 'open',
  opened_at        timestamptz not null default now(),
  closed_at        timestamptz,
  opening_cash     integer not null check (opening_cash >= 0),
  expected_cash    integer,
  counted_cash     integer check (counted_cash is null or counted_cash >= 0),
  cash_difference  integer,
  note             text
);
create unique index one_open_shift_per_cashier on shifts(cashier_id) where status = 'open';

create table daily_counters (
  order_date   date primary key,
  last_number  integer not null
);

create table orders (
  id               uuid primary key default gen_random_uuid(),
  order_date       date not null,
  order_number     integer not null,
  shift_id         uuid not null references shifts(id),
  cashier_id       uuid not null references profiles(id),
  order_type       order_type not null,
  channel          order_channel not null default 'direct',
  payment_method   payment_method not null,
  subtotal         integer not null check (subtotal >= 0),
  discount_amount  integer not null default 0 check (discount_amount >= 0),
  discount_reason  text,
  total            integer not null check (total >= 0),
  cash_received    integer,
  change_amount    integer,
  status           order_status not null default 'paid',
  voided_at        timestamptz,
  created_at       timestamptz not null default now(),
  unique (order_date, order_number),
  check (discount_amount <= subtotal),
  check (discount_amount = 0 or discount_reason is not null)
);
create index orders_order_date_idx on orders(order_date);
create index orders_shift_idx      on orders(shift_id);
create index orders_cashier_idx    on orders(cashier_id, created_at desc);

create table order_items (
  id                uuid primary key default gen_random_uuid(),
  order_id          uuid not null references orders(id),
  menu_item_id      uuid references menu_items(id),
  item_name         text not null,          -- snapshot nama
  unit_price        integer not null check (unit_price >= 0),  -- snapshot harga
  quantity          integer not null check (quantity between 1 and 99),
  sambal_option_id  uuid references sambal_options(id),
  sambal_name       text,                   -- snapshot nama sambal
  line_total        integer not null check (line_total >= 0)
);
create index order_items_order_idx on order_items(order_id);

create table void_requests (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references orders(id),
  requested_by   uuid not null references profiles(id),
  reason         text not null,
  status         request_status not null default 'pending',
  decided_by     uuid references profiles(id),
  decided_at     timestamptz,
  decision_note  text,
  created_at     timestamptz not null default now()
);
create unique index one_pending_void_per_order on void_requests(order_id) where status = 'pending';

create table activity_logs (
  id           uuid primary key default gen_random_uuid(),
  actor_id     uuid references profiles(id),
  action       text not null,
  entity_type  text not null,
  entity_id    uuid,
  details      jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);
create index activity_logs_created_idx on activity_logs(created_at desc);

-- ---------- FUNGSI BANTU ----------
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin' and is_active
  );
$$;

create or replace function public.write_log(
  p_action text, p_entity_type text, p_entity_id uuid, p_details jsonb default '{}'::jsonb
) returns void
language sql security definer set search_path = public as $$
  insert into activity_logs(actor_id, action, entity_type, entity_id, details)
  values (auth.uid(), p_action, p_entity_type, p_entity_id, coalesce(p_details, '{}'::jsonb));
$$;
-- write_log hanya boleh dipanggil dari fungsi lain, bukan dari klien:
revoke all on function public.write_log(text, text, uuid, jsonb) from public, anon, authenticated;

-- ---------- TRIGGER ----------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
create trigger menu_items_updated before update on menu_items
  for each row execute function public.set_updated_at();

create or replace function public.log_price_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.price is distinct from old.price then
    perform public.write_log('price_changed', 'menu_item', new.id,
      jsonb_build_object('name', new.name, 'old_price', old.price, 'new_price', new.price));
  end if;
  return new;
end $$;
create trigger menu_items_price_log after update on menu_items
  for each row execute function public.log_price_change();

create or replace function public.block_delete() returns trigger
language plpgsql as $$
begin
  raise exception 'Data ini tidak boleh dihapus';
end $$;
create trigger no_delete_orders      before delete on orders         for each row execute function public.block_delete();
create trigger no_delete_order_items before delete on order_items    for each row execute function public.block_delete();
create trigger no_delete_logs        before delete on activity_logs  for each row execute function public.block_delete();
create trigger no_delete_voids       before delete on void_requests  for each row execute function public.block_delete();

create or replace function public.block_log_update() returns trigger
language plpgsql as $$
begin
  raise exception 'Log tidak boleh diubah';
end $$;
create trigger no_update_logs before update on activity_logs for each row execute function public.block_log_update();

-- ---------- RLS ----------
alter table profiles        enable row level security;
alter table categories      enable row level security;
alter table menu_items      enable row level security;
alter table sambal_options  enable row level security;
alter table app_settings    enable row level security;
alter table shifts          enable row level security;
alter table daily_counters  enable row level security;
alter table orders          enable row level security;
alter table order_items     enable row level security;
alter table void_requests   enable row level security;
alter table activity_logs   enable row level security;

-- profiles: baca milik sendiri, admin baca semua. Tulis lewat service_role (API admin).
create policy profiles_select on profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());

-- data master: semua pengguna login boleh baca; hanya admin boleh tulis
create policy categories_select on categories for select to authenticated using (true);
create policy categories_admin  on categories for all    to authenticated using (public.is_admin()) with check (public.is_admin());

create policy menu_select on menu_items for select to authenticated using (true);
create policy menu_admin  on menu_items for all    to authenticated using (public.is_admin()) with check (public.is_admin());

create policy sambal_select on sambal_options for select to authenticated using (true);
create policy sambal_admin  on sambal_options for all    to authenticated using (public.is_admin()) with check (public.is_admin());

create policy settings_select on app_settings for select to authenticated using (true);
create policy settings_admin  on app_settings for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- transaksi: baca saja. Tulis HANYA lewat fungsi (security definer) di bawah.
create policy shifts_select on shifts for select to authenticated
  using (cashier_id = auth.uid() or public.is_admin());

create policy orders_select on orders for select to authenticated
  using (cashier_id = auth.uid() or public.is_admin());

create policy order_items_select on order_items for select to authenticated
  using (exists (
    select 1 from orders o
    where o.id = order_items.order_id and (o.cashier_id = auth.uid() or public.is_admin())
  ));

create policy voids_select on void_requests for select to authenticated
  using (requested_by = auth.uid() or public.is_admin());

create policy logs_select on activity_logs for select to authenticated
  using (public.is_admin());

-- daily_counters: tanpa policy = tidak bisa diakses klien (sengaja)

-- ---------- FUNGSI BISNIS (dipanggil via supabase.rpc) ----------

-- Buka shift
create or replace function public.open_shift(p_opening_cash integer) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_id  uuid;
begin
  if not exists (select 1 from profiles where id = v_uid and is_active) then
    raise exception 'Pengguna tidak aktif atau tidak ditemukan';
  end if;
  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'Kas awal tidak valid';
  end if;
  if exists (select 1 from shifts where cashier_id = v_uid and status = 'open') then
    raise exception 'Masih ada shift yang terbuka';
  end if;

  insert into shifts(cashier_id, opening_cash) values (v_uid, p_opening_cash)
  returning id into v_id;

  perform public.write_log('shift_opened', 'shift', v_id, jsonb_build_object('opening_cash', p_opening_cash));
  return v_id;
end $$;

-- Tutup shift
create or replace function public.close_shift(p_counted_cash integer, p_note text default null) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid       uuid := auth.uid();
  v_shift     shifts;
  v_cash      integer;
  v_qris      integer;
  v_count     integer;
  v_void      integer;
  v_expected  integer;
  v_diff      integer;
begin
  if p_counted_cash is null or p_counted_cash < 0 then
    raise exception 'Kas hitung tidak valid';
  end if;

  select * into v_shift from shifts where cashier_id = v_uid and status = 'open' for update;
  if not found then
    raise exception 'Tidak ada shift yang terbuka';
  end if;

  select coalesce(sum(total) filter (where payment_method = 'cash' and status = 'paid'), 0),
         coalesce(sum(total) filter (where payment_method = 'qris' and status = 'paid'), 0),
         count(*) filter (where status = 'paid'),
         count(*) filter (where status = 'void')
    into v_cash, v_qris, v_count, v_void
    from orders where shift_id = v_shift.id;

  v_expected := v_shift.opening_cash + v_cash;
  v_diff     := p_counted_cash - v_expected;

  update shifts
     set status = 'closed', closed_at = now(), expected_cash = v_expected,
         counted_cash = p_counted_cash, cash_difference = v_diff, note = p_note
   where id = v_shift.id;

  perform public.write_log('shift_closed', 'shift', v_shift.id,
    jsonb_build_object('expected_cash', v_expected, 'counted_cash', p_counted_cash, 'difference', v_diff));

  return jsonb_build_object(
    'shift_id', v_shift.id, 'opening_cash', v_shift.opening_cash,
    'cash_sales', v_cash, 'qris_sales', v_qris,
    'order_count', v_count, 'void_count', v_void,
    'expected_cash', v_expected, 'counted_cash', p_counted_cash, 'cash_difference', v_diff);
end $$;

-- Buat order
-- p_items: [{"menu_item_id":"...","quantity":2,"sambal_option_id":"..."|null}, ...]
create or replace function public.create_order(
  p_items           jsonb,
  p_order_type      order_type,
  p_channel         order_channel,
  p_payment_method  payment_method,
  p_cash_received   integer default null,
  p_discount_amount integer default 0,
  p_discount_reason text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid        uuid := auth.uid();
  v_profile    profiles;
  v_shift      shifts;
  v_item       jsonb;
  v_menu       menu_items;
  v_cat        categories;
  v_sambal     sambal_options;
  v_qty        integer;
  v_line_total integer;
  v_lines      jsonb := '[]'::jsonb;
  v_subtotal   integer := 0;
  v_discount   integer := coalesce(p_discount_amount, 0);
  v_total      integer;
  v_change     integer;
  v_cash       integer := p_cash_received;
  v_max_pct    integer;
  v_date       date := (now() at time zone 'Asia/Jakarta')::date;
  v_number     integer;
  v_order_id   uuid;
begin
  select * into v_profile from profiles where id = v_uid and is_active;
  if not found then
    raise exception 'Pengguna tidak aktif atau tidak ditemukan';
  end if;

  select * into v_shift from shifts where cashier_id = v_uid and status = 'open';
  if not found then
    raise exception 'Belum ada shift terbuka. Buka shift dulu.';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Keranjang kosong';
  end if;

  -- 1) validasi tiap item dan hitung harga dari database
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    if v_qty is null or v_qty < 1 or v_qty > 99 then
      raise exception 'Jumlah harus 1 sampai 99';
    end if;

    select * into v_menu from menu_items
     where id = (v_item->>'menu_item_id')::uuid and is_active and is_available;
    if not found then
      raise exception 'Ada menu yang tidak tersedia';
    end if;

    select * into v_cat from categories where id = v_menu.category_id;

    v_sambal := null;
    if v_cat.requires_sambal then
      if (v_item->>'sambal_option_id') is null then
        raise exception 'Pilih sambal untuk %', v_menu.name;
      end if;
      select * into v_sambal from sambal_options
       where id = (v_item->>'sambal_option_id')::uuid and is_available;
      if not found then
        raise exception 'Sambal tidak tersedia';
      end if;
    end if;

    v_line_total := v_menu.price * v_qty;
    v_subtotal   := v_subtotal + v_line_total;
    v_lines := v_lines || jsonb_build_array(jsonb_build_object(
      'menu_item_id', v_menu.id,
      'item_name', v_menu.name,
      'unit_price', v_menu.price,
      'quantity', v_qty,
      'sambal_option_id', v_sambal.id,
      'sambal_name', v_sambal.name,
      'line_total', v_line_total));
  end loop;

  -- 2) diskon
  if v_discount < 0 or v_discount > v_subtotal then
    raise exception 'Diskon tidak valid';
  end if;
  if v_discount > 0 then
    if p_discount_reason is null or length(trim(p_discount_reason)) < 3 then
      raise exception 'Alasan diskon wajib diisi';
    end if;
    select value::integer into v_max_pct from app_settings where key = 'discount_cashier_max_percent';
    if v_profile.role <> 'admin' and v_discount * 100 > v_subtotal * coalesce(v_max_pct, 0) then
      raise exception 'Diskon melebihi batas kasir. Minta admin.';
    end if;
  end if;

  -- 3) pembayaran
  v_total := v_subtotal - v_discount;
  if p_payment_method = 'cash' then
    if v_cash is null or v_cash < v_total then
      raise exception 'Uang diterima kurang dari total';
    end if;
    v_change := v_cash - v_total;
  else
    v_cash := null;
    v_change := null;
  end if;

  -- 4) nomor order (atomik per hari)
  insert into daily_counters(order_date, last_number) values (v_date, 1)
  on conflict (order_date) do update set last_number = daily_counters.last_number + 1
  returning last_number into v_number;

  -- 5) simpan
  insert into orders(order_date, order_number, shift_id, cashier_id, order_type, channel,
                     payment_method, subtotal, discount_amount, discount_reason, total,
                     cash_received, change_amount)
  values (v_date, v_number, v_shift.id, v_uid, p_order_type, p_channel,
          p_payment_method, v_subtotal, v_discount,
          case when v_discount > 0 then trim(p_discount_reason) else null end,
          v_total, v_cash, v_change)
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(v_lines) loop
    insert into order_items(order_id, menu_item_id, item_name, unit_price, quantity,
                            sambal_option_id, sambal_name, line_total)
    values (v_order_id,
            (v_item->>'menu_item_id')::uuid,
            v_item->>'item_name',
            (v_item->>'unit_price')::integer,
            (v_item->>'quantity')::integer,
            (v_item->>'sambal_option_id')::uuid,
            v_item->>'sambal_name',
            (v_item->>'line_total')::integer);
  end loop;

  if v_discount > 0 then
    perform public.write_log('discount_applied', 'order', v_order_id,
      jsonb_build_object('amount', v_discount, 'subtotal', v_subtotal, 'reason', trim(p_discount_reason)));
  end if;

  return v_order_id;
end $$;

-- Ajukan void
create or replace function public.request_void(p_order_id uuid, p_reason text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_prof  profiles;
  v_order orders;
  v_id    uuid;
begin
  select * into v_prof from profiles where id = v_uid and is_active;
  if not found then
    raise exception 'Pengguna tidak aktif atau tidak ditemukan';
  end if;
  if p_reason is null or length(trim(p_reason)) < 5 then
    raise exception 'Alasan void minimal 5 karakter';
  end if;

  select * into v_order from orders where id = p_order_id;
  if not found then
    raise exception 'Order tidak ditemukan';
  end if;
  if v_prof.role <> 'admin' and v_order.cashier_id <> v_uid then
    raise exception 'Anda hanya bisa mengajukan void untuk order sendiri';
  end if;
  if v_order.status <> 'paid' then
    raise exception 'Order ini sudah di-void';
  end if;
  if exists (select 1 from void_requests where order_id = p_order_id and status = 'pending') then
    raise exception 'Sudah ada pengajuan void yang menunggu';
  end if;

  insert into void_requests(order_id, requested_by, reason)
  values (p_order_id, v_uid, trim(p_reason)) returning id into v_id;

  perform public.write_log('void_requested', 'order', p_order_id,
    jsonb_build_object('request_id', v_id, 'reason', trim(p_reason), 'order_number', v_order.order_number));
  return v_id;
end $$;

-- Putuskan void (admin)
create or replace function public.decide_void(p_request_id uuid, p_approve boolean, p_note text default null) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_req void_requests;
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang boleh memutuskan void';
  end if;

  select * into v_req from void_requests where id = p_request_id for update;
  if not found then
    raise exception 'Pengajuan tidak ditemukan';
  end if;
  if v_req.status <> 'pending' then
    raise exception 'Pengajuan ini sudah diputuskan';
  end if;

  update void_requests
     set status = case when p_approve then 'approved'::request_status else 'rejected'::request_status end,
         decided_by = v_uid, decided_at = now(), decision_note = p_note
   where id = p_request_id;

  if p_approve then
    update orders set status = 'void', voided_at = now()
     where id = v_req.order_id and status = 'paid';
  end if;

  perform public.write_log(
    case when p_approve then 'void_approved' else 'void_rejected' end,
    'order', v_req.order_id,
    jsonb_build_object('request_id', p_request_id, 'note', p_note));
end $$;

-- Izin eksekusi: hanya pengguna login
revoke all on function public.open_shift(integer)                          from public, anon;
revoke all on function public.close_shift(integer, text)                   from public, anon;
revoke all on function public.create_order(jsonb, order_type, order_channel, payment_method, integer, integer, text) from public, anon;
revoke all on function public.request_void(uuid, text)                     from public, anon;
revoke all on function public.decide_void(uuid, boolean, text)             from public, anon;
grant execute on function public.open_shift(integer)                          to authenticated;
grant execute on function public.close_shift(integer, text)                   to authenticated;
grant execute on function public.create_order(jsonb, order_type, order_channel, payment_method, integer, integer, text) to authenticated;
grant execute on function public.request_void(uuid, text)                     to authenticated;
grant execute on function public.decide_void(uuid, boolean, text)             to authenticated;
