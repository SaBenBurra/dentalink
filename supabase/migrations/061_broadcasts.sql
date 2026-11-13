-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 061: Panelden toplu duyuru (push)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Yeni yetki broadcast.send (staff_roles CHECK genişler, admin rolüne eklenir).
-- Kararlar (2026-11-12): yalnızca bilgilendirme (ticari ileti İYS ister, kapsam dışı);
-- kullanıcı Ayarlar'dan kapatabilir (cihazda, FCM topic aboneliği); yalnızca push,
-- uygulama içi bildirim listesine düşmez.
-- send_broadcast(p_title, p_body, p_post_id, p_test_user_id): satırı yazar ve loglar.
--   p_test_user_id NULL = herkes (FCM topic 'announcements'), değilse yalnızca o
--   kullanıcının cihazları (push_tokens). Gönderimi INSERT trigger'ı (trigger_push,
--   027) Edge Function push'a ('broadcast') bırakır; push sent_at ya da error yazar.
-- Bilinen sınırlar: topic'e abone olmayan eski uygulama sürümleri duyuruyu almaz;
-- topic gönderiminde teslim sayısı FCM'den gelmez; uygulama açıkken gelen duyuru
-- gösterilmez (diğer bildirimler gibi).
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.staff_roles DROP CONSTRAINT IF EXISTS staff_roles_permissions_check;
ALTER TABLE public.staff_roles ADD CONSTRAINT staff_roles_permissions_check
  CHECK (permissions <@ ARRAY[
    'support.reply', 'reports.handle', 'posts.remove',
    'comments.remove', 'users.ban', 'users.verify',
    'staff.manage', 'stats.view', 'tags.manage', 'broadcast.send']::text[]);

UPDATE public.staff_roles SET permissions = array_append(permissions, 'broadcast.send')
 WHERE name = 'admin' AND NOT 'broadcast.send' = ANY (permissions);

-- ─── broadcasts ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.broadcasts (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title         text        NOT NULL CHECK (char_length(title) BETWEEN 1 AND 65),
  body          text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 240),
  post_id       uuid        REFERENCES public.posts(id) ON DELETE SET NULL,
  test_user_id  uuid        REFERENCES public.users(id) ON DELETE SET NULL,
  is_test       boolean     NOT NULL DEFAULT false,
  created_by    uuid        DEFAULT auth.uid() REFERENCES public.users(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  sent_at       timestamptz,
  error         text
);
CREATE INDEX IF NOT EXISTS broadcasts_created_idx ON public.broadcasts (created_at DESC);

ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "broadcasts_select" ON public.broadcasts;
CREATE POLICY "broadcasts_select" ON public.broadcasts
  FOR SELECT TO authenticated
  USING ((select public.has_permission('broadcast.send')));
REVOKE ALL ON public.broadcasts FROM public, anon, authenticated;
GRANT SELECT ON public.broadcasts TO authenticated;
-- Edge Function push: satırı okur, sonucu yazar (SUPABASE.md §2).
GRANT SELECT (id, title, body, post_id, test_user_id, is_test) ON public.broadcasts TO service_role;
GRANT UPDATE (sent_at, error) ON public.broadcasts TO service_role;

DROP TRIGGER IF EXISTS on_broadcast_push ON public.broadcasts;
CREATE TRIGGER on_broadcast_push
  AFTER INSERT ON public.broadcasts
  FOR EACH ROW EXECUTE FUNCTION public.trigger_push('broadcast');

-- ─── send_broadcast ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.send_broadcast(
  p_title        text,
  p_body         text,
  p_post_id      uuid DEFAULT NULL,
  p_test_user_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_title text := btrim(coalesce(p_title, ''));
  v_body  text := btrim(coalesce(p_body, ''));
  v_id    uuid;
  v_action text := 'broadcast.send';
BEGIN
  IF NOT public.has_permission('broadcast.send') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF char_length(v_title) NOT BETWEEN 1 AND 65 OR char_length(v_body) NOT BETWEEN 1 AND 240 THEN
    RAISE EXCEPTION 'invalid broadcast' USING ERRCODE = '22023';
  END IF;
  IF p_post_id IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.posts WHERE id = p_post_id AND removed_at IS NULL) THEN
    RAISE EXCEPTION 'post not found' USING ERRCODE = 'P0002';
  END IF;
  IF p_test_user_id IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.users WHERE id = p_test_user_id) THEN
    RAISE EXCEPTION 'user not found' USING ERRCODE = 'P0002';
  END IF;

  IF p_test_user_id IS NOT NULL THEN
    v_action := 'broadcast.test';
  END IF;

  INSERT INTO public.broadcasts (title, body, post_id, test_user_id, is_test)
  VALUES (v_title, v_body, p_post_id, p_test_user_id, p_test_user_id IS NOT NULL)
  RETURNING id INTO v_id;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES (v_action, 'broadcast', v_id::text,
          jsonb_build_object('title', v_title, 'test_user_id', p_test_user_id));
  RETURN v_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.send_broadcast(text, text, uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.send_broadcast(text, text, uuid, uuid) TO authenticated;
