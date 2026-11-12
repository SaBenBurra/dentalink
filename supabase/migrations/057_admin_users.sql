-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 057: Panel kullanıcı yönetimi
-- ═══════════════════════════════════════════════════════════════════════════════
-- admin_search_users: ad, kullanıcı adı ya da id ile arama; boşsa en yeniler.
--                     Ban durumu ve açık rapor sayısıyla (users.verify | users.ban | staff.manage).
-- admin_user_detail:  profil + ban, son giriş, rapor sayıları; e-posta/telefon maskeli.
-- admin_user_contact: e-posta/telefonun tamamı (users.ban), user.view_contact olarak loglanır.
-- set_user_verified:  users.verify, loglu.
-- set_user_ban:       users.ban. Edge Function yerine definer RPC (ADMIN_PANEL.md madde 6):
--                     auth.users.banned_until, auth.sessions (refresh token'lar cascade
--                     ile gider), push_tokens ve log aynı transaction'da. Personel
--                     banlanamaz. p_days NULL = kalıcı (100 yıl; GoTrue sonsuz tarih okumaz).
--                     Bilinen sınır: açık access token ≤1 saat geçerli kalır.
-- target_history:     056'daki RPC, kullanıcı sayfası için users.* yetkilerine de açılır.
-- panel-account düzeltmesi: service_role'ün users ve staff_actions'a INSERT yetkisi
--                     yoktu (SUPABASE.md §2); panelden hesap açma 42501 ile düşüyor,
--                     şifre değişikliği loglanmıyordu.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── panel-account için service_role yetkileri ──────────────────────────────
GRANT INSERT (id, full_name, username) ON public.users TO service_role;
GRANT INSERT (actor_id, action, target_type, target_id) ON public.staff_actions TO service_role;

-- ─── Yetki ──────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.can_manage_users()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.has_permission('users.verify')
      OR public.has_permission('users.ban')
      OR public.has_permission('staff.manage');
$$;

REVOKE EXECUTE ON FUNCTION public.can_manage_users() FROM public, anon, authenticated;

-- Kullanıcıya karşı açık raporlar: hesabın kendisi, postları ve yorumları.
CREATE OR REPLACE FUNCTION public.open_reports_against(p_user_id uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT count(*)::integer FROM public.reports r
   WHERE r.status = 'open'
     AND ((r.target_type = 'user' AND r.target_id = p_user_id)
       OR (r.target_type = 'post' AND r.target_id IN (SELECT id FROM public.posts WHERE user_id = p_user_id))
       OR (r.target_type = 'comment' AND r.target_id IN (SELECT id FROM public.comments WHERE user_id = p_user_id)));
$$;

REVOKE EXECUTE ON FUNCTION public.open_reports_against(uuid) FROM public, anon, authenticated;

-- ─── admin_search_users ─────────────────────────────────────────────────────
-- p_filter: NULL (hepsi), 'banned', 'reported'.
CREATE OR REPLACE FUNCTION public.admin_search_users(
  p_query  text    DEFAULT NULL,
  p_filter text    DEFAULT NULL,
  p_limit  integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id           uuid,
  full_name    text,
  username     text,
  title        text,
  avatar_url   text,
  is_verified  boolean,
  created_at   timestamptz,
  banned_until timestamptz,
  open_reports integer,
  staff_role   text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_q text := nullif(btrim(p_query), '');
BEGIN
  IF NOT public.can_manage_users() THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_filter IS NOT NULL AND p_filter NOT IN ('banned', 'reported') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT u.id, u.full_name, u.username, u.title::text, u.avatar_url, u.is_verified, u.created_at,
         a.banned_until, public.open_reports_against(u.id), s.role
    FROM public.users u
    LEFT JOIN auth.users a ON a.id = u.id
    LEFT JOIN public.staff s ON s.user_id = u.id
   WHERE (v_q IS NULL
          OR u.id::text = v_q
          OR u.full_name ILIKE '%' || v_q || '%'
          OR u.username ILIKE '%' || ltrim(v_q, '@') || '%')
     AND (p_filter IS DISTINCT FROM 'banned' OR a.banned_until > now())
     AND (p_filter IS DISTINCT FROM 'reported' OR public.open_reports_against(u.id) > 0)
   ORDER BY u.created_at DESC
   LIMIT least(greatest(coalesce(p_limit, 50), 1), 100)
  OFFSET greatest(coalesce(p_offset, 0), 0);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_search_users(text, text, integer, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_search_users(text, text, integer, integer) TO authenticated;

-- ─── admin_user_detail ──────────────────────────────────────────────────────
-- Maske: e-postanın ilk harfi ve alan adı, telefonun son iki hanesi.
CREATE OR REPLACE FUNCTION public.admin_user_detail(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v jsonb;
BEGIN
  IF NOT public.can_manage_users() THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
           'id', u.id, 'full_name', u.full_name, 'username', u.username, 'title', u.title,
           'avatar_url', u.avatar_url, 'bio', u.bio, 'university', u.university, 'city', u.city,
           'workplace', u.workplace, 'experience_years', u.experience_years,
           'is_verified', u.is_verified, 'onboarding_completed', u.onboarding_completed,
           'posts_count', u.posts_count, 'followers_count', u.followers_count,
           'created_at', u.created_at, 'last_seen_at', u.last_seen_at,
           'last_sign_in_at', a.last_sign_in_at, 'banned_until', a.banned_until,
           'email', nullif(left(a.email, 1) || '***' || substring(a.email FROM '@.*$'), '***'),
           'phone', nullif('***' || right(a.phone, 2), '***'),
           'staff_role', s.role,
           'open_reports', public.open_reports_against(u.id),
           'total_reports', (SELECT count(*) FROM public.reports r
                              WHERE r.target_type = 'user' AND r.target_id = u.id),
           'support_thread_id', (SELECT t.id FROM public.support_threads t WHERE t.user_id = u.id))
    INTO v
    FROM public.users u
    LEFT JOIN auth.users a ON a.id = u.id
    LEFT JOIN public.staff s ON s.user_id = u.id
   WHERE u.id = p_user_id;

  IF v IS NULL THEN
    RAISE EXCEPTION 'user not found' USING ERRCODE = 'P0002';
  END IF;
  RETURN v;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_user_detail(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_user_detail(uuid) TO authenticated;

-- ─── admin_user_contact ─────────────────────────────────────────────────────
-- VOLATILE: log yazar.
CREATE OR REPLACE FUNCTION public.admin_user_contact(p_user_id uuid)
RETURNS TABLE (email text, phone text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_permission('users.ban') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY SELECT a.email::text, a.phone::text FROM auth.users a WHERE a.id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id)
  VALUES ('user.view_contact', 'user', p_user_id::text);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_user_contact(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_user_contact(uuid) TO authenticated;

-- ─── set_user_verified ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_user_verified(
  p_user_id  uuid,
  p_verified boolean,
  p_reason   text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_action text := 'user.unverify';
BEGIN
  IF NOT public.has_permission('users.verify') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_verified IS NULL THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF p_verified THEN
    v_action := 'user.verify';
  END IF;

  UPDATE public.users SET is_verified = p_verified WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason)
  VALUES (v_action, 'user', p_user_id::text, left(p_reason, 500));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_user_verified(uuid, boolean, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_user_verified(uuid, boolean, text) TO authenticated;

-- ─── set_user_ban ───────────────────────────────────────────────────────────
-- p_ban = false: banı kaldırır (p_days yok sayılır). p_days NULL: kalıcı.
CREATE OR REPLACE FUNCTION public.set_user_ban(
  p_user_id uuid,
  p_ban     boolean,
  p_days    integer DEFAULT NULL,
  p_reason  text    DEFAULT NULL
)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_until timestamptz;
  v_n     integer;
BEGIN
  IF NOT public.has_permission('users.ban') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_ban IS NULL OR (p_ban AND p_days IS NOT NULL AND (p_days < 1 OR p_days > 3650)) THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF p_ban AND EXISTS (SELECT 1 FROM public.staff WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'target is staff' USING ERRCODE = 'P0001';
  END IF;

  IF p_ban THEN
    v_until := now() + make_interval(days => coalesce(p_days, 36500));
  END IF;

  UPDATE auth.users SET banned_until = v_until WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found' USING ERRCODE = 'P0002';
  END IF;

  IF p_ban THEN
    -- Oturumlar kapanır (refresh token'lar cascade ile), push gitmez.
    DELETE FROM auth.sessions WHERE user_id = p_user_id;
    GET DIAGNOSTICS v_n = ROW_COUNT;
    DELETE FROM public.push_tokens WHERE user_id = p_user_id;
    INSERT INTO public.staff_actions (action, target_type, target_id, reason, detail)
    VALUES ('user.ban', 'user', p_user_id::text, left(p_reason, 500),
            jsonb_build_object('days', p_days, 'until', v_until, 'sessions', v_n));
  ELSE
    INSERT INTO public.staff_actions (action, target_type, target_id, reason)
    VALUES ('user.unban', 'user', p_user_id::text, left(p_reason, 500));
  END IF;

  RETURN v_until;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_user_ban(uuid, boolean, integer, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_user_ban(uuid, boolean, integer, text) TO authenticated;

-- ─── target_history: kullanıcı sayfası için ─────────────────────────────────
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
  IF NOT (public.has_permission('reports.handle') OR public.can_manage_users()) THEN
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
