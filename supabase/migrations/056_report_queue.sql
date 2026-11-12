-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 056: Panel moderasyon kuyruğu
-- ═══════════════════════════════════════════════════════════════════════════════
-- report_queue:   raporlar hedef başına gruplu (reports.handle). Her satır hedefin
--                 önizlemesini taşır (target jsonb; hedef silinmişse NULL). Definer:
--                 gizlenmiş içerik posts.remove / comments.remove olmadan da görünür,
--                 moderatör neye karar verdiğini görmeli. Medya yolları döner, panel
--                 signed URL'i kendisi alır (storage okuma her oturuma açık, 020/046).
-- target_history: hedefin staff_actions geçmişi (reports.handle). staff_actions
--                 tablosu yalnızca staff.manage'a açık kalır; bu yalnızca bir hedefi verir.
-- Mevcut RPC, kolon ve policy değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS reports_target_idx
  ON public.reports (target_type, target_id, status);

-- ─── report_queue ───────────────────────────────────────────────────────────
-- open: çok raporlanan önce, eşitse en eski; kapalılar: son rapor önce.
CREATE OR REPLACE FUNCTION public.report_queue(
  p_status text    DEFAULT 'open',
  p_limit  integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  target_type  text,
  target_id    uuid,
  report_count integer,
  reasons      text[],
  first_at     timestamptz,
  last_at      timestamptz,
  target       jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_open integer := (p_status = 'open')::integer;
BEGIN
  IF NOT public.has_permission('reports.handle') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL OR p_status NOT IN ('open', 'actioned', 'dismissed') THEN
    RAISE EXCEPTION 'invalid status' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  WITH g AS (
    SELECT r.target_type, r.target_id, count(*)::integer AS n,
           array_agg(DISTINCT r.reason) AS reasons,
           min(r.created_at) AS first_at, max(r.created_at) AS last_at
      FROM public.reports r
     WHERE r.status = p_status
     GROUP BY r.target_type, r.target_id
     -- CASE yerine çarpan (SUPABASE.md §1): kapalılarda ilk iki anahtar 0 olur.
     ORDER BY (v_open * count(*)) DESC,
              (v_open * extract(epoch FROM min(r.created_at))) ASC,
              max(r.created_at) DESC
     LIMIT least(greatest(coalesce(p_limit, 50), 1), 100)
    OFFSET greatest(coalesce(p_offset, 0), 0)
  )
  SELECT g.target_type, g.target_id, g.n, g.reasons, g.first_at, g.last_at,
         coalesce(
           (SELECT jsonb_build_object(
                     'title', p.title, 'content', p.content, 'type', p.type,
                     'created_at', p.created_at, 'removed_at', p.removed_at,
                     'author', jsonb_build_object('id', a.id, 'full_name', a.full_name, 'username', a.username),
                     'media', coalesce((
                       SELECT jsonb_agg(jsonb_build_object('image_url', i.image_url, 'video_path', i.video_path)
                                        ORDER BY i.sort_order)
                         FROM public.post_images i WHERE i.post_id = p.id), '[]'::jsonb))
              FROM public.posts p JOIN public.users a ON a.id = p.user_id
             WHERE g.target_type = 'post' AND p.id = g.target_id),
           (SELECT jsonb_build_object(
                     'content', c.content, 'created_at', c.created_at, 'removed_at', c.removed_at,
                     'post_id', c.post_id, 'post_title', p.title,
                     'author', jsonb_build_object('id', a.id, 'full_name', a.full_name, 'username', a.username))
              FROM public.comments c
              JOIN public.users a ON a.id = c.user_id
              JOIN public.posts p ON p.id = c.post_id
             WHERE g.target_type = 'comment' AND c.id = g.target_id),
           (SELECT jsonb_build_object(
                     'full_name', u.full_name, 'username', u.username, 'title', u.title,
                     'avatar_url', u.avatar_url, 'bio', u.bio, 'is_verified', u.is_verified,
                     'created_at', u.created_at)
              FROM public.users u
             WHERE g.target_type = 'user' AND u.id = g.target_id)
         )
    FROM g
   ORDER BY (v_open * g.n) DESC,
            (v_open * extract(epoch FROM g.first_at)) ASC,
            g.last_at DESC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.report_queue(text, integer, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.report_queue(text, integer, integer) TO authenticated;

-- ─── target_history ─────────────────────────────────────────────────────────
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
  IF NOT public.has_permission('reports.handle') THEN
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

REVOKE EXECUTE ON FUNCTION public.target_history(text, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.target_history(text, uuid) TO authenticated;
