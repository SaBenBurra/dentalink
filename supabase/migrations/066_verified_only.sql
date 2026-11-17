-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 066: Uygulama yalnızca doğrulanmış hesaplara açık
-- ═══════════════════════════════════════════════════════════════════════════════
-- Üye = is_verified ya da personel (panel hesapları onboarding'siz, doğrulamasız).
-- Üye olmayan oturumlu kullanıcı yalnızca şunlara erişir:
--   kendi users satırı (okuma, kayıtta ekleme), doğrulama isteği, destek sohbeti,
--   app_config (sürüm), push token kaydı, hesap silme.
-- Katmanlar:
--   PostgREST  check_session (058, db_pre_request) her istekte yolu izin listesine
--              bakar; dışındaki istek 403 not_verified. (Oturum kontrolü önce gelir.)
--   RLS        users: üye olmayan yalnızca kendini görür (embed ile başkasının
--              profili gelmesin; destek cevabı personel adı olmadan "Dentigo Destek").
--   Realtime   messages, conversations, notifications SELECT policy'leri üyelik ister
--              (Realtime pre-request'ten geçmez). Destek tabloları açık kalır.
--   Storage    post-images ve post-videos okuma/yükleme üyelik ister. avatars public
--              bucket (okuma kısıtlanamaz); kendi avatarını yükleme kayıtta gerekir.
--   Push       push fonksiyonu alıcı üye değilse yalnızca 'verification' gönderir
--              (is_app_member(uuid), service_role). Duyuru topic'ine aboneliği
--              uygulama yalnızca üyeyken yapar (bilinen sınır: sunucu topic'i
--              kısıtlayamaz).
-- Mevcut kaydı tamamlanmış hesaplar doğrulanmış sayılır (karar 2026-11-17).
-- Eski uygulama sürümü: doğrulanmamış yeni hesap her istekte 403 alır, doğrulama
-- ekranı yoktur. Yeni sürüm yayılınca min_supported_version artırılır (SUPABASE.md).
-- Geri alma: 058'deki gibi pre-request kapatılır ya da check_session 058'e döner.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Üyelik ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_app_member(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id AND is_verified)
      OR EXISTS (SELECT 1 FROM public.staff WHERE user_id = p_user_id);
$$;

-- Yalnızca push fonksiyonu başkası için sorar.
REVOKE EXECUTE ON FUNCTION public.is_app_member(uuid) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_app_member(uuid) TO service_role;

CREATE OR REPLACE FUNCTION public.is_app_member()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.is_app_member(auth.uid());
$$;

-- Policy'ler çağıran rolle çalışır.
REVOKE EXECUTE ON FUNCTION public.is_app_member() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.is_app_member() TO authenticated;

-- ─── Mevcut hesaplar doğrulanmış sayılır ────────────────────────────────────
UPDATE public.users SET is_verified = true
 WHERE onboarding_completed AND NOT is_verified;

-- ─── check_session (058) + üyelik ───────────────────────────────────────────
-- İzin listesi 'METOT /yol' (PostgREST request.method / request.path).
CREATE OR REPLACE FUNCTION public.check_session()
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_claims jsonb := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
  v_sid    text  := v_claims ->> 'session_id';
  v_code   text  := 'session_revoked';
  v_req    text;
BEGIN
  IF v_sid IS NULL THEN
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM auth.sessions WHERE id = v_sid::uuid) THEN
    IF public.is_app_member((v_claims ->> 'sub')::uuid) THEN
      RETURN;
    END IF;
    v_req := current_setting('request.method', true) || ' ' || current_setting('request.path', true);
    IF v_req = ANY (ARRAY[
         'GET /users', 'HEAD /users', 'POST /users',
         'GET /verification_requests', 'POST /rpc/submit_verification',
         'GET /app_config',
         'POST /rpc/register_push_token', 'POST /rpc/unregister_push_token',
         'POST /rpc/delete_account',
         'GET /support_threads', 'GET /support_messages',
         'POST /rpc/send_support_message', 'POST /rpc/mark_support_read']) THEN
      RETURN;
    END IF;
    RAISE SQLSTATE 'PGRST' USING
      MESSAGE = json_build_object('code', 'not_verified', 'message', 'account not verified')::text,
      DETAIL  = json_build_object('status', 403, 'headers', json_build_object())::text;
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users
              WHERE id = (v_claims ->> 'sub')::uuid AND banned_until > now()) THEN
    v_code := 'user_banned';
  END IF;

  -- PGRST: PostgREST gövdeyi MESSAGE'dan, durum ve başlıkları DETAIL'den alır.
  RAISE SQLSTATE 'PGRST' USING
    MESSAGE = json_build_object('code', v_code, 'message', 'session revoked')::text,
    DETAIL  = json_build_object('status', 401,
                                'headers', json_build_object('X-Session-Revoked', v_code))::text;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_session() FROM public;
GRANT EXECUTE ON FUNCTION public.check_session() TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload config';

-- ─── RLS ────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_select_all" ON public.users;
CREATE POLICY "users_select_all" ON public.users
  FOR SELECT TO authenticated
  USING ((select public.is_app_member()) OR id = (select auth.uid()));

DROP POLICY IF EXISTS "conversations_select_own" ON public.conversations;
CREATE POLICY "conversations_select_own" ON public.conversations
  FOR SELECT TO authenticated
  USING (
    ((select auth.uid()) = user1_id OR (select auth.uid()) = user2_id)
    AND (select public.is_app_member())
  );

DROP POLICY IF EXISTS "messages_select_own" ON public.messages;
CREATE POLICY "messages_select_own" ON public.messages
  FOR SELECT TO authenticated
  USING (
    ((select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id)
    AND (select public.is_app_member())
  );

DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id AND (select public.is_app_member()));

-- ─── Storage ────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "post_images_read" ON storage.objects;
CREATE POLICY "post_images_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-images' AND (select public.is_app_member()));

DROP POLICY IF EXISTS "post_images_upload" ON storage.objects;
CREATE POLICY "post_images_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
    AND (select public.is_app_member())
  );

DROP POLICY IF EXISTS "post_videos_read" ON storage.objects;
CREATE POLICY "post_videos_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-videos' AND (select public.is_app_member()));

DROP POLICY IF EXISTS "post_videos_upload" ON storage.objects;
CREATE POLICY "post_videos_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-videos'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
    AND (select public.is_app_member())
  );
