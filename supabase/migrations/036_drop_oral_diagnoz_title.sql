-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 036: "Oral Diagnoz Uzmanı" unvanı kaldırıldı
-- ═══════════════════════════════════════════════════════════════════════════════
-- Postgres enum'dan değer silmeyi desteklemez; tip yeniden oluşturulur. Bu
-- unvandaki kullanıcılar kolon varsayılanı 'dis_hekimi'ye taşınır. dental_branch
-- tipindeki 'oral_diagnoz_uzmani' (branş) bu migration'dan etkilenmez.
-- ═══════════════════════════════════════════════════════════════════════════════

UPDATE public.users SET title = 'dis_hekimi' WHERE title = 'oral_diagnoz_uzmani';

ALTER TYPE public.user_title RENAME TO user_title_old;

CREATE TYPE public.user_title AS ENUM (
  'ogrenci',
  'dis_hekimi',
  'endodontist',
  'ortodontist',
  'periodontolog',
  'protez_uzmani',
  'pedodontist',
  'agiz_dis_cene_cerrahi',
  'agiz_dis_cene_radyologu',
  'restoratif_dis_tedavisi_uzmani'
);

ALTER TABLE public.users
  ALTER COLUMN title DROP DEFAULT,
  ALTER COLUMN title TYPE public.user_title USING title::text::public.user_title,
  ALTER COLUMN title SET DEFAULT 'dis_hekimi';

DROP TYPE public.user_title_old;
