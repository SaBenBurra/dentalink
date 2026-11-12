-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 060: Panel etiket yönetimi
-- ═══════════════════════════════════════════════════════════════════════════════
-- Yeni yetki tags.manage (staff_roles CHECK genişler, admin rolüne eklenir).
-- SUPABASE.md §9'daki SQL Editor işleri panele açılır:
--   admin_tag_report(p_limit):       kullanıcı etiketleri + en benzer tanımlı etiket
--   admin_user_treatments(p_limit):  listede olmayan tedaviler, branşa göre vaka sayısı
--   admin_add_tag_alias(p_alias, p_tag, p_reason):  add_tag_alias (032) + log
--   admin_curate_tag(p_name, p_reason):             add_curated_tags (032) + log
-- merge_tags sarmalanmaz: kullanıcı etiketi add_tag_alias ile birleşir; tanımlı
-- etiketi birleştirmek katalog kararıdır, SQL Editor'da kalır. promote_other_treatment
-- uygulama sürümü ister (TreatmentType enum'u), panelden çalıştırılmaz.
-- Log: staff_actions target_type 'tag', target_id hedef etiketin slug'ı (birleşen
-- etiket silinir, slug okunur kalır). Mevcut RPC, kolon ve policy değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.staff_roles DROP CONSTRAINT IF EXISTS staff_roles_permissions_check;
ALTER TABLE public.staff_roles ADD CONSTRAINT staff_roles_permissions_check
  CHECK (permissions <@ ARRAY[
    'support.reply', 'reports.handle', 'posts.remove',
    'comments.remove', 'users.ban', 'users.verify',
    'staff.manage', 'stats.view', 'tags.manage']::text[]);

UPDATE public.staff_roles SET permissions = array_append(permissions, 'tags.manage')
 WHERE name = 'admin' AND NOT 'tags.manage' = ANY (permissions);

-- ─── Benzerlik raporu ───────────────────────────────────────────────────────
-- En çok kullanılan önce. Tanımlı etiket yoksa closest_* NULL.
CREATE OR REPLACE FUNCTION public.admin_tag_report(p_limit integer DEFAULT 100)
RETURNS TABLE (id uuid, name text, slug text, usage_count integer,
               closest_name text, closest_slug text, similarity real)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
#variable_conflict use_column
BEGIN
  IF NOT public.has_permission('tags.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT u.id, u.name, u.slug, u.usage_count, c.name, c.slug,
         extensions.similarity(u.match_key, c.match_key)
    FROM public.tags u
    LEFT JOIN LATERAL (
      SELECT t.name, t.slug, t.match_key FROM public.tags t
       WHERE t.is_curated
       ORDER BY extensions.similarity(u.match_key, t.match_key) DESC
       LIMIT 1) c ON true
   WHERE NOT u.is_curated
   ORDER BY u.usage_count DESC, u.created_at DESC
   LIMIT least(greatest(coalesce(p_limit, 100), 1), 500);
END;
$$;

-- ─── Kullanıcı tedavileri (§9 sorgusu) ──────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_user_treatments(p_limit integer DEFAULT 50)
RETURNS TABLE (branch public.dental_branch, name text, slug text, cases bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
#variable_conflict use_column
BEGIN
  IF NOT public.has_permission('tags.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT pt.branch, t.name, t.slug, count(*)
    FROM public.post_treatments pt
    JOIN public.tags t ON t.id = pt.tag_id
   WHERE NOT EXISTS (SELECT 1 FROM public.treatment_types tt WHERE tt.tag_id = pt.tag_id)
   GROUP BY 1, 2, 3
   ORDER BY 4 DESC, 2
   LIMIT least(greatest(coalesce(p_limit, 50), 1), 500);
END;
$$;

-- ─── Eş anlamlı ─────────────────────────────────────────────────────────────
-- p_alias yazımı p_tag'e yönlenir; o yazımla açılmış kullanıcı etiketi postları
-- (ve tedavi bağıyla) birleşir. Tanımlı etiket eş anlamlı yapılamaz.
CREATE OR REPLACE FUNCTION public.admin_add_tag_alias(
  p_alias  text,
  p_tag    text,
  p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_key  text := public.tag_match_key(coalesce(p_alias, ''));
  v_into public.tags;
  v_from public.tags;
BEGIN
  IF NOT public.has_permission('tags.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF v_key = '' THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_into FROM public.tags WHERE match_key = public.tag_match_key(coalesce(p_tag, ''));
  IF v_into.id IS NULL THEN
    RAISE EXCEPTION 'tag not found' USING ERRCODE = 'P0002';
  END IF;
  SELECT * INTO v_from FROM public.tags WHERE match_key = v_key;
  IF v_from.id = v_into.id THEN
    RAISE EXCEPTION 'alias is target' USING ERRCODE = '22023';
  END IF;
  IF v_from.is_curated THEN
    RAISE EXCEPTION 'alias is curated' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public.add_tag_alias(p_alias, v_into.slug);
  -- Listedeki tedaviye birleşen vakaların branşı listedekine eşitlenir
  -- (resolve_case_treatments listedeki tedavide branşı listeden alır).
  UPDATE public.post_treatments pt SET branch = tt.branch
    FROM public.treatment_types tt
   WHERE tt.tag_id = v_into.id AND pt.tag_id = v_into.id AND pt.branch <> tt.branch;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason, detail)
  VALUES ('tag.alias', 'tag', v_into.slug, left(p_reason, 500),
          jsonb_build_object('alias', v_key, 'merged', v_from.slug, 'merged_usage', v_from.usage_count));
END;
$$;

-- ─── Tanımlı etiket ─────────────────────────────────────────────────────────
-- Aynı yazımlı kullanıcı etiketi varsa tanımlıya çevrilir (postları korunur).
-- Ad uzunluğu tags_name_length (017) ile 23514.
CREATE OR REPLACE FUNCTION public.admin_curate_tag(p_name text, p_reason text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slug text := public.tag_slug(lower(btrim(coalesce(p_name, ''))));
BEGIN
  IF NOT public.has_permission('tags.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF v_slug = '' THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tag_aliases WHERE match_key = replace(v_slug, '-', '')) THEN
    RAISE EXCEPTION 'tag is alias' USING ERRCODE = 'P0001';
  END IF;

  PERFORM public.add_curated_tags(ARRAY[p_name]);

  INSERT INTO public.staff_actions (action, target_type, target_id, reason)
  VALUES ('tag.curate', 'tag', v_slug, left(p_reason, 500));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_tag_report(integer), public.admin_user_treatments(integer),
  public.admin_add_tag_alias(text, text, text), public.admin_curate_tag(text, text)
  FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_tag_report(integer), public.admin_user_treatments(integer),
  public.admin_add_tag_alias(text, text, text), public.admin_curate_tag(text, text)
  TO authenticated;
