-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 024: Hesap silme (UX-5)
-- ═══════════════════════════════════════════════════════════════════════════════
-- auth.users satırı silinir; public.users ve ona bağlı her tablo (post, yorum,
-- beğeni, takip, sohbet, mesaj, bildirim, rapor, engel) ON DELETE CASCADE ile
-- gider. Sohbet karşı taraftan da silinir.
-- Storage dosyaları SQL ile silinemez; istemci RPC'den önce kendi klasörlerini
-- (avatars/{uid}, post-images/{uid}) Storage API ile boşaltır.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.delete_account()
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
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_account() TO authenticated;
