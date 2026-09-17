-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 004: Full-Text Search, Storage ve Seed Data
-- ═══════════════════════════════════════════════════════════════════════════════
-- Önkoşul: 001, 002, 003 çalıştırılmış olmalı.
-- Hedef: Supabase Dashboard → SQL Editor → New Query → Yapıştır → Run
-- ═══════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. FULL-TEXT SEARCH (Arama desteği)
-- ─────────────────────────────────────────────────────────────────────────────

-- Posts: başlık (A ağırlığı) + içerik (B ağırlığı) üzerinde arama
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(content, '')), 'B')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_posts_search ON public.posts USING GIN (search_vector);

-- Users: isim (A) + kullanıcı adı (A) + üniversite (B) üzerinde arama
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(full_name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(university, '')), 'B')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_users_search ON public.users USING GIN (search_vector);


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. STORAGE BUCKET: post-images
-- ─────────────────────────────────────────────────────────────────────────────
-- Not: Storage bucket'ları SQL ile oluşturulabilir ama Supabase Dashboard
-- üzerinden de yapılabilir. Aşağıdaki SQL Dashboard'da çalışır.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  true,                           -- Public erişim (URL ile görüntülenebilir)
  5242880,                        -- 5 MB maks dosya boyutu
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Authenticated kullanıcılar kendi klasörlerine yükleyebilir
CREATE POLICY "post_images_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "post_images_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-images');

CREATE POLICY "post_images_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );

CREATE POLICY "post_images_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (select auth.uid())::text = (storage.foldername(name))[1]
  );


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. SEED DATA: Rozetler
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.badges (name, description, icon_name, criteria)
VALUES
  (
    'Yeni Üye',
    'DentLink ailesine hoş geldiniz! Kayıt olarak ilk rozetinizi kazandınız.',
    'person_add',
    '{"type": "registration"}'::jsonb
  ),
  (
    'Uzman',
    'Belirli bir branşta 10 veya daha fazla vaka paylaştınız.',
    'workspace_premium',
    '{"type": "case_count", "threshold": 10}'::jsonb
  ),
  (
    'Popüler',
    'Gönderileriniz toplam 100 veya daha fazla beğeni aldı.',
    'favorite',
    '{"type": "total_likes", "threshold": 100}'::jsonb
  ),
  (
    'Yardımsever',
    '5 veya daha fazla cevabınız "En İyi Cevap" olarak seçildi.',
    'emoji_events',
    '{"type": "best_answer_count", "threshold": 5}'::jsonb
  ),
  (
    'Aktif Katılımcı',
    '50 veya daha fazla yorum yaptınız.',
    'forum',
    '{"type": "comment_count", "threshold": 50}'::jsonb
  ),
  (
    'Doğrulanmış Hekim',
    'Diploma/belge doğrulaması tamamlanmış hekim.',
    'verified',
    '{"type": "verification"}'::jsonb
  )
ON CONFLICT (name) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. YARDIMCI FONKSİYON: Okunmamış mesajları sıfırla
-- ─────────────────────────────────────────────────────────────────────────────
-- Kullanım: Kullanıcı bir sohbeti açtığında çağrılır.
-- Flutter'dan: supabase.rpc('mark_messages_read', params: {'p_conversation_id': id})

CREATE OR REPLACE FUNCTION public.mark_messages_read(p_conversation_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_user1_id uuid;
  v_user2_id uuid;
  v_current_user uuid := (select auth.uid());
BEGIN
  -- Conversation bilgilerini al
  SELECT user1_id, user2_id INTO v_user1_id, v_user2_id
  FROM public.conversations
  WHERE id = p_conversation_id;

  -- Yetkisiz erişim kontrolü
  IF v_current_user != v_user1_id AND v_current_user != v_user2_id THEN
    RAISE EXCEPTION 'Bu sohbete erişim yetkiniz yok';
  END IF;

  -- Mesajları okundu işaretle
  UPDATE public.messages
  SET is_read = true
  WHERE conversation_id = p_conversation_id
    AND receiver_id = v_current_user
    AND is_read = false;

  -- Unread count'u sıfırla
  IF v_current_user = v_user1_id THEN
    UPDATE public.conversations SET user1_unread_count = 0 WHERE id = p_conversation_id;
  ELSE
    UPDATE public.conversations SET user2_unread_count = 0 WHERE id = p_conversation_id;
  END IF;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. YARDIMCI FONKSİYON: Mevcut sohbeti bul veya yeni oluştur
-- ─────────────────────────────────────────────────────────────────────────────
-- Kullanım: İlk mesaj gönderilirken sohbet yoksa otomatik oluşturur.
-- Flutter'dan: supabase.rpc('get_or_create_conversation', params: {'p_other_user_id': id})

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(p_other_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_conversation_id uuid;
  v_current_user uuid := (select auth.uid());
BEGIN
  -- Kendine mesaj gönderemez
  IF v_current_user = p_other_user_id THEN
    RAISE EXCEPTION 'Kendinize mesaj gönderemezsiniz';
  END IF;

  -- Mevcut sohbeti bul
  SELECT id INTO v_conversation_id
  FROM public.conversations
  WHERE (user1_id = LEAST(v_current_user, p_other_user_id)
    AND  user2_id = GREATEST(v_current_user, p_other_user_id))
     OR (user1_id = GREATEST(v_current_user, p_other_user_id)
    AND  user2_id = LEAST(v_current_user, p_other_user_id));

  -- Yoksa yeni oluştur
  IF v_conversation_id IS NULL THEN
    INSERT INTO public.conversations (user1_id, user2_id)
    VALUES (LEAST(v_current_user, p_other_user_id), GREATEST(v_current_user, p_other_user_id))
    RETURNING id INTO v_conversation_id;
  END IF;

  RETURN v_conversation_id;
END;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 004 tamamlandı.
-- Tüm migration'lar başarıyla uygulandı!
-- ═══════════════════════════════════════════════════════════════════════════════
