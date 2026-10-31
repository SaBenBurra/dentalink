-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 032: Etiket tekilleştirme ve genişletilmiş etiket kataloğu
-- ═══════════════════════════════════════════════════════════════════════════════
-- Aynı etiketin farklı yazımları tek etikette toplanır. Katmanlar:
--   1. tags.match_key = slug'ın tiresiz hali, UNIQUE. "e-max", "emax", "E max",
--      "E.Max" aynı anahtara (emax) düşer; Türkçe harf ve büyük/küçük farkı
--      slug'da zaten yok ("Çene Kırığı" = "cene-kirigi").
--   2. tag_aliases: eş anlamlı, kısaltma, İngilizce ve yaygın yanlış yazımlar
--      tanımlı etikete yönlenir ("rct", "root-canal" → kanal-tedavisi).
--   3. Çoğul: "-lar/-ler" ekli yazım, kökü tanımlıysa köke bağlanır
--      ("implantlar" → implant). Kök yoksa yeni etiket açılır.
--   4. suggest_tags eş anlamlıları ve yazım hatalarını (pg_trgm) da bulur,
--      sonuçta hep asıl etiketi gösterir; 3+ postta kullanılmış kullanıcı
--      etiketleri de önerilir. Kullanıcı yazarken mevcut etikete yönlenir.
--   5. Yönetim (yalnızca SQL Editor): add_curated_tags, add_tag_alias,
--      merge_tags. Kullanım: docs/SUPABASE.md §9.
-- create_post/update_post etiketleri resolve_tags ile çözer; imzaları aynı.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;

-- ─── 1. Yazım anahtarı ───────────────────────────────────────────────────────
-- İstemcideki _slugify ile aynı sonucu verir (temiz adlar için). Türkçe harfler
-- lower()'dan önce çevrilir; sonuç DB collation'ından bağımsız.
CREATE OR REPLACE FUNCTION public.tag_slug(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT btrim(regexp_replace(
           lower(translate(p_text, 'ÇĞIİÖŞÜÂÎÛçğıöşüâîû', 'cgiiosuaiucgiosuaiu')),
           '[^a-z0-9]+', '-', 'g'), '-');
$$;

CREATE OR REPLACE FUNCTION public.tag_match_key(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT replace(public.tag_slug(p_text), '-', '');
$$;

ALTER TABLE public.tags
  ADD COLUMN IF NOT EXISTS match_key text GENERATED ALWAYS AS (replace(slug, '-', '')) STORED;

-- ─── 2. Eş anlamlılar ────────────────────────────────────────────────────────
-- Bir anahtar ya etikettir ya eş anlamlı; add_tag_alias çakışan etiketi birleştirir.
CREATE TABLE IF NOT EXISTS public.tag_aliases (
  match_key  text PRIMARY KEY CHECK (match_key ~ '^[a-z0-9]+$'),
  tag_id     uuid NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tag_aliases_tag_id ON public.tag_aliases (tag_id);

-- İstemci okumaz/yazmaz; suggest_tags SECURITY DEFINER.
ALTER TABLE public.tag_aliases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.tag_aliases FROM public, anon, authenticated;

-- ─── 3. Birleştirme ──────────────────────────────────────────────────────────
-- p_from'un postları p_into'ya taşınır, p_from'un yazımı eş anlamlı olur, p_from silinir.
-- UPDATE, post başına 5 etiket trigger'ına takılmaz; sayaç sonda yeniden hesaplanır.
CREATE OR REPLACE FUNCTION public.merge_tags(p_from uuid, p_into uuid)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF p_from = p_into THEN
    RETURN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.tags WHERE id = p_into) THEN
    RAISE EXCEPTION 'merge target not found' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.post_tags SET tag_id = p_into
   WHERE tag_id = p_from
     AND post_id NOT IN (SELECT post_id FROM public.post_tags WHERE tag_id = p_into);
  DELETE FROM public.post_tags WHERE tag_id = p_from;

  UPDATE public.tag_aliases SET tag_id = p_into WHERE tag_id = p_from;
  INSERT INTO public.tag_aliases (match_key, tag_id)
  SELECT f.match_key, p_into
    FROM public.tags f, public.tags i
   WHERE f.id = p_from AND i.id = p_into AND f.match_key <> i.match_key
  ON CONFLICT (match_key) DO UPDATE SET tag_id = EXCLUDED.tag_id;

  DELETE FROM public.tags WHERE id = p_from;
  UPDATE public.tags
     SET usage_count = (SELECT count(*) FROM public.post_tags WHERE tag_id = p_into)
   WHERE id = p_into;
END;
$$;

-- Mevcut tekrarlar: aynı anahtardaki etiketler tanımlı / en çok kullanılan / en eski olana.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id, first_value(id) OVER (
             PARTITION BY match_key ORDER BY is_curated DESC, usage_count DESC, created_at
           ) AS keep_id
      FROM public.tags
  LOOP
    IF r.id <> r.keep_id THEN
      PERFORM public.merge_tags(r.id, r.keep_id);
    END IF;
  END LOOP;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS tags_match_key_key ON public.tags (match_key);

-- ─── 4. Çözümleme ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.find_tag(p_key text)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT coalesce(
    (SELECT id FROM public.tags WHERE match_key = p_key),
    (SELECT tag_id FROM public.tag_aliases WHERE match_key = p_key));
$$;

-- create_post/update_post biçimindeki jsonb → tekil etiket id'leri (sıra korunur).
-- Bilinmeyen yazım yeni etiket olur; eşzamanlı aynı yeni etiket ON CONFLICT ile tekleşir.
CREATE OR REPLACE FUNCTION public.resolve_tags(p_tags jsonb)
RETURNS uuid[]
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_tag  jsonb;
  v_name text;
  v_slug text;
  v_key  text;
  v_id   uuid;
  v_ids  uuid[] := '{}';
BEGIN
  FOR v_tag IN SELECT * FROM jsonb_array_elements(coalesce(p_tags, '[]')) LOOP
    v_name := btrim(v_tag->>'name');
    v_slug := v_tag->>'slug';
    CONTINUE WHEN v_slug IS NULL OR v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
               OR coalesce(v_name, '') = '';
    v_key := replace(v_slug, '-', '');
    v_id := public.find_tag(v_key);
    -- Çoğul yalnızca kök zaten varsa köke bağlanır ("implantlar" → implant).
    IF v_id IS NULL AND v_key ~ '^[a-z0-9]{3,}(lar|ler)$' THEN
      v_id := public.find_tag(left(v_key, -3));
    END IF;
    IF v_id IS NULL THEN
      INSERT INTO public.tags (name, slug) VALUES (v_name, v_slug) ON CONFLICT DO NOTHING;
      v_id := public.find_tag(v_key);
    END IF;
    IF v_id IS NOT NULL AND NOT v_id = ANY (v_ids) THEN
      v_ids := v_ids || v_id;
    END IF;
  END LOOP;
  RETURN v_ids;
END;
$$;

-- ─── 5. Yönetim ──────────────────────────────────────────────────────────────
-- Adı verilen etiketleri tanımlı yapar. Aynı anahtarda kullanıcı etiketi varsa
-- o etiket tanımlı yazıma çevrilir (postları korunur).
CREATE OR REPLACE FUNCTION public.add_curated_tags(p_names text[])
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_name text;
  v_slug text;
BEGIN
  FOREACH v_name IN ARRAY p_names LOOP
    v_name := lower(btrim(v_name));
    v_slug := public.tag_slug(v_name);
    IF EXISTS (SELECT 1 FROM public.tag_aliases WHERE match_key = replace(v_slug, '-', '')) THEN
      RAISE EXCEPTION 'tag % is already an alias', v_name;
    END IF;
    UPDATE public.tags SET is_curated = true, name = v_name, slug = v_slug
     WHERE match_key = replace(v_slug, '-', '');
    IF NOT FOUND THEN
      INSERT INTO public.tags (name, slug, is_curated) VALUES (v_name, v_slug, true);
    END IF;
  END LOOP;
END;
$$;

-- p_alias yazımını p_tag etiketine yönlendirir. Bu yazımla açılmış bir kullanıcı
-- etiketi varsa postlarıyla birlikte p_tag'e birleştirilir. Tanımlı bir etiket
-- eş anlamlı yapılmaz (önce is_curated = false).
CREATE OR REPLACE FUNCTION public.add_tag_alias(p_alias text, p_tag text)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_key     text := public.tag_match_key(p_alias);
  v_into    uuid;
  v_from    uuid;
  v_curated boolean;
BEGIN
  SELECT id INTO v_into FROM public.tags WHERE match_key = public.tag_match_key(p_tag);
  IF v_into IS NULL THEN
    RAISE EXCEPTION 'tag % not found', p_tag;
  END IF;
  IF v_key = '' THEN
    RAISE EXCEPTION 'empty alias';
  END IF;

  SELECT id, is_curated INTO v_from, v_curated FROM public.tags WHERE match_key = v_key;
  IF v_from = v_into THEN
    RETURN;
  END IF;
  IF v_curated THEN
    RAISE EXCEPTION 'alias % is a curated tag', p_alias;
  END IF;
  IF v_from IS NOT NULL THEN
    PERFORM public.merge_tags(v_from, v_into);
  END IF;

  INSERT INTO public.tag_aliases (match_key, tag_id) VALUES (v_key, v_into)
  ON CONFLICT (match_key) DO UPDATE SET tag_id = EXCLUDED.tag_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.tag_slug(text), public.tag_match_key(text),
  public.merge_tags(uuid, uuid), public.find_tag(text), public.resolve_tags(jsonb),
  public.add_curated_tags(text[]), public.add_tag_alias(text, text)
  FROM public, anon, authenticated;

-- ─── 6. create_post / update_post (015, 016) ─────────────────────────────────
-- Gövdeler aynı; yalnızca etiket bölümü resolve_tags kullanıyor.
CREATE OR REPLACE FUNCTION public.create_post(
  p_type        public.post_type,
  p_title       text,
  p_content     text,
  p_branch      public.dental_branch DEFAULT NULL,
  p_image_paths text[] DEFAULT '{}',
  p_tags        jsonb  DEFAULT '[]'   -- [{"name": "İmplant", "slug": "implant"}, …]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_title   text := btrim(p_title);
  v_content text := btrim(p_content);
  v_paths   text[] := coalesce(p_image_paths, '{}');
  v_branch  public.dental_branch;
  v_post_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF v_title IS NULL OR v_title = '' OR v_content IS NULL OR v_content = '' THEN
    RAISE EXCEPTION 'title and content required' USING ERRCODE = '22023';
  END IF;
  IF p_type = 'case' AND p_branch IS NULL THEN
    RAISE EXCEPTION 'branch required for case' USING ERRCODE = '22023';
  END IF;
  -- Branş yalnızca vakada tutulur.
  IF p_type = 'case' THEN
    v_branch := p_branch;
  END IF;
  -- CASE…END kullanılmıyor: CLI'ın SQL bölücüsü fonksiyon gövdesinde onu yanlış ayırıyor.
  IF cardinality(v_paths) > 10 OR (p_type = 'question' AND cardinality(v_paths) > 4) THEN
    RAISE EXCEPTION 'too many images' USING ERRCODE = '22023';
  END IF;
  -- Her yol, bu kullanıcının post-images'a yüklediği bir nesne olmalı.
  IF EXISTS (
    SELECT 1 FROM unnest(v_paths) AS p(path)
     WHERE NOT EXISTS (
       SELECT 1 FROM storage.objects o
        WHERE o.bucket_id = 'post-images'
          AND o.name = p.path
          AND (storage.foldername(o.name))[1] = v_uid::text
     )
  ) THEN
    RAISE EXCEPTION 'invalid image path' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.posts (user_id, type, title, content, branch)
  VALUES (v_uid, p_type, v_title, v_content, v_branch)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);

  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT v_post_id, tag_id FROM unnest(public.resolve_tags(p_tags)) AS tag_id
  ON CONFLICT DO NOTHING;

  RETURN v_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id uuid,
  p_title   text,
  p_content text,
  p_branch  public.dental_branch DEFAULT NULL,
  p_tags    jsonb DEFAULT '[]'   -- create_post ile aynı biçim
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_title   text := btrim(p_title);
  v_content text := btrim(p_content);
  v_type    public.post_type;
  v_branch  public.dental_branch;
  v_tag_ids uuid[];
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT type INTO v_type FROM public.posts
   WHERE id = p_post_id AND user_id = v_uid
   FOR UPDATE;
  IF NOT FOUND THEN
    -- Yok ya da başkasının: ikisi de istemcide "bulunamadı".
    RAISE EXCEPTION 'post not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_title IS NULL OR v_title = '' OR v_content IS NULL OR v_content = '' THEN
    RAISE EXCEPTION 'title and content required' USING ERRCODE = '22023';
  END IF;
  IF v_type = 'case' AND p_branch IS NULL THEN
    RAISE EXCEPTION 'branch required for case' USING ERRCODE = '22023';
  END IF;
  -- Branş yalnızca vakada tutulur. (CASE…END yok: bkz. SUPABASE.md)
  IF v_type = 'case' THEN
    v_branch := p_branch;
  END IF;

  UPDATE public.posts
     SET title = v_title, content = v_content, branch = v_branch
   WHERE id = p_post_id;

  -- Etiketler: yeni sette olmayan bağlar silinir, yeniler eklenir.
  v_tag_ids := public.resolve_tags(p_tags);
  DELETE FROM public.post_tags
   WHERE post_id = p_post_id AND tag_id <> ALL (v_tag_ids);
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT p_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;
END;
$$;

-- ─── 7. Öneri ────────────────────────────────────────────────────────────────
-- Sıra: 0 tam eşleşme, 1 eş anlamlı tam, 2 baştan, 3 eş anlamlı baştan,
-- 4 içinde, 5 yazım hatası (trigram ≥ 0.4, en az 4 harf). Hep asıl etiket döner.
-- shortcut: LIKE '%…%' ve similarity tags'i baştan tarar; birkaç on bin etikette
-- gin_trgm_ops index'e geç.
CREATE OR REPLACE FUNCTION public.suggest_tags(p_query text)
RETURNS SETOF text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH q AS (SELECT public.tag_match_key(p_query) AS k),
  hits AS (
    SELECT t.id, 2 * ((t.match_key <> q.k)::int + (t.match_key NOT LIKE q.k || '%')::int) AS rank
      FROM public.tags t, q
     WHERE t.match_key LIKE '%' || q.k || '%'
    UNION ALL
    SELECT a.tag_id, 1 + 2 * (a.match_key <> q.k)::int
      FROM public.tag_aliases a, q
     WHERE a.match_key LIKE q.k || '%'
    UNION ALL
    SELECT t.id, 5
      FROM public.tags t, q
     WHERE char_length(q.k) >= 4 AND extensions.similarity(t.match_key, q.k) >= 0.4
  )
  SELECT t.name
    FROM (SELECT id, min(rank) AS rank FROM hits GROUP BY id) h
    JOIN public.tags t ON t.id = h.id, q
   WHERE char_length(q.k) >= 2
     -- Kullanıcı etiketi en az 3 postta geçtiyse önerilir; tek seferlik yazımlar önerilmez.
     AND (t.is_curated OR t.usage_count >= 3)
   ORDER BY h.rank, t.is_curated DESC, t.usage_count DESC, t.name
   LIMIT 8;
$$;

REVOKE EXECUTE ON FUNCTION public.suggest_tags(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.suggest_tags(text) TO authenticated;

-- ─── 8. Katalog ──────────────────────────────────────────────────────────────
-- 025'teki ~80 etikete ek. Tek kelime ya da tireli (TagInput boşlukta böler), ≤ 30 harf.
SELECT public.add_curated_tags(ARRAY[
  -- Endodonti
  'geri-dönüşümlü-pulpitis', 'geri-dönüşümsüz-pulpitis', 'pulpa-nekrozu', 'apikal-apse',
  'kondanse-osteitis', 'flare-up', 'apeks-bulucu', 'döner-alet', 'resiprokal-sistem',
  'nikel-titanyum', 'kanal-irrigasyonu', 'sodyum-hipoklorit', 'edta', 'klorheksidin',
  'kalsiyum-hidroksit', 'biyoseramik', 'lateral-kondensasyon', 'vertikal-kondensasyon',
  'tek-kon-tekniği', 'güta-perka', 'kanal-patı', 'perforasyon', 'basamak-oluşumu',
  'mb2-kanalı', 'c-şekilli-kanal', 'dens-invaginatus', 'internal-rezorpsiyon',
  'eksternal-rezorpsiyon', 'servikal-rezorpsiyon', 'endo-perio-lezyon', 'dikey-kök-kırığı',
  'çatlak-diş-sendromu', 'fiber-post', 'döküm-post', 'kor-yapımı', 'mikroskop',
  'endodontik-cerrahi', 'pulpektomi', 'apeksogenezis', 'vital-pulpa-tedavisi', 'biyodentin',
  'kanal-şekillendirme', 'çalışma-boyu', 'kanal-tedavisi-ağrısı', 'endodontik-acil',
  -- Restoratif
  'bulk-fill', 'akışkan-kompozit', 'cam-iyonomer', 'rezin-modifiye-cam-iyonomer',
  'adeziv-sistem', 'total-etch', 'self-etch', 'universal-adeziv', 'renk-seçimi',
  'tabakalama-tekniği', 'sınıf-1-kavite', 'sınıf-2-kavite', 'sınıf-3-kavite', 'sınıf-4-kavite',
  'sınıf-5-kavite', 'abfraksiyon', 'erozyon', 'abrazyon', 'atrizyon', 'kontakt-noktası',
  'matris-bant', 'rubber-dam', 'polisaj', 'minimal-invaziv', 'çürük-risk-analizi',
  'remineralizasyon', 'rezin-infiltrasyon', 'mih', 'florozis', 'beyaz-nokta-lezyonu',
  'ofis-tipi-beyazlatma', 'ev-tipi-beyazlatma', 'devital-beyazlatma', 'kompozit-veneer',
  'direkt-restorasyon', 'indirekt-restorasyon', 'kavite-preparasyonu', 'endokron',
  'renklenme', 'gülüş-tasarımı', 'dijital-gülüş-tasarımı', 'mock-up', 'diş-kırığı',
  'restorasyon-yenileme',
  -- Protetik
  'metal-seramik', 'tam-seramik', 'monolitik-zirkonyum', 'geçici-kron', 'hassas-bağlantı',
  'teleskop-protez', 'overdenture', 'immediat-protez', 'gece-plağı', 'okluzal-splint',
  'dikey-boyut', 'sentrik-ilişki', 'artikülatör', 'yüz-arkı', 'ölçü-maddesi',
  'silikon-ölçü', 'aljinat', 'ağız-içi-tarayıcı', 'adeziv-köprü', 'maryland-köprü',
  'kantilever-köprü', 'post-kor', 'siman', 'rezin-siman', 'simantasyon',
  'protez-stomatiti', 'kaide-yenileme', 'akrilik', 'iskelet-protez', 'all-on-4',
  'hibrit-protez', 'vidalı-protez', 'simante-protez', 'abutment', 'özel-abutment',
  'ti-base', '3d-yazıcı', 'frezeleme', 'diş-teknisyeni', 'laboratuvar', 'bitiş-çizgisi',
  'retraksiyon-ipi', 'okluzyon', 'okluzal-ayarlama', 'aşınmış-dentisyon',
  'tam-ağız-rehabilitasyonu', 'obturatör', 'maksillofasiyal-protez', 'porselen-kırığı',
  -- Cerrahi ve implant
  'immediat-implant', 'immediat-yükleme', 'osseointegrasyon', 'kemik-rejenerasyonu',
  'membran', 'blok-greft', 'otojen-greft', 'ksenogreft', 'allogreft', 'prf', 'prp',
  'soket-koruma', 'kret-genişletme', 'kret-split', 'dikey-kemik-artırma',
  'zigomatik-implant', 'kısa-implant', 'dar-çaplı-implant', 'cerrahi-rehber',
  'navigasyonlu-cerrahi', 'implant-başarısızlığı', 'implant-kırığı', 'vida-gevşemesi',
  'yumuşak-doku-yönetimi', 'serbest-dişeti-grefti', 'internal-sinüs-lifting',
  'lateral-sinüs-lifting', 'oroantral-fistül', 'kuru-soket', 'kanama-kontrolü',
  'antikoagülan', 'bifosfonat', 'mronj', 'osteoradyonekroz', 'osteomiyelit',
  'odontojenik-enfeksiyon', 'apse-drenajı', 'selülit', 'perikoronit', 'koronektomi',
  'gömülü-kanin', 'ostektomi', 'flep-tasarımı', 'sütur', 'frenektomi', 'vestibüloplasti',
  'alveoloplasti', 'torus', 'eksostoz', 'kist-enükleasyonu', 'marsüpyalizasyon',
  'keratokist', 'ameloblastoma', 'odontoma', 'dentigeröz-kist', 'radiküler-kist',
  'distraksiyon-osteogenezi', 'le-fort', 'bsso', 'genioplasti', 'yarık-damak',
  'artrosentez', 'botoks', 'hyaluronik-asit', 'sedasyon', 'genel-anestezi',
  'lokal-anestezi', 'mandibular-blok', 'sinir-hasarı', 'parestezi', 'trismus',
  'kök-ucu-kalması', 'implant-planlama',
  -- Periodontoloji
  'agresif-periodontitis', 'periodontal-apse', 'cep-derinliği', 'ataşman-kaybı',
  'furkasyon', 'mobilite', 'splintleme', 'kron-boyu-uzatma', 'gingivoplasti',
  'flep-operasyonu', 'rejeneratif-periodontal-tedavi', 'emdogain', 'gtr', 'tünel-tekniği',
  'koronal-kaydırma-flebi', 'pembe-estetik', 'dişeti-gülümsemesi', 'dişeti-büyümesi',
  'nekrotizan-gingivitis', 'periodontal-idame', 'diyabet', 'sigara', 'lazer',
  'ozon-tedavisi', 'peri-implant-mukozit', 'keratinize-doku', 'dişeti-fenotipi',
  'dişeti-depigmentasyonu', 'siyah-üçgen', 'dişeti-kanaması', 'periodontal-cerrahi',
  -- Ortodonti
  'sınıf-1', 'çapraz-kapanış', 'makas-kapanış', 'overjet', 'overbite', 'ön-çapraz-kapanış',
  'seramik-braket', 'lingual-ortodonti', 'self-ligating', 'mini-vida',
  'hızlı-üst-çene-genişletme', 'marpe', 'fonksiyonel-aparey', 'twin-block', 'headgear',
  'yüz-maskesi', 'sefalometri', 'ankraj', 'çekimli-tedavi', 'çekimsiz-tedavi',
  'kanin-retraksiyonu', 'ark-teli', 'elastik', 'interproksimal-aşındırma',
  'kök-rezorpsiyonu', 'nüks', 'erken-ortodontik-tedavi', 'interseptif-ortodonti',
  'parmak-emme', 'ağız-solunumu', 'dil-itme', 'orta-hat-kayması', 'hipodonti',
  'süpernümerer-diş', 'meziodens', 'dijital-ortodonti', 'ortodontik-cerrahi-hazırlık',
  'yetişkin-ortodontisi', 'diş-sürme-bozukluğu',
  -- Pedodonti
  'davranış-yönetimi', 'diş-hekimi-korkusu', 'paslanmaz-çelik-kuron', 'strip-kron',
  'avülsiyon', 'replantasyon', 'lüksasyon', 'intrüzyon', 'kron-kırığı', 'kök-kırığı',
  'diş-sürmesi', 'erken-süt-dişi-kaybı', 'ankiloz', 'amelogenezis-imperfekta',
  'dentinogenezis-imperfekta', 'özel-gereksinimli-hasta', 'gümüş-diamin-florür',
  'hall-tekniği', 'atravmatik-restoratif-tedavi', 'süt-dişi-kanal-tedavisi',
  'karışık-dişlenme', 'çocuk-hasta',
  -- Radyoloji ve oral diagnoz
  'bitewing', 'sefalometrik-röntgen', 'okluzal-röntgen', 'radyasyon-güvenliği',
  'radyolüsent-lezyon', 'radyoopak-lezyon', 'lökoplaki', 'eritroplaki', 'oral-kanser',
  'skuamöz-hücreli-karsinom', 'premalign-lezyon', 'oral-kandidiyazis', 'herpes',
  'mukosel', 'ranula', 'fibrom', 'piyojenik-granülom', 'hemanjiyom', 'pemfigus',
  'pemfigoid', 'eritema-multiforme', 'coğrafik-dil', 'tükürük-bezi', 'siyalolit',
  'sjögren-sendromu', 'yanan-ağız-sendromu', 'trigeminal-nevralji', 'orofasiyal-ağrı',
  'miyofasiyal-ağrı', 'disk-deplasmanı', 'ayırıcı-tanı', 'sistemik-hastalık', 'gebelik',
  'hipertansiyon', 'kalp-hastalığı', 'kemoterapi', 'radyoterapi', 'ilaç-etkileşimi',
  'alerji', 'kanama-bozukluğu',
  -- Genel
  'enfeksiyon-kontrolü', 'dezenfeksiyon', 'otoklav', 'klinik-fotoğrafçılık',
  'hasta-iletişimi', 'onam-formu', 'malpraktis', 'klinik-yönetimi', 'ergonomi',
  'diş-hekimliği-eğitimi', 'staj', 'uzmanlık', 'kariyer', 'yeni-mezun', 'akademi',
  'makale', 'literatür', 'kongre', 'kurs', 'malzeme', 'lup', 'yapay-zeka',
  'dijital-diş-hekimliği', 'acil-durum', 'senkop', 'anafilaksi', 'ağız-hijyeni',
  'diş-fırçalama', 'diş-ipi', 'ağız-gargarası', 'koruyucu-diş-hekimliği', 'yaşlı-hasta',
  'analjezik', 'nsaid', 'antibiyotik-profilaksisi', 'vaka-sunumu', 'ikinci-görüş',
  'tedavi-planlama', 'komplikasyon', 'uzun-dönem-takip', 'öncesi-sonrası'
]);

-- Eş anlamlı / kısaltma / İngilizce / yanlış yazım → asıl etiket.
-- Yalnızca tire, boşluk, Türkçe harf ya da büyük harf farkı olanlar gerekmez (match_key).
SELECT public.add_tag_alias(a, t) FROM (VALUES
  -- Endodonti
  ('rct', 'kanal-tedavisi'), ('root-canal', 'kanal-tedavisi'), ('kanal', 'kanal-tedavisi'),
  ('kanal-dolgusu', 'kanal-tedavisi'), ('endo', 'kanal-tedavisi'),
  ('endodontik-tedavi', 'kanal-tedavisi'),
  ('retreatment', 'yeniden-kanal-tedavisi'), ('retreat', 'yeniden-kanal-tedavisi'),
  ('kanal-yenileme', 'yeniden-kanal-tedavisi'), ('revizyon', 'yeniden-kanal-tedavisi'),
  ('pulpa-kuafajı', 'pulpa-kaplama'), ('kuafaj', 'pulpa-kaplama'),
  ('direkt-kuafaj', 'pulpa-kaplama'), ('pulp-capping', 'pulpa-kaplama'),
  ('kırık-eğe', 'eğe-kırılması'), ('eğe-kırığı', 'eğe-kırılması'),
  ('alet-kırılması', 'eğe-kırılması'), ('separated-instrument', 'eğe-kırılması'),
  ('kalsifikasyon', 'kalsifiye-kanal'), ('oblitere-kanal', 'kalsifiye-kanal'),
  ('mineral-trioksit-agregat', 'mta'),
  ('naocl', 'sodyum-hipoklorit'), ('hipoklorit', 'sodyum-hipoklorit'),
  ('chx', 'klorheksidin'), ('caoh2', 'kalsiyum-hidroksit'),
  ('niti', 'nikel-titanyum'), ('nitinol', 'nikel-titanyum'),
  ('gutta-percha', 'güta-perka'), ('gutta-perka', 'güta-perka'), ('güta', 'güta-perka'),
  ('mb2', 'mb2-kanalı'), ('cam-fiber-post', 'fiber-post'), ('biodentine', 'biyodentin'),
  ('endocrown', 'endokron'), ('apeks-locator', 'apeks-bulucu'),
  ('dental-mikroskop', 'mikroskop'), ('cracked-tooth', 'çatlak-diş-sendromu'),
  -- Restoratif
  ('kompozit-dolgu', 'kompozit'), ('beyaz-dolgu', 'kompozit'), ('composite', 'kompozit'),
  ('amalgam-dolgu', 'amalgam'), ('gümüş-dolgu', 'amalgam'),
  ('inlay', 'inley'), ('onlay', 'onley'),
  ('karyes', 'çürük'), ('caries', 'çürük'), ('diş-çürüğü', 'çürük'),
  ('dentin-hassasiyeti', 'hassasiyet'), ('diş-hassasiyeti', 'hassasiyet'),
  ('hassas-diş', 'hassasiyet'),
  ('bleaching', 'beyazlatma'), ('whitening', 'beyazlatma'), ('diş-beyazlatma', 'beyazlatma'),
  ('gic', 'cam-iyonomer'), ('cis', 'cam-iyonomer'), ('glass-ionomer', 'cam-iyonomer'),
  ('cam-ionomer', 'cam-iyonomer'), ('rmgic', 'rezin-modifiye-cam-iyonomer'),
  ('bonding', 'adeziv-sistem'), ('bond', 'adeziv-sistem'),
  ('lastik-örtü', 'rubber-dam'), ('koferdam', 'rubber-dam'), ('dental-dam', 'rubber-dam'),
  ('molar-insizör-hipomineralizasyonu', 'mih'),
  ('white-spot', 'beyaz-nokta-lezyonu'),
  ('smile-design', 'gülüş-tasarımı'), ('gülümseme-tasarımı', 'gülüş-tasarımı'),
  ('dsd', 'dijital-gülüş-tasarımı'),
  -- Protetik
  ('zirkon', 'zirkonyum'), ('zirkonya', 'zirkonyum'), ('zirconia', 'zirkonyum'),
  ('zirkonyum-kron', 'zirkonyum'),
  ('emaks', 'e-max'), ('lityum-disilikat', 'e-max'),
  ('veneer', 'lamine-veneer'), ('laminate', 'lamine-veneer'), ('lamina', 'lamine-veneer'),
  ('yaprak-porselen', 'lamine-veneer'), ('porselen-lamina', 'lamine-veneer'),
  ('kuron', 'kron'), ('crown', 'kron'), ('porselen-kron', 'kron'),
  ('bridge', 'köprü'),
  ('tam-protez', 'total-protez'), ('damak-protezi', 'total-protez'),
  ('takma-diş', 'total-protez'),
  ('bölümlü-protez', 'parsiyel-protez'), ('yarım-protez', 'parsiyel-protez'),
  ('implant-destekli-protez', 'implant-üstü-protez'),
  ('ağız-içi-tarama', 'dijital-ölçü'), ('intraoral-tarama', 'dijital-ölçü'),
  ('cerec', 'cad-cam'),
  ('metal-destekli-porselen', 'metal-seramik'), ('porselen-metal', 'metal-seramik'),
  ('full-seramik', 'tam-seramik'), ('all-ceramic', 'tam-seramik'),
  ('geçici', 'geçici-kron'), ('geçici-diş', 'geçici-kron'),
  ('nightguard', 'gece-plağı'), ('bruksizm-plağı', 'gece-plağı'),
  ('stabilizasyon-splinti', 'okluzal-splint'),
  ('intraoral-tarayıcı', 'ağız-içi-tarayıcı'), ('maryland', 'maryland-köprü'),
  ('dayanak', 'abutment'), ('abutmant', 'abutment'),
  ('3d-baskı', '3d-yazıcı'), ('üç-boyutlu-yazıcı', '3d-yazıcı'),
  ('teknisyen', 'diş-teknisyeni'),
  ('all-on-four', 'all-on-4'), ('rebazaj', 'kaide-yenileme'), ('besleme', 'kaide-yenileme'),
  -- Cerrahi ve implant
  ('implantoloji', 'implant'), ('dental-implant', 'implant'), ('implant-tedavisi', 'implant'),
  ('sinüs-lift', 'sinüs-lifting'),
  ('sinüs-yükseltme', 'sinüs-lifting'), ('sinüs-greftleme', 'sinüs-lifting'),
  ('greft', 'kemik-grefti'), ('kemik-tozu', 'kemik-grefti'), ('bone-graft', 'kemik-grefti'),
  ('gbr', 'kemik-rejenerasyonu'),
  ('yirmilik', 'yirmilik-diş'), ('20lik', 'yirmilik-diş'), ('akıl-dişi', 'yirmilik-diş'),
  ('üçüncü-molar', 'yirmilik-diş'), ('3-molar', 'yirmilik-diş'),
  ('wisdom-tooth', 'yirmilik-diş'),
  ('impakte-diş', 'gömülü-diş'), ('gömülü', 'gömülü-diş'),
  ('çekim', 'diş-çekimi'), ('ekstraksiyon', 'diş-çekimi'), ('extraction', 'diş-çekimi'),
  ('rezeksiyon', 'apikal-rezeksiyon'), ('apikoektomi', 'apikal-rezeksiyon'),
  ('apisektomi', 'apikal-rezeksiyon'),
  ('ortognatik', 'ortognatik-cerrahi'),
  ('immediate-implant', 'immediat-implant'), ('anında-implant', 'immediat-implant'),
  ('immediate-loading', 'immediat-yükleme'), ('anında-yükleme', 'immediat-yükleme'),
  ('osteointegrasyon', 'osseointegrasyon'),
  ('i-prf', 'prf'), ('a-prf', 'prf'),
  ('ridge-split', 'kret-split'), ('soket-prezervasyonu', 'soket-koruma'),
  ('socket-preservation', 'soket-koruma'),
  ('alveolit', 'kuru-soket'), ('alveolar-osteitis', 'kuru-soket'),
  ('dry-socket', 'kuru-soket'),
  ('bronj', 'mronj'), ('orn', 'osteoradyonekroz'), ('bisfosfonat', 'bifosfonat'),
  ('kan-sulandırıcı', 'antikoagülan'),
  ('perikoronitis', 'perikoronit'), ('frenulektomi', 'frenektomi'),
  ('okk', 'keratokist'), ('odontojenik-keratokist', 'keratokist'),
  ('yarık-dudak-damak', 'yarık-damak'), ('dudak-damak-yarığı', 'yarık-damak'),
  ('botulinum', 'botoks'), ('botox', 'botoks'),
  ('bilinçli-sedasyon', 'sedasyon'), ('uyuşukluk', 'parestezi'),
  ('fgg', 'serbest-dişeti-grefti'),
  -- Periodontoloji
  ('gingivit', 'gingivitis'), ('periodontit', 'periodontitis'),
  ('paradontoz', 'periodontitis'), ('piyore', 'periodontitis'),
  ('tartar', 'diş-taşı'), ('detertraj', 'diş-taşı'), ('diş-taşı-temizliği', 'diş-taşı'),
  ('scaling', 'diş-taşı'),
  ('küretaj', 'kök-yüzeyi-düzleştirme'), ('srp', 'kök-yüzeyi-düzleştirme'),
  ('root-planing', 'kök-yüzeyi-düzleştirme'),
  ('resesyon', 'dişeti-çekilmesi'), ('recession', 'dişeti-çekilmesi'),
  ('ctg', 'bağ-dokusu-grefti'), ('bdg', 'bağ-dokusu-grefti'),
  ('cal', 'ataşman-kaybı'), ('furkasyon-defekti', 'furkasyon'),
  ('sallanan-diş', 'mobilite'), ('crown-lengthening', 'kron-boyu-uzatma'),
  ('emd', 'emdogain'), ('gummy-smile', 'dişeti-gülümsemesi'),
  ('dişeti-gülüşü', 'dişeti-gülümsemesi'), ('laser', 'lazer'),
  ('black-triangle', 'siyah-üçgen'), ('dişeti-hiperplazisi', 'dişeti-büyümesi'),
  -- Ortodonti
  ('tel', 'braket'), ('diş-teli', 'braket'), ('braces', 'braket'),
  ('invisalign', 'şeffaf-plak'), ('aligner', 'şeffaf-plak'), ('clear-aligner', 'şeffaf-plak'),
  ('plak-tedavisi', 'şeffaf-plak'), ('şeffaf-aparey', 'şeffaf-plak'),
  ('çapraşık-diş', 'çapraşıklık'), ('crowding', 'çapraşıklık'),
  ('open-bite', 'açık-kapanış'), ('deep-bite', 'derin-kapanış'),
  ('crossbite', 'çapraz-kapanış'), ('scissor-bite', 'makas-kapanış'),
  ('class-1', 'sınıf-1'), ('klas-1', 'sınıf-1'), ('sınıf-i', 'sınıf-1'),
  ('class-2', 'sınıf-2'), ('klas-2', 'sınıf-2'), ('sınıf-ii', 'sınıf-2'),
  ('class-3', 'sınıf-3'), ('klas-3', 'sınıf-3'), ('sınıf-iii', 'sınıf-3'),
  ('retainer', 'pekiştirme'), ('retansiyon', 'pekiştirme'),
  ('expansion', 'ekspansiyon'), ('genişletme', 'ekspansiyon'),
  ('rme', 'hızlı-üst-çene-genişletme'), ('rpe', 'hızlı-üst-çene-genişletme'),
  ('kendinden-bağlanan-braket', 'self-ligating'),
  ('mini-implant', 'mini-vida'), ('tad', 'mini-vida'),
  ('facemask', 'yüz-maskesi'), ('sefalometrik-analiz', 'sefalometri'),
  ('ipr', 'interproksimal-aşındırma'), ('stripping', 'interproksimal-aşındırma'),
  ('diş-eksikliği', 'hipodonti'), ('agenezi', 'hipodonti'),
  ('supernumerary', 'süpernümerer-diş'), ('fazla-diş', 'süpernümerer-diş'),
  ('mezyodens', 'meziodens'),
  -- Pedodonti
  ('sealant', 'fissür-örtücü'), ('fissür-sealant', 'fissür-örtücü'),
  ('flor', 'flor-uygulaması'), ('florür', 'flor-uygulaması'),
  ('fluoride', 'flor-uygulaması'), ('flor-vernik', 'flor-uygulaması'),
  ('space-maintainer', 'yer-tutucu'),
  ('travma', 'diş-travması'), ('dental-travma', 'diş-travması'),
  ('biberon-çürüğü', 'erken-çocukluk-çürüğü'), ('ecc', 'erken-çocukluk-çürüğü'),
  ('ssc', 'paslanmaz-çelik-kuron'), ('paslanmaz-çelik-kron', 'paslanmaz-çelik-kuron'),
  ('sdf', 'gümüş-diamin-florür'), ('art', 'atravmatik-restoratif-tedavi'),
  ('avulsion', 'avülsiyon'), ('engelli-hasta', 'özel-gereksinimli-hasta'),
  ('dental-anksiyete', 'diş-hekimi-korkusu'), ('dental-fobi', 'diş-hekimi-korkusu'),
  -- Radyoloji ve oral diagnoz
  ('panoramik-röntgen', 'panoramik'), ('panorex', 'panoramik'), ('opg', 'panoramik'),
  ('periapikal', 'periapikal-röntgen'),
  ('dvt', 'cbct'), ('konik-ışınlı-bt', 'cbct'), ('tomografi', 'cbct'),
  ('3d-tomografi', 'cbct'), ('dental-tomografi', 'cbct'),
  ('liken', 'liken-planus'), ('olp', 'liken-planus'), ('oral-liken-planus', 'liken-planus'),
  ('afta', 'aft'), ('aftöz-stomatit', 'aft'), ('ras', 'aft'),
  ('tme', 'tme-bozukluğu'), ('tmj', 'tme-bozukluğu'), ('tmd', 'tme-bozukluğu'),
  ('çene-eklemi', 'tme-bozukluğu'), ('tme-ağrısı', 'tme-bozukluğu'),
  ('diş-sıkma', 'bruksizm'), ('diş-gıcırdatma', 'bruksizm'), ('bruxism', 'bruksizm'),
  ('kserostomi', 'ağız-kuruluğu'), ('xerostomia', 'ağız-kuruluğu'),
  ('ağız-kokusu', 'halitozis'),
  ('kanatlı-film', 'bitewing'), ('ağız-kanseri', 'oral-kanser'),
  ('scc', 'skuamöz-hücreli-karsinom'),
  ('pamukçuk', 'oral-kandidiyazis'), ('kandida', 'oral-kandidiyazis'),
  ('kandidiyazis', 'oral-kandidiyazis'),
  ('uçuk', 'herpes'), ('herpes-labialis', 'herpes'),
  ('bms', 'yanan-ağız-sendromu'), ('trigeminal-nöralji', 'trigeminal-nevralji'),
  ('hamilelik', 'gebelik'), ('hamile-hasta', 'gebelik'),
  ('şeker-hastalığı', 'diyabet'), ('diabetes', 'diyabet'),
  -- Genel
  ('uyuşturma', 'anestezi'),
  ('steril', 'sterilizasyon'), ('infection-control', 'enfeksiyon-kontrolü'),
  ('dental-fotoğrafçılık', 'klinik-fotoğrafçılık'), ('dental-fotoğraf', 'klinik-fotoğrafçılık'),
  ('loupe', 'lup'), ('büyüteç', 'lup'),
  ('ai', 'yapay-zeka'), ('yz', 'yapay-zeka'),
  ('anafilaktik-şok', 'anafilaksi'), ('bayılma', 'senkop'),
  ('ağız-bakımı', 'ağız-hijyeni'), ('gargara', 'ağız-gargarası'),
  ('nsaii', 'nsaid'), ('nsai', 'nsaid'), ('ağrı-kesici', 'analjezik'),
  ('geriatri', 'yaşlı-hasta'), ('geriatrik-hasta', 'yaşlı-hasta'),
  ('dus-sınavı', 'dus'), ('vaka-raporu', 'vaka-sunumu'),
  ('before-after', 'öncesi-sonrası')
) AS v(a, t);
