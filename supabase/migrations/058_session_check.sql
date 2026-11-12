-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 058: Her istekte oturum kontrolü (ban anında etkili)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Ban (057) oturumları siler ama access token süresi dolana kadar (≤1 saat)
-- geçerli kalıyordu. PostgREST her istekten önce check_session'ı çalıştırır
-- (db_pre_request): token'daki session_id auth.sessions'ta yoksa istek
-- reddedilir. Okuma, yazma ve RPC hepsi kapsanır; Storage ve Realtime kapsanmaz.
--
-- Yanıt: HTTP 401, `X-Session-Revoked: user_banned | session_revoked` başlığı ve
-- aynı kod gövdede. Uygulama başlığı görünce yerel çıkış yapar ve sebebi gösterir.
-- session_id taşımayan token (anon, service_role, smoke testleri) kontrol edilmez.
-- Maliyet: istek başına bir birincil anahtar araması.
--
-- Geri alma (API'yi kilitlerse SQL Editor'dan):
--   ALTER ROLE authenticator RESET pgrst.db_pre_request;
--   NOTIFY pgrst, 'reload config';
-- ═══════════════════════════════════════════════════════════════════════════════

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
BEGIN
  IF v_sid IS NULL THEN
    RETURN;
  END IF;
  IF EXISTS (SELECT 1 FROM auth.sessions WHERE id = v_sid::uuid) THEN
    RETURN;
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

-- Her istek bu rolle çağırır; anon da dahil, yoksa anon istekler düşer.
REVOKE EXECUTE ON FUNCTION public.check_session() FROM public;
GRANT EXECUTE ON FUNCTION public.check_session() TO anon, authenticated, service_role;

ALTER ROLE authenticator SET pgrst.db_pre_request = 'public.check_session';
NOTIFY pgrst, 'reload config';
