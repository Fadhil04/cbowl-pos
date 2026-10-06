-- =====================================================================
-- seed.sql  |  DATA CONTOH. Ganti nama dan harga dengan menu asli C'Bowl.id
-- (bisa lewat layar admin nanti). Jalankan setelah 0001_init.sql.
-- =====================================================================

insert into categories(name, requires_sambal, sort_order) values
  ('Rice Bowl',       true,  1),
  ('Menu Pendamping', false, 2),
  ('Minuman',         false, 3)
on conflict (name) do nothing;

insert into sambal_options(name, sort_order) values
  ('Sambal Matah', 1),
  ('Sambal Bawang', 2),
  ('Sambal Ijo', 3)
on conflict (name) do nothing;

insert into menu_items(category_id, name, price, sort_order)
select c.id, v.name, v.price, v.sort_order
from (values
  ('Rice Bowl',       'Rice Bowl Contoh 1', 28000, 1),
  ('Rice Bowl',       'Rice Bowl Contoh 2', 30000, 2),
  ('Rice Bowl',       'Rice Bowl Contoh 3', 32000, 3),
  ('Rice Bowl',       'Rice Bowl Contoh 4', 34000, 4),
  ('Rice Bowl',       'Rice Bowl Contoh 5', 35000, 5),
  ('Rice Bowl',       'Rice Bowl Contoh 6', 36000, 6),
  ('Rice Bowl',       'Rice Bowl Contoh 7', 38000, 7),
  ('Menu Pendamping', 'Kentang Goreng',     12000, 1),
  ('Menu Pendamping', 'Tahu Crispy',        10000, 2),
  ('Minuman',         'Es Teh',              8000, 1),
  ('Minuman',         'Es Jeruk',           10000, 2)
) as v(cat, name, price, sort_order)
join categories c on c.name = v.cat;

-- =====================================================================
-- ADMIN PERTAMA (lakukan manual):
-- 1. Supabase Dashboard > Authentication > Users > Add user
--    (isi email + password, centang Auto Confirm User)
-- 2. Jalankan SQL ini dengan email yang sama:
--
-- insert into profiles(id, full_name, role)
-- select id, 'Pemilik', 'admin' from auth.users where email = 'GANTI@email.com';
--
-- Kasir berikutnya dibuat lewat layar admin aplikasi (Tugas T-12).
-- =====================================================================
