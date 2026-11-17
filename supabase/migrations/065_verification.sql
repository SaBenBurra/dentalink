-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 065: Mezuniyet ve öğrenci belgesi doğrulama (ADMIN_PANEL.md madde 13, ROADMAP Faz 4)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Kullanıcı mezuniyet belgesini ya da öğrenci belgesini (fotoğraf ya da PDF) private
-- verification-docs bucket'ına yükler ({uid}/…, JPEG ya da PDF, 5 MB) ve
-- submit_verification ile istek açar (doc_type unvandan gelir). Kullanıcı
-- başına tek bekleyen istek; doğrulanmış hesap istek açamaz.
-- Panel (/dogrulama, users.verify):
--   admin_verification_queue  kuyruk (bekleyenler en eski önce), belge yolu dönmez
--   open_verification_doc     belge yolunu verir ve verification.view_doc loglar;
--                             panel yolu 60 sn'lik signed URL ile açar
--   review_verification       onay (users.is_verified = true) ya da gerekçeli ret;
--                             doc_path NULL olur, eski yol döner, panel dosyayı siler
-- KVKK: belge karar verilince silinir (hukukçu farklı bir süre derse burası değişir).
-- Silinemeyen ya da hiç gönderilmeyen dosya sahipsiz medya sayılır (064 genişletildi).
-- Karar push'la bildirilir: status değişince trigger_push('verification'); eski
-- uygulama sürümleri bilinmeyen türü yok sayar (push_provider.dart pushRoute).
-- Bilinen sınır: users.verify yetkilisi Storage API'den belgeyi loglanmadan da
-- imzalayabilir (policy satır bazlı, log RPC'de).
-- Mevcut RPC, kolon ve policy değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Bucket ─────────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('verification-docs', 'verification-docs', false, 5242880, ARRAY['image/jpeg', 'application/pdf'])
ON CONFLICT (id) DO UPDATE
  SET public = false, file_size_limit = 5242880,
      allowed_mime_types = ARRAY['image/jpeg', 'application/pdf'];

-- Sahibi: yükler, okur (hesap silmede klasör listesi), siler. Personel: imzalar, siler.
DROP POLICY IF EXISTS "verification_docs_read" ON storage.objects;
CREATE POLICY "verification_docs_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-docs'
    AND ((select auth.uid())::text = (storage.foldername(name))[1]
         OR (select public.has_permission('users.verify')))
  );

DROP POLICY IF EXISTS "verification_docs_upload" ON storage.objects;
CREATE POLICY "verification_docs_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'verification-docs'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "verification_docs_delete" ON storage.objects;
CREATE POLICY "verification_docs_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'verification-docs'
    AND ((select auth.uid())::text = (storage.foldername(name))[1]
         OR (select public.has_permission('users.verify')))
  );

-- ─── verification_requests ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- Karar verilince NULL (dosya silinir).
  doc_path     text,
  -- Uygulama unvandan seçer: öğrenci → student_certificate, diğerleri →
  -- graduation_certificate. Diploma ve öğrenci kimlik kartı kabul edilmez.
  doc_type     text        NOT NULL
                           CHECK (doc_type IN ('graduation_certificate', 'student_certificate')),
  status       text        NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewer_id  uuid        REFERENCES public.users(id) ON DELETE SET NULL,
  reason       text        CHECK (char_length(reason) <= 500),
  created_at   timestamptz NOT NULL DEFAULT now(),
  reviewed_at  timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS verification_requests_one_pending
  ON public.verification_requests (user_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS verification_requests_user_idx
  ON public.verification_requests (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS verification_requests_status_idx
  ON public.verification_requests (status, created_at);

-- Kullanıcı yalnızca kendi isteklerini okur; yazma RPC'lerle. Personel RPC'den okur.
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "verification_requests_select_own" ON public.verification_requests;
CREATE POLICY "verification_requests_select_own" ON public.verification_requests
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));
REVOKE ALL ON public.verification_requests FROM public, anon, authenticated;
GRANT SELECT (id, doc_type, status, reason, created_at, reviewed_at)
  ON public.verification_requests TO authenticated;
-- Edge Function push: kararı okur (SUPABASE.md §2).
GRANT SELECT (id, user_id, status, reason) ON public.verification_requests TO service_role;

DROP TRIGGER IF EXISTS on_verification_push ON public.verification_requests;
CREATE TRIGGER on_verification_push
  AFTER UPDATE OF status ON public.verification_requests
  FOR EACH ROW
  WHEN (OLD.status = 'pending' AND NEW.status <> 'pending')
  EXECUTE FUNCTION public.trigger_push('verification');

-- ─── submit_verification ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.submit_verification(
  p_doc_path text,
  p_doc_type text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_doc_type IS NULL OR p_doc_type NOT IN ('graduation_certificate', 'student_certificate') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF p_doc_path IS NULL OR p_doc_path NOT LIKE v_uid::text || '/%' OR NOT EXISTS (
       SELECT 1 FROM storage.objects
        WHERE bucket_id = 'verification-docs' AND name = p_doc_path) THEN
    RAISE EXCEPTION 'document not found' USING ERRCODE = 'P0002';
  END IF;
  IF EXISTS (SELECT 1 FROM public.users WHERE id = v_uid AND is_verified) THEN
    RAISE EXCEPTION 'already verified' USING ERRCODE = 'P0001';
  END IF;
  IF EXISTS (SELECT 1 FROM public.verification_requests
              WHERE user_id = v_uid AND status = 'pending') THEN
    RAISE EXCEPTION 'already pending' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.verification_requests (user_id, doc_path, doc_type)
  VALUES (v_uid, p_doc_path, p_doc_type)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_verification(text, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.submit_verification(text, text) TO authenticated;

-- ─── admin_verification_queue ───────────────────────────────────────────────
-- pending: en eski istek önce; approved/rejected: en son karar önce.
CREATE OR REPLACE FUNCTION public.admin_verification_queue(
  p_status text    DEFAULT 'pending',
  p_limit  integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id            uuid,
  user_id       uuid,
  full_name     text,
  username      text,
  title         text,
  university    text,
  city          text,
  workplace     text,
  avatar_url    text,
  is_verified   boolean,
  doc_type      text,
  status        text,
  has_doc       boolean,
  reason        text,
  reviewer_name text,
  created_at    timestamptz,
  reviewed_at   timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_permission('users.verify') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL OR p_status NOT IN ('pending', 'approved', 'rejected') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT r.id, r.user_id, u.full_name, u.username, u.title::text, u.university, u.city,
         u.workplace, u.avatar_url, u.is_verified, r.doc_type, r.status,
         r.doc_path IS NOT NULL, r.reason, rv.full_name, r.created_at, r.reviewed_at
    FROM public.verification_requests r
    JOIN public.users u ON u.id = r.user_id
    LEFT JOIN public.users rv ON rv.id = r.reviewer_id
   WHERE r.status = p_status
   -- CASE yok (SUPABASE.md §1): bekleyende işaret +1 (eski önce), kararda -1 (yeni önce).
   ORDER BY extract(epoch FROM coalesce(r.reviewed_at, r.created_at))
            * (1 - 2 * (p_status <> 'pending')::integer), r.id
   LIMIT least(greatest(coalesce(p_limit, 50), 1), 100)
  OFFSET greatest(coalesce(p_offset, 0), 0);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_verification_queue(text, integer, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_verification_queue(text, integer, integer) TO authenticated;

-- ─── open_verification_doc ──────────────────────────────────────────────────
-- Her açılış loglanır (KVKK).
CREATE OR REPLACE FUNCTION public.open_verification_doc(p_request_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_path text;
  v_user uuid;
BEGIN
  IF NOT public.has_permission('users.verify') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  SELECT doc_path, user_id INTO v_path, v_user
    FROM public.verification_requests WHERE id = p_request_id;
  IF v_path IS NULL THEN
    RAISE EXCEPTION 'document not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.staff_actions (action, target_type, target_id, detail)
  VALUES ('verification.view_doc', 'user', v_user::text,
          jsonb_build_object('request', p_request_id));
  RETURN v_path;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.open_verification_doc(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.open_verification_doc(uuid) TO authenticated;

-- ─── review_verification ────────────────────────────────────────────────────
-- Ret gerekçesi zorunlu (kullanıcıya push'ta ve uygulamada gösterilir).
-- Dönen yol panel tarafından Storage API ile silinir.
CREATE OR REPLACE FUNCTION public.review_verification(
  p_request_id uuid,
  p_approve    boolean,
  p_reason     text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_reason text := nullif(btrim(p_reason), '');
  v_req    public.verification_requests;
  v_status text := 'rejected';
  v_action text := 'verification.reject';
BEGIN
  IF NOT public.has_permission('users.verify') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_approve IS NULL OR char_length(v_reason) > 500 THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;
  IF NOT p_approve AND v_reason IS NULL THEN
    RAISE EXCEPTION 'reason required' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_req FROM public.verification_requests
   WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request not found' USING ERRCODE = 'P0002';
  END IF;
  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'already reviewed' USING ERRCODE = 'P0001';
  END IF;

  IF p_approve THEN
    v_status := 'approved';
    v_action := 'verification.approve';
    UPDATE public.users SET is_verified = true WHERE id = v_req.user_id;
  END IF;

  UPDATE public.verification_requests
     SET status = v_status, reason = v_reason, reviewer_id = auth.uid(),
         reviewed_at = now(), doc_path = NULL
   WHERE id = p_request_id;

  INSERT INTO public.staff_actions (action, target_type, target_id, reason, detail)
  VALUES (v_action, 'user', v_req.user_id::text, v_reason,
          jsonb_build_object('request', p_request_id));

  RETURN v_req.doc_path;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.review_verification(uuid, boolean, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.review_verification(uuid, boolean, text) TO authenticated;

-- ─── Sahipsiz medya (064) ───────────────────────────────────────────────────
-- Bekleyen isteğin belgesi bağlı sayılır; kararı verilmiş ya da hiç gönderilmemiş
-- belge 24 saat sonra media-cleanup ile silinir.
CREATE OR REPLACE FUNCTION public.media_is_referenced(p_bucket text, p_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT CASE p_bucket
    WHEN 'post-images' THEN EXISTS (SELECT 1 FROM public.post_images i WHERE i.image_url = p_name)
    WHEN 'post-videos' THEN EXISTS (SELECT 1 FROM public.post_images i WHERE i.video_path = p_name)
    WHEN 'avatars' THEN EXISTS (
      SELECT 1 FROM public.users u
       WHERE split_part(u.avatar_url, '/storage/v1/object/public/avatars/', 2) = p_name)
    WHEN 'verification-docs' THEN EXISTS (
      SELECT 1 FROM public.verification_requests r WHERE r.doc_path = p_name)
    -- Bilinmeyen bucket: bağlı say, asla silinmesin.
    ELSE true
  END;
$$;

REVOKE EXECUTE ON FUNCTION public.media_is_referenced(text, text) FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_orphan_media(
  p_bucket text,
  p_limit  integer DEFAULT 20
)
RETURNS TABLE (
  name        text,
  size        bigint,
  mimetype    text,
  created_at  timestamptz,
  total_count integer,
  total_bytes bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.has_permission('staff.manage') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;
  IF p_bucket IS NULL
     OR p_bucket NOT IN ('post-images', 'post-videos', 'avatars', 'verification-docs') THEN
    RAISE EXCEPTION 'invalid value' USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT o.name, coalesce((o.metadata->>'size')::bigint, 0), o.metadata->>'mimetype', o.created_at,
         (count(*) OVER ())::integer,
         (sum(coalesce((o.metadata->>'size')::bigint, 0)) OVER ())::bigint
    FROM storage.objects o
   WHERE o.bucket_id = p_bucket
     AND o.created_at < now() - interval '24 hours'
     AND NOT public.media_is_referenced(p_bucket, o.name)
   ORDER BY o.created_at, o.name
   LIMIT least(greatest(coalesce(p_limit, 20), 1), 100);
END;
$$;
