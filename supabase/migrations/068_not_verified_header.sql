-- 068: doğrulaması kaldırılan oturum uygulamaya haber verir.
--
-- 066'da üye olmayan oturumun isteği 403 not_verified alır, ama başlıksızdı:
-- uygulama oturumdaki eski profille (is_verified = true) içeride kalıyor,
-- yalnızca veriler gelmiyordu. Artık yanıt `X-Not-Verified: 1` taşır; istemci
-- (SessionGuardClient) profili yeniden okur ve router doğrulama ekranına alır.
-- Fonksiyonun geri kalanı 066 ile aynı.
--
-- Geri alma: check_session 066'daki tanımına döner.

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
      DETAIL  = json_build_object('status', 403,
                                  'headers', json_build_object('X-Not-Verified', '1'))::text;
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
