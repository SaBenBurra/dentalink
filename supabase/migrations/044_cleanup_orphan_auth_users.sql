-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 044: Profilsiz auth kullanıcılarını temizleme
-- ═══════════════════════════════════════════════════════════════════════════════
-- Kod istemek, doğrulanmasa bile auth.users satırı açar ve mükerrer kontrolü bu
-- satırı da sayar. Yanlış yazılan numara, gerçek sahibinin onu Ayarlar'dan
-- eklemesini engellerdi. Kayıt bitmeden kalan hesaplar saat başı silinir:
--   doğrulanmamış: son koddan 1 saat sonra (kod 10 dakika geçerli)
--   doğrulanmış: son girişten 24 saat sonra (kayıt yarım kalmış)
-- public.users satırı olan hesaba dokunulmaz.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION public.cleanup_orphan_auth_users()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_deleted integer;
BEGIN
  DELETE FROM auth.users u
  WHERE NOT EXISTS (SELECT 1 FROM public.users p WHERE p.id = u.id)
    AND (
      (u.phone_confirmed_at IS NULL
        AND u.email_confirmed_at IS NULL
        AND COALESCE(u.confirmation_sent_at, u.created_at) < now() - interval '1 hour')
      OR
      ((u.phone_confirmed_at IS NOT NULL OR u.email_confirmed_at IS NOT NULL)
        AND COALESCE(u.last_sign_in_at, u.created_at) < now() - interval '24 hours')
    );
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.cleanup_orphan_auth_users() FROM public, anon, authenticated, service_role;

SELECT cron.schedule(
  'cleanup-orphan-auth-users',
  '0 * * * *',
  'SELECT public.cleanup_orphan_auth_users()'
);
