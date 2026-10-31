-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 033: Tedavi türleri
-- ═══════════════════════════════════════════════════════════════════════════════
-- Her branşın tanımlı tedavi türleri var; her tür bir tanımlı etikete bağlı.
-- Vakada tedavi türü zorunlu ve branşla uyumlu olmalı; türün etiketi postta
-- her zaman bulunur (create_post/update_post sunucuda ekler, kullanıcı kaldıramaz).
-- Liste istemcide TreatmentType enum'unda da var (lib/data/models/enums.dart);
-- test/data/models/treatment_type_test.dart ikisinin aynı olduğunu denetler.
-- Bağlı etiket silinemez/birleştirilemez (FK); önce türün tag_id'si değiştirilir.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.treatment_types (
  code   text PRIMARY KEY,
  branch public.dental_branch NOT NULL,
  tag_id uuid NOT NULL REFERENCES public.tags(id)
);

-- İstemci okumaz (liste enum'da); RPC'ler SECURITY DEFINER.
ALTER TABLE public.treatment_types ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.treatment_types FROM public, anon, authenticated;

-- code = etiketin slug'ı. Etiket 025/032'de tanımlı olmalı.
INSERT INTO public.treatment_types (code, branch, tag_id)
SELECT v.code, v.branch::public.dental_branch, t.id
  FROM (VALUES
    -- Endodonti
    ('kanal-tedavisi', 'endodontist'),
    ('yeniden-kanal-tedavisi', 'endodontist'),
    ('vital-pulpa-tedavisi', 'endodontist'),
    ('apeksifikasyon', 'endodontist'),
    ('rejeneratif-endodonti', 'endodontist'),
    ('endodontik-cerrahi', 'endodontist'),
    -- Restoratif
    ('kompozit', 'restoratif_dis_tedavisi_uzmani'),
    ('indirekt-restorasyon', 'restoratif_dis_tedavisi_uzmani'),
    ('kompozit-veneer', 'restoratif_dis_tedavisi_uzmani'),
    ('beyazlatma', 'restoratif_dis_tedavisi_uzmani'),
    ('diastema', 'restoratif_dis_tedavisi_uzmani'),
    ('gulus-tasarimi', 'restoratif_dis_tedavisi_uzmani'),
    -- Protetik
    ('kron', 'protez_uzmani'),
    ('kopru', 'protez_uzmani'),
    ('lamine-veneer', 'protez_uzmani'),
    ('total-protez', 'protez_uzmani'),
    ('parsiyel-protez', 'protez_uzmani'),
    ('implant-ustu-protez', 'protez_uzmani'),
    ('tam-agiz-rehabilitasyonu', 'protez_uzmani'),
    ('gece-plagi', 'protez_uzmani'),
    -- Ağız, diş ve çene cerrahisi
    ('dis-cekimi', 'agiz_dis_cene_cerrahi'),
    ('gomulu-dis', 'agiz_dis_cene_cerrahi'),
    ('implant', 'agiz_dis_cene_cerrahi'),
    ('sinus-lifting', 'agiz_dis_cene_cerrahi'),
    ('kemik-grefti', 'agiz_dis_cene_cerrahi'),
    ('kist', 'agiz_dis_cene_cerrahi'),
    ('apikal-rezeksiyon', 'agiz_dis_cene_cerrahi'),
    ('ortognatik-cerrahi', 'agiz_dis_cene_cerrahi'),
    ('cene-kirigi', 'agiz_dis_cene_cerrahi'),
    -- Periodontoloji
    ('dis-tasi', 'periodontolog'),
    ('kok-yuzeyi-duzlestirme', 'periodontolog'),
    ('flep-operasyonu', 'periodontolog'),
    ('rejeneratif-periodontal-tedavi', 'periodontolog'),
    ('bag-dokusu-grefti', 'periodontolog'),
    ('serbest-diseti-grefti', 'periodontolog'),
    ('kron-boyu-uzatma', 'periodontolog'),
    ('gingivektomi', 'periodontolog'),
    ('peri-implantitis', 'periodontolog'),
    -- Ortodonti
    ('braket', 'ortodontist'),
    ('seffaf-plak', 'ortodontist'),
    ('fonksiyonel-aparey', 'ortodontist'),
    ('hizli-ust-cene-genisletme', 'ortodontist'),
    ('interseptif-ortodonti', 'ortodontist'),
    ('mini-vida', 'ortodontist'),
    ('pekistirme', 'ortodontist'),
    -- Pedodonti
    ('pulpotomi', 'pedodontist'),
    ('sut-disi-kanal-tedavisi', 'pedodontist'),
    ('fissur-ortucu', 'pedodontist'),
    ('flor-uygulamasi', 'pedodontist'),
    ('yer-tutucu', 'pedodontist'),
    ('paslanmaz-celik-kuron', 'pedodontist'),
    ('dis-travmasi', 'pedodontist'),
    ('genel-anestezi', 'pedodontist'),
    -- Ağız, diş ve çene radyolojisi
    ('panoramik', 'agiz_dis_cene_radyologu'),
    ('periapikal-rontgen', 'agiz_dis_cene_radyologu'),
    ('bitewing', 'agiz_dis_cene_radyologu'),
    ('cbct', 'agiz_dis_cene_radyologu'),
    ('sefalometrik-rontgen', 'agiz_dis_cene_radyologu'),
    -- Oral diagnoz
    ('biyopsi', 'oral_diagnoz_uzmani'),
    ('oral-lezyon', 'oral_diagnoz_uzmani'),
    ('tme-bozuklugu', 'oral_diagnoz_uzmani'),
    ('orofasiyal-agri', 'oral_diagnoz_uzmani'),
    ('ayirici-tani', 'oral_diagnoz_uzmani'),
    ('botoks', 'oral_diagnoz_uzmani')
  ) AS v(code, branch)
  JOIN public.tags t ON t.match_key = replace(v.code, '-', '')
ON CONFLICT (code) DO NOTHING;

-- JOIN etiketi bulamazsa satır sessizce düşerdi.
DO $$
BEGIN
  IF (SELECT count(*) FROM public.treatment_types) <> 64 THEN
    RAISE EXCEPTION 'treatment_types: expected 64 rows, missing tag?';
  END IF;
END;
$$;

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS treatment text REFERENCES public.treatment_types(code);
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_treatment_case_only;
ALTER TABLE public.posts ADD CONSTRAINT posts_treatment_case_only
  CHECK (treatment IS NULL OR type = 'case');

-- ─── create_post / update_post: p_treatment ──────────────────────────────────
-- Yeni parametre imzayı değiştirir; eski sürüm kalırsa PostgREST iki aday görür.
DROP FUNCTION IF EXISTS public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb);
DROP FUNCTION IF EXISTS public.update_post(uuid, text, text, public.dental_branch, jsonb);

CREATE OR REPLACE FUNCTION public.create_post(
  p_type        public.post_type,
  p_title       text,
  p_content     text,
  p_branch      public.dental_branch DEFAULT NULL,
  p_image_paths text[] DEFAULT '{}',
  p_tags        jsonb  DEFAULT '[]',  -- [{"name": "İmplant", "slug": "implant"}, …]
  p_treatment   text   DEFAULT NULL   -- treatment_types.code; vakada zorunlu
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_title     text := btrim(p_title);
  v_content   text := btrim(p_content);
  v_paths     text[] := coalesce(p_image_paths, '{}');
  v_branch    public.dental_branch;
  v_treatment text;
  v_fixed_tag uuid;
  v_tag_ids   uuid[];
  v_post_id   uuid;
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
  -- Branş ve tedavi türü yalnızca vakada tutulur; tür branşa ait olmalı.
  IF p_type = 'case' THEN
    v_branch := p_branch;
    SELECT tag_id INTO v_fixed_tag FROM public.treatment_types
     WHERE code = p_treatment AND branch = p_branch;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'invalid treatment' USING ERRCODE = '22023';
    END IF;
    v_treatment := p_treatment;
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

  INSERT INTO public.posts (user_id, type, title, content, branch, treatment)
  VALUES (v_uid, p_type, v_title, v_content, v_branch, v_treatment)
  RETURNING id INTO v_post_id;

  INSERT INTO public.post_images (post_id, image_url, sort_order)
  SELECT v_post_id, path, ord - 1
    FROM unnest(v_paths) WITH ORDINALITY AS t(path, ord);

  -- Tedavi türünün etiketi her zaman var (5 etiket sınırına dahil).
  v_tag_ids := public.resolve_tags(p_tags);
  IF v_fixed_tag IS NOT NULL THEN
    v_tag_ids := v_fixed_tag || array_remove(v_tag_ids, v_fixed_tag);
  END IF;
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT v_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;

  RETURN v_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_post(
  p_post_id   uuid,
  p_title     text,
  p_content   text,
  p_branch    public.dental_branch DEFAULT NULL,
  p_tags      jsonb DEFAULT '[]',  -- create_post ile aynı biçim
  p_treatment text  DEFAULT NULL   -- vakada zorunlu
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid       uuid := auth.uid();
  v_title     text := btrim(p_title);
  v_content   text := btrim(p_content);
  v_type      public.post_type;
  v_branch    public.dental_branch;
  v_treatment text;
  v_fixed_tag uuid;
  v_tag_ids   uuid[];
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
  -- Branş ve tedavi türü yalnızca vakada tutulur. (CASE…END yok: bkz. SUPABASE.md)
  IF v_type = 'case' THEN
    v_branch := p_branch;
    SELECT tag_id INTO v_fixed_tag FROM public.treatment_types
     WHERE code = p_treatment AND branch = p_branch;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'invalid treatment' USING ERRCODE = '22023';
    END IF;
    v_treatment := p_treatment;
  END IF;

  UPDATE public.posts
     SET title = v_title, content = v_content, branch = v_branch, treatment = v_treatment
   WHERE id = p_post_id;

  -- Etiketler: yeni sette olmayan bağlar silinir, yeniler eklenir.
  v_tag_ids := public.resolve_tags(p_tags);
  IF v_fixed_tag IS NOT NULL THEN
    v_tag_ids := v_fixed_tag || array_remove(v_tag_ids, v_fixed_tag);
  END IF;
  DELETE FROM public.post_tags
   WHERE post_id = p_post_id AND tag_id <> ALL (v_tag_ids);
  INSERT INTO public.post_tags (post_id, tag_id)
  SELECT p_post_id, tag_id FROM unnest(v_tag_ids) AS tag_id
  ON CONFLICT DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_post(public.post_type, text, text, public.dental_branch, text[], jsonb, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.update_post(uuid, text, text, public.dental_branch, jsonb, text) TO authenticated;
