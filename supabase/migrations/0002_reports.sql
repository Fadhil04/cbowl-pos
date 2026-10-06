-- =====================================================================
-- 0002_reports.sql  |  Jalankan setelah 0001_init.sql (dipakai mulai Sprint 5)
-- Semua fungsi hanya mengembalikan data bila pemanggil adalah admin
-- (jika bukan admin, hasilnya kosong). Order berstatus 'void' TIDAK dihitung omzet.
-- =====================================================================

-- Laporan harian: satu baris per tanggal
create or replace function public.report_daily(p_from date, p_to date)
returns table (
  order_date     date,
  order_count    bigint,
  revenue        bigint,
  cash_total     bigint,
  qris_total     bigint,
  discount_total bigint,
  void_count     bigint
)
language sql stable security definer set search_path = public as $$
  select o.order_date,
         count(*) filter (where o.status = 'paid'),
         coalesce(sum(o.total) filter (where o.status = 'paid'), 0)::bigint,
         coalesce(sum(o.total) filter (where o.status = 'paid' and o.payment_method = 'cash'), 0)::bigint,
         coalesce(sum(o.total) filter (where o.status = 'paid' and o.payment_method = 'qris'), 0)::bigint,
         coalesce(sum(o.discount_amount) filter (where o.status = 'paid'), 0)::bigint,
         count(*) filter (where o.status = 'void')
    from orders o
   where public.is_admin() and o.order_date between p_from and p_to
   group by o.order_date
   order by o.order_date;
$$;

-- Menu terlaris
create or replace function public.report_top_items(p_from date, p_to date, p_limit integer default 10)
returns table (item_name text, qty_sold bigint, revenue bigint)
language sql stable security definer set search_path = public as $$
  select oi.item_name,
         sum(oi.quantity)::bigint,
         sum(oi.line_total)::bigint
    from order_items oi
    join orders o on o.id = oi.order_id
   where public.is_admin() and o.status = 'paid' and o.order_date between p_from and p_to
   group by oi.item_name
   order by sum(oi.quantity) desc, oi.item_name
   limit greatest(coalesce(p_limit, 10), 1);
$$;

-- Jam ramai (WIB)
create or replace function public.report_peak_hours(p_from date, p_to date)
returns table (hour_of_day integer, order_count bigint, revenue bigint)
language sql stable security definer set search_path = public as $$
  select extract(hour from o.created_at at time zone 'Asia/Jakarta')::integer,
         count(*),
         sum(o.total)::bigint
    from orders o
   where public.is_admin() and o.status = 'paid' and o.order_date between p_from and p_to
   group by 1
   order by 1;
$$;

-- Per kanal
create or replace function public.report_by_channel(p_from date, p_to date)
returns table (channel order_channel, order_count bigint, revenue bigint)
language sql stable security definer set search_path = public as $$
  select o.channel, count(*), sum(o.total)::bigint
    from orders o
   where public.is_admin() and o.status = 'paid' and o.order_date between p_from and p_to
   group by o.channel
   order by sum(o.total) desc;
$$;

revoke all on function public.report_daily(date, date)               from public, anon;
revoke all on function public.report_top_items(date, date, integer)  from public, anon;
revoke all on function public.report_peak_hours(date, date)          from public, anon;
revoke all on function public.report_by_channel(date, date)          from public, anon;
grant execute on function public.report_daily(date, date)               to authenticated;
grant execute on function public.report_top_items(date, date, integer)  to authenticated;
grant execute on function public.report_peak_hours(date, date)          to authenticated;
grant execute on function public.report_by_channel(date, date)          to authenticated;
