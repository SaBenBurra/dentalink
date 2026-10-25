-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 020: post-images private (Faz 2, SEC-9)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Vaka görselleri (hasta fotoğrafları) URL'yi bilen herkese açıktı (KVKK).
-- Bucket private olur; istemci createSignedUrls ile 1 günlük link üretir.
-- İmzalamak SELECT policy'si ister: yalnızca oturum açmış kullanıcılar.
-- ═══════════════════════════════════════════════════════════════════════════════

UPDATE storage.buckets SET public = false WHERE id = 'post-images';

DROP POLICY IF EXISTS "post_images_read" ON storage.objects;
CREATE POLICY "post_images_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-images');
