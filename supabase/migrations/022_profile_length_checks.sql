-- 022: Profil alanları için uzunluk CHECK'leri (UX-8).
-- İstemci sınırları `lib/core/constants/profile_limits.dart` ile aynı.
-- Mevcut satır ihlal ederse migration bütünüyle geri alınır.

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_full_name_length;
ALTER TABLE public.users ADD CONSTRAINT users_full_name_length
  CHECK (char_length(btrim(full_name)) BETWEEN 1 AND 60);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_bio_length;
ALTER TABLE public.users ADD CONSTRAINT users_bio_length
  CHECK (char_length(bio) <= 300);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_university_length;
ALTER TABLE public.users ADD CONSTRAINT users_university_length
  CHECK (char_length(university) <= 100);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_city_length;
ALTER TABLE public.users ADD CONSTRAINT users_city_length
  CHECK (char_length(city) <= 100);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_workplace_length;
ALTER TABLE public.users ADD CONSTRAINT users_workplace_length
  CHECK (char_length(workplace) <= 100);

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_experience_years_max;
ALTER TABLE public.users ADD CONSTRAINT users_experience_years_max
  CHECK (experience_years <= 70);
