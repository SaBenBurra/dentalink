-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 062: Sürüm kontrolü (app_config)
-- ═══════════════════════════════════════════════════════════════════════════════
-- ROADMAP Faz 5 "Sürüm kontrolü ve zorunlu güncelleme", ADMIN_PANEL.md madde 9.
-- Platform başına bir satır: min_supported_version altındaki uygulama kilitlenir
-- (/update-required), latest_version altındaki uygulamaya banner çıkar.
-- Herkes okur (oturum açmadan da). Yazma yalnızca set_app_config (config.manage,
-- loglu; eski ve yeni değer staff_actions.detail'da). Yeni yetki config.manage
-- (staff_roles CHECK genişler, admin rolüne eklenir). Mevcut RPC, kolon ve policy
-- değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.staff_roles DROP CONSTRAINT IF EXISTS staff_roles_permissions_check;
ALTER TABLE public.staff_roles ADD CONSTRAINT staff_roles_permissions_check
  CHECK (permissions <@ ARRAY[
    'support.reply', 'reports.handle', 'posts.remove',
    'comments.remove', 'users.ban', 'users.verify',
    'staff.manage', 'stats.view', 'tags.manage', 'broadcast.send',
    'config.manage']::text[]);

UPDATE public.staff_roles SET permissions = array_append(permissions, 'config.manage')
 WHERE name = 'admin' AND NOT 'config.manage' = ANY (permissions);

-- ─── app_config ─────────────────────────────────────────────────────────────
-- Sürüm x.y.z (parça başına en fazla 4 hane, int[] dönüşümü taşmasın).
-- Karşılaştırma sayısal: int[] dizileri eleman eleman karşılaştırılır (1.10.0 > 1.9.0).
CREATE TABLE IF NOT EXISTS public.app_config (
  platform               text        PRIMARY KEY CHECK (platform IN ('android', 'ios')),
  min_supported_version  text        NOT NULL CHECK (min_supported_version ~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$'),
  latest_version         text        NOT NULL CHECK (latest_version ~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$'),
  -- iOS uygulaması App Store'a girene kadar NULL: uygulama "Mağazaya git" yerine
  -- açıklama gösterir.
  store_url              text        CHECK (store_url ~ '^https://'),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  CHECK (string_to_array(min_supported_version, '.')::int[]
         <= string_to_array(latest_version, '.')::int[])
);

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "app_config_select" ON public.app_config;
CREATE POLICY "app_config_select" ON public.app_config
  FOR SELECT TO anon, authenticated USING (true);
REVOKE ALL ON public.app_config FROM public, anon, authenticated;
GRANT SELECT ON public.app_config TO anon, authenticated;

-- Başlangıç: ilk yayın sürümü, kimse kilitlenmez.
INSERT INTO public.app_config (platform, min_supported_version, latest_version, store_url)
VALUES ('android', '0.1.0', '0.1.0', 'https://play.google.com/store/apps/details?id=com.atlas.dentlink'),
       ('ios',     '0.1.0', '0.1.0', NULL)
ON CONFLICT (platform) DO NOTHING;

-- ─── set_app_config ─────────────────────────────────────────────────────────
-- Boş p_store_url bağlantıyı kaldırır. Biçim ve min ≤ latest hataları 22023.
CREATE OR REPLACE FUNCTION public.set_app_config(
  p_platform   text,
  p_min        text,
  p_latest     text,
  p_store_url  text DEFAULT NULL,
  p_reason     text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_min    text := btrim(coalesce(p_min, ''));
  v_latest text := btrim(coalesce(p_latest, ''));
  v_url    text := nullif(btrim(coalesce(p_store_url, '')), '');
  v_old    public.app_config;
BEGIN
  IF NOT public.has_permission('config.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF v_min !~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$' OR v_latest !~ '^\d{1,4}\.\d{1,4}\.\d{1,4}$' THEN
    RAISE EXCEPTION 'invalid version' USING ERRCODE = '22023';
  END IF;
  IF string_to_array(v_min, '.')::int[] > string_to_array(v_latest, '.')::int[] THEN
    RAISE EXCEPTION 'min above latest' USING ERRCODE = '22023';
  END IF;
  IF v_url IS NOT NULL AND v_url !~ '^https://' THEN
    RAISE EXCEPTION 'invalid store url' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_old FROM public.app_config WHERE platform = p_platform FOR UPDATE;
  IF v_old.platform IS NULL THEN
    RAISE EXCEPTION 'platform not found' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.app_config
     SET min_supported_version = v_min, latest_version = v_latest,
         store_url = v_url, updated_at = now()
   WHERE platform = p_platform;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason, detail)
  VALUES ('config.update', 'app_config', p_platform, nullif(btrim(coalesce(p_reason, '')), ''),
          jsonb_build_object(
            'old', jsonb_build_object('min', v_old.min_supported_version,
                                      'latest', v_old.latest_version, 'store_url', v_old.store_url),
            'new', jsonb_build_object('min', v_min, 'latest', v_latest, 'store_url', v_url)));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_app_config(text, text, text, text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.set_app_config(text, text, text, text, text) TO authenticated;
