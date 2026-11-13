-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 063: Panel içerik sayfası (ADMIN_PANEL.md madde 10)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Rapor beklemeden içerik bulma ve gizleme. Yazma için yeni RPC yok: gizleme
-- moderate_content (053), geçmiş target_history (056).
-- admin_search_posts:  başlık + içerik araması (uygulamanın search_tsquery'si) ya da
--                      gönderi id'si; tür, yalnızca gizliler, yazar, ilan kategorisi ve
--                      şehir filtresi; en yeni önce. Gizliler dahil, engellemeler
--                      uygulanmaz (definer). Medya yolları döner, signed URL panelde.
-- admin_post_comments: gönderinin yorumları, gizliler dahil.
-- İkisi de posts.remove | comments.remove ister (can_moderate_content).
-- target_history:      bu iki yetkiye de açılır (önceki: reports.handle | can_manage_users).
-- Mevcut RPC, kolon ve policy değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.can_moderate_content()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.has_permission('posts.remove') OR public.has_permission('comments.remove');
$$;

REVOKE EXECUTE ON FUNCTION public.can_moderate_content() FROM public, anon, authenticated;

-- ─── admin_search_posts ─────────────────────────────────────────────────────
-- p_type: NULL (hepsi), 'case', 'question', 'listing'. p_hidden true: yalnızca gizliler.
CREATE OR REPLACE FUNCTION public.admin_search_posts(
  p_query    text    DEFAULT NULL,
  p_type     text    DEFAULT NULL,
  p_hidden   boolean DEFAULT false,
  p_user_id  uuid    DEFAULT NULL,
  p_category text    DEFAULT NULL,
  p_city     text    DEFAULT NULL,
  p_limit    integer DEFAULT 50,
  p_offset   integer DEFAULT 0
)
RETURNS TABLE (
  id               uuid,
  type             text,
  title            text,
  content          text,
  created_at       timestamptz,
  removed_at       timestamptz,
  author_id        uuid,
  author_name      text,
  author_username  text,
  comment_count    integer,
  open_reports     integer,
  listing_category text,
  item_condition   text,
  price            integer,
  city             text,
  is_sold          boolean,
  media            jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_q    text := nullif(btrim(p_query), '');
  v_city text := nullif(btrim(p_city), '');
  v_id   uuid;
  v_tsq  tsquery;
BEGIN
  IF NOT public.can_moderate_content() THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NOT NULL AND p_type NOT IN ('case', 'question', 'listing') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;

  -- Uygulamadan kopyalanan gönderi id'si doğrudan bulunur.
  IF v_q ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    v_id := v_q::uuid;
  ELSIF v_q IS NOT NULL THEN
    v_tsq := public.search_tsquery(v_q);
  END IF;

  RETURN QUERY
  SELECT p.id, p.type::text, p.title, p.content, p.created_at, p.removed_at,
         a.id, a.full_name, a.username, p.comment_count,
         (SELECT count(*)::integer FROM public.reports r
           WHERE r.target_type = 'post' AND r.target_id = p.id AND r.status = 'open'),
         p.listing_category, p.item_condition, p.price, p.city, p.is_sold,
         coalesce((
           SELECT jsonb_agg(jsonb_build_object('image_url', i.image_url, 'video_path', i.video_path)
                            ORDER BY i.sort_order)
             FROM public.post_images i WHERE i.post_id = p.id), '[]'::jsonb)
    FROM public.posts p
    JOIN public.users a ON a.id = p.user_id
   WHERE (v_id IS NULL OR p.id = v_id)
     AND (v_tsq IS NULL OR p.search_vector @@ v_tsq)
     AND (p_type IS NULL OR p.type::text = p_type)
     AND (NOT coalesce(p_hidden, false) OR p.removed_at IS NOT NULL)
     AND (p_user_id IS NULL OR p.user_id = p_user_id)
     AND (p_category IS NULL OR p.listing_category = p_category)
     AND (v_city IS NULL OR p.city ILIKE '%' || v_city || '%')
   ORDER BY p.created_at DESC, p.id
   LIMIT least(greatest(coalesce(p_limit, 50), 1), 100)
  OFFSET greatest(coalesce(p_offset, 0), 0);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_search_posts(text, text, boolean, uuid, text, text, integer, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_search_posts(text, text, boolean, uuid, text, text, integer, integer) TO authenticated;

-- ─── admin_post_comments ────────────────────────────────────────────────────
-- Eskiden yeniye; cevaplar parent_id ile üst yoruma bağlanır.
CREATE OR REPLACE FUNCTION public.admin_post_comments(p_post_id uuid)
RETURNS TABLE (
  id              uuid,
  parent_id       uuid,
  content         text,
  created_at      timestamptz,
  removed_at      timestamptz,
  author_id       uuid,
  author_name     text,
  author_username text,
  open_reports    integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.can_moderate_content() THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  -- shortcut: ilk 500 yorum, sayfalama yok; bu kadar yorumlu gönderi çıkarsa keyset ekle.
  RETURN QUERY
  SELECT c.id, c.parent_id, c.content, c.created_at, c.removed_at,
         a.id, a.full_name, a.username,
         (SELECT count(*)::integer FROM public.reports r
           WHERE r.target_type = 'comment' AND r.target_id = c.id AND r.status = 'open')
    FROM public.comments c
    JOIN public.users a ON a.id = c.user_id
   WHERE c.post_id = p_post_id
   ORDER BY c.created_at, c.id
   LIMIT 500;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_post_comments(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_post_comments(uuid) TO authenticated;

-- ─── target_history ─────────────────────────────────────────────────────────
-- 057'deki gövde; yalnızca yetki kontrolü genişledi.
CREATE OR REPLACE FUNCTION public.target_history(
  p_target_type text,
  p_target_id   uuid
)
RETURNS TABLE (
  action     text,
  reason     text,
  detail     jsonb,
  created_at timestamptz,
  actor_name text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT (public.has_permission('reports.handle') OR public.can_manage_users()
          OR public.can_moderate_content()) THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT s.action, s.reason, s.detail, s.created_at, u.full_name
    FROM public.staff_actions s
    LEFT JOIN public.users u ON u.id = s.actor_id
   WHERE s.target_type = p_target_type AND s.target_id = p_target_id::text
   ORDER BY s.created_at DESC
   LIMIT 50;
END;
$$;
