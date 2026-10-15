-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 012: Güvenlik sertleştirme
-- AUDIT: SEC-1..8, SEC-10..12, DATA-2, DATA-6, DATA-11, DATA-14, DATA-15
-- Idempotent: tekrar çalıştırılabilir.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── 1. likes: kullanıcı başına hedef başına tek beğeni (DATA-2) ──────────────
-- 005'teki NULLS NOT DISTINCT constraint'leri her kullanıcıyı tek like'a kilitliyordu.
ALTER TABLE public.likes DROP CONSTRAINT IF EXISTS likes_user_post_key;
ALTER TABLE public.likes DROP CONSTRAINT IF EXISTS likes_user_comment_key;

-- Varsa mükerrer like'ları temizle (unique index oluşturulabilsin diye).
DELETE FROM public.likes a USING public.likes b
WHERE a.ctid > b.ctid AND a.user_id = b.user_id
  AND a.post_id IS NOT DISTINCT FROM b.post_id
  AND a.comment_id IS NOT DISTINCT FROM b.comment_id;

CREATE UNIQUE INDEX IF NOT EXISTS likes_user_post_uidx
  ON public.likes (user_id, post_id) WHERE post_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS likes_user_comment_uidx
  ON public.likes (user_id, comment_id) WHERE comment_id IS NOT NULL;

-- Sayaçları gerçek değerlerle yeniden hesapla (olası mükerrerlerden kaynaklı sapma).
UPDATE public.posts p SET like_count = (SELECT count(*) FROM public.likes l WHERE l.post_id = p.id);
UPDATE public.comments c SET like_count = (SELECT count(*) FROM public.likes l WHERE l.comment_id = c.id);

-- ─── 2. users (SEC-1, SEC-6, SEC-12) ─────────────────────────────────────────
-- email/phone zaten auth.users'ta var; public.users'ta herkese açık okunuyordu
-- ve istemciden yazılabildiği için başkasının kaydını engellemeye yarıyordu.
ALTER TABLE public.users DROP COLUMN IF EXISTS email;
ALTER TABLE public.users DROP COLUMN IF EXISTS phone;

-- Sayaçlar, is_verified, created_at yalnızca trigger/admin tarafından yazılır.
REVOKE INSERT, UPDATE ON public.users FROM authenticated;
GRANT INSERT (id, full_name, username, avatar_url, title, bio, university, city,
              experience_years, workplace, onboarding_completed)
  ON public.users TO authenticated;
GRANT UPDATE (full_name, username, avatar_url, title, bio, university, city,
              experience_years, workplace, onboarding_completed, last_seen_at)
  ON public.users TO authenticated;

-- ─── 3. posts & comments (SEC-4, SEC-5) ──────────────────────────────────────
REVOKE INSERT, UPDATE ON public.posts FROM authenticated;
GRANT INSERT (user_id, type, title, content, branch) ON public.posts TO authenticated;
GRANT UPDATE (title, content, branch) ON public.posts TO authenticated;

REVOKE INSERT, UPDATE ON public.comments FROM authenticated;
GRANT INSERT (post_id, user_id, content) ON public.comments TO authenticated;
GRANT UPDATE (content) ON public.comments TO authenticated;

-- ─── 4. messages (SEC-2, SEC-8) ──────────────────────────────────────────────
DROP POLICY IF EXISTS "messages_insert_own" ON public.messages;
CREATE POLICY "messages_insert_own" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND ((c.user1_id = sender_id AND c.user2_id = receiver_id)
          OR (c.user2_id = sender_id AND c.user1_id = receiver_id))
    )
  );

REVOKE INSERT, UPDATE ON public.messages FROM authenticated;
GRANT INSERT (conversation_id, sender_id, receiver_id, content) ON public.messages TO authenticated;
GRANT UPDATE (deleted_at) ON public.messages TO authenticated;  -- yalnızca soft delete

-- ─── 5. conversations (SEC-7) ────────────────────────────────────────────────
-- Oluşturma get_or_create_conversation RPC'si, güncelleme trigger/RPC'ler ile.
DROP POLICY IF EXISTS "conversations_insert_own" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update_own" ON public.conversations;
REVOKE INSERT, UPDATE ON public.conversations FROM authenticated;

-- 001 ve 011 aynı unique index'i iki kez oluşturmuştu (DATA-14).
DROP INDEX IF EXISTS public.unique_conversation_users;

-- ─── 6. notifications (SEC-3) ────────────────────────────────────────────────
-- Bildirimleri yalnızca SECURITY DEFINER trigger'lar oluşturur.
DROP POLICY IF EXISTS "notifications_insert_auth" ON public.notifications;
REVOKE INSERT, UPDATE ON public.notifications FROM authenticated;
GRANT UPDATE (is_read) ON public.notifications TO authenticated;

-- ─── 7. tags (SEC-11) ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "tags_update_auth" ON public.tags;
REVOKE UPDATE ON public.tags FROM authenticated;

-- ─── 8. increment_view_count (DATA-6) ────────────────────────────────────────
-- INVOKER iken RLS yüzünden yalnızca post sahibi sayacı artırabiliyordu.
CREATE OR REPLACE FUNCTION public.increment_view_count(p_post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
  END IF;
  UPDATE public.posts SET view_count = view_count + 1 WHERE id = p_post_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.increment_view_count(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.increment_view_count(uuid) TO authenticated;

-- ─── 9. Ölü fonksiyon (DATA-15) ──────────────────────────────────────────────
-- 004'teki INVOKER sürüm RLS yüzünden hiçbir şey yapmıyordu; 010'daki
-- mark_messages_as_read kullanılıyor.
DROP FUNCTION IF EXISTS public.mark_messages_read(uuid);

-- ─── 10. avatars bucket + policy'ler (SEC-10) ────────────────────────────────
-- Dashboard'dan elle kurulmuştu; artık versiyon kontrolünde.
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (SELECT auth.uid())::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (SELECT auth.uid())::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'avatars' AND (SELECT auth.uid())::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (SELECT auth.uid())::text = (storage.foldername(name))[1]);

-- ─── 11. Realtime yayını (DATA-11) ───────────────────────────────────────────
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['messages', 'conversations'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 012 tamamlandı. Doğrulama: docs/SUPABASE.md §5 smoke testleri.
-- ═══════════════════════════════════════════════════════════════════════════════
