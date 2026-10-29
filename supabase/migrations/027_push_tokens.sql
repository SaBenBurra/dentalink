-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 027: Push bildirim (REL-6)
-- ═══════════════════════════════════════════════════════════════════════════════
-- push_tokens: cihaz FCM token'ı → kullanıcı. İstemci tabloya doğrudan erişemez;
-- register/unregister RPC'leri kullanılır (aynı cihazda hesap değişince token
-- yeni kullanıcıya geçmeli, RLS ile başkasının satırı güncellenemez).
--
-- notifications ve messages INSERT'lerinde pg_net ile `push` Edge Function'ı
-- çağrılır. URL ve paylaşılan sır Vault'tan okunur (docs/SUPABASE.md §7);
-- sırlar tanımlı değilse trigger hiçbir şey yapmaz.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE TABLE IF NOT EXISTS public.push_tokens (
  token       text PRIMARY KEY CHECK (char_length(token) BETWEEN 1 AND 4096),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform    text NOT NULL CHECK (platform IN ('android', 'ios')),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user ON public.push_tokens (user_id);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.push_tokens FROM public, anon, authenticated;


CREATE OR REPLACE FUNCTION public.register_push_token(p_token text, p_platform text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.push_tokens (token, user_id, platform)
  VALUES (p_token, v_uid, p_platform)
  ON CONFLICT (token) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.unregister_push_token(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  DELETE FROM public.push_tokens WHERE token = p_token AND user_id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.register_push_token(text, text) FROM public, anon;
REVOKE EXECUTE ON FUNCTION public.unregister_push_token(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.register_push_token(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unregister_push_token(text) TO authenticated;


-- Edge Function'a yalnızca tür ve satır id'si gider; içeriği fonksiyon kendisi okur.
CREATE OR REPLACE FUNCTION public.trigger_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_url    text;
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_url
    FROM vault.decrypted_secrets WHERE name = 'push_function_url';
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'push_webhook_secret';
  IF v_url IS NULL OR v_secret IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object('kind', TG_ARGV[0], 'id', NEW.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', v_secret
    )
  );
  RETURN NULL;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.trigger_push() FROM public, anon, authenticated;

DROP TRIGGER IF EXISTS on_notification_push ON public.notifications;
CREATE TRIGGER on_notification_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.trigger_push('notification');

DROP TRIGGER IF EXISTS on_message_push ON public.messages;
CREATE TRIGGER on_message_push
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trigger_push('message');
