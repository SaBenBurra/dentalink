-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 025: Tanımlı etiketler ve etiket önerisi
-- ═══════════════════════════════════════════════════════════════════════════════
-- tags.is_curated: sistemin önerdiği etiketler. Kullanıcı yine serbest etiket
-- ekleyebilir (create_post/update_post), ama öneriler yalnızca bu listeden.
-- Liste SQL ile genişletilir:
--   insert into public.tags (name, slug, is_curated) values ('ad', 'slug', true)
--   on conflict (slug) do update set is_curated = true;
-- suggest_tags(q): en az 2 karakter; ad ya da ASCII slug içinde arar, önce
-- başlangıcı eşleşenler, sonra kullanım sayısı. En fazla 8 sonuç.
-- İstemci tags tablosuna doğrudan yazamaz (015), is_curated yalnızca migration ile.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.tags ADD COLUMN IF NOT EXISTS is_curated boolean NOT NULL DEFAULT false;

-- Tek kelime ya da tireli (TagInput boşlukta böler); slug = Türkçe harfler ASCII.
INSERT INTO public.tags (name, slug, is_curated)
SELECT n, translate(n, 'çğıöşü', 'cgiosu'), true
  FROM unnest(ARRAY[
    -- Endodonti
    'kanal-tedavisi', 'yeniden-kanal-tedavisi', 'apikal-periodontitis', 'pulpitis',
    'pulpotomi', 'pulpa-kaplama', 'apeksifikasyon', 'rejeneratif-endodonti',
    'kalsifiye-kanal', 'eğe-kırılması', 'mta',
    -- Restoratif
    'kompozit', 'amalgam', 'inley', 'onley', 'çürük', 'sekonder-çürük',
    'beyazlatma', 'diastema', 'hassasiyet',
    -- Protetik
    'zirkonyum', 'kron', 'köprü', 'lamine-veneer', 'e-max', 'total-protez',
    'parsiyel-protez', 'implant-üstü-protez', 'dijital-ölçü', 'cad-cam',
    -- Cerrahi ve implant
    'implant', 'sinüs-lifting', 'kemik-grefti', 'gömülü-diş', 'yirmilik-diş',
    'diş-çekimi', 'apikal-rezeksiyon', 'kist', 'ortognatik-cerrahi', 'çene-kırığı',
    -- Periodontoloji
    'gingivitis', 'periodontitis', 'diş-taşı', 'kök-yüzeyi-düzleştirme',
    'gingivektomi', 'dişeti-çekilmesi', 'bağ-dokusu-grefti', 'peri-implantitis',
    -- Ortodonti
    'braket', 'şeffaf-plak', 'çapraşıklık', 'açık-kapanış', 'derin-kapanış',
    'sınıf-2', 'sınıf-3', 'pekiştirme', 'ekspansiyon',
    -- Pedodonti
    'süt-dişi', 'fissür-örtücü', 'flor-uygulaması', 'yer-tutucu', 'diş-travması',
    'erken-çocukluk-çürüğü',
    -- Radyoloji ve oral diagnoz
    'panoramik', 'periapikal-röntgen', 'cbct', 'oral-lezyon', 'liken-planus',
    'aft', 'biyopsi', 'tme-bozukluğu', 'bruksizm', 'ağız-kuruluğu', 'halitozis',
    -- Genel
    'anestezi', 'antibiyotik', 'ağrı-yönetimi', 'estetik', 'sterilizasyon', 'dus'
  ]) AS n
ON CONFLICT (slug) DO UPDATE SET is_curated = true;

CREATE OR REPLACE FUNCTION public.suggest_tags(p_query text)
RETURNS SETOF text
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  WITH q AS (
    -- LIKE jokerleri kaçırılır; slug araması için Türkçe harfler ASCII'ye.
    SELECT n AS name, translate(n, 'çğıöşü', 'cgiosu') AS slug
      FROM (SELECT replace(replace(replace(lower(btrim(p_query)),
                   '\', '\\'), '%', '\%'), '_', '\_') AS n) s
  )
  SELECT t.name
    FROM public.tags t, q
   WHERE t.is_curated
     AND char_length(btrim(p_query)) >= 2
     AND (t.name LIKE '%' || q.name || '%' OR t.slug LIKE '%' || q.slug || '%')
   ORDER BY (t.name LIKE q.name || '%' OR t.slug LIKE q.slug || '%') DESC,
            t.usage_count DESC, t.name
   LIMIT 8;
$$;

REVOKE EXECUTE ON FUNCTION public.suggest_tags(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.suggest_tags(text) TO authenticated;
