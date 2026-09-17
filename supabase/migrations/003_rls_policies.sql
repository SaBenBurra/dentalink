-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 003: Row Level Security (RLS) Politikaları
-- ═══════════════════════════════════════════════════════════════════════════════
-- Önkoşul: 001 ve 002 çalıştırılmış olmalı.
-- Hedef: Supabase Dashboard → SQL Editor → New Query → Yapıştır → Run
--
-- ÖNEMLİ: RLS etkinleştirilmeden Supabase API üzerinden hiçbir veri
-- okunamaz/yazılamaz. Bu dosya MUTLAKA çalıştırılmalı.
-- ═══════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════
-- USERS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_all" ON public.users
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- POSTS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "posts_select_all" ON public.posts
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "posts_insert_own" ON public.posts
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "posts_update_own" ON public.posts
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "posts_delete_own" ON public.posts
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- POST_IMAGES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.post_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "post_images_select_all" ON public.post_images
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "post_images_insert_own" ON public.post_images
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND user_id = (select auth.uid())
    )
  );

CREATE POLICY "post_images_delete_own" ON public.post_images
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND user_id = (select auth.uid())
    )
  );


-- ═══════════════════════════════════════════════════════════════════════════════
-- TAGS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tags_select_all" ON public.tags
  FOR SELECT TO authenticated
  USING (true);

-- Herhangi bir authenticated kullanıcı yeni etiket oluşturabilir
CREATE POLICY "tags_insert_auth" ON public.tags
  FOR INSERT TO authenticated
  WITH CHECK (true);


-- ═══════════════════════════════════════════════════════════════════════════════
-- POST_TAGS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.post_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "post_tags_select_all" ON public.post_tags
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "post_tags_insert_own" ON public.post_tags
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND user_id = (select auth.uid())
    )
  );

CREATE POLICY "post_tags_delete_own" ON public.post_tags
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND user_id = (select auth.uid())
    )
  );


-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "comments_insert_own" ON public.comments
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "comments_update_own" ON public.comments
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "comments_delete_own" ON public.comments
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- LIKES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes_select_all" ON public.likes
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "likes_insert_own" ON public.likes
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "likes_delete_own" ON public.likes
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- BOOKMARKS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

-- Sadece kendi bookmark'larını görebilir
CREATE POLICY "bookmarks_select_own" ON public.bookmarks
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "bookmarks_insert_own" ON public.bookmarks
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "bookmarks_delete_own" ON public.bookmarks
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- FOLLOWS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "follows_select_all" ON public.follows
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "follows_insert_own" ON public.follows
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = follower_id);

CREATE POLICY "follows_delete_own" ON public.follows
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = follower_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- CONVERSATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversations_select_own" ON public.conversations
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user1_id OR (select auth.uid()) = user2_id
  );

CREATE POLICY "conversations_insert_own" ON public.conversations
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user1_id OR (select auth.uid()) = user2_id
  );

CREATE POLICY "conversations_update_own" ON public.conversations
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = user1_id OR (select auth.uid()) = user2_id
  )
  WITH CHECK (
    (select auth.uid()) = user1_id OR (select auth.uid()) = user2_id
  );


-- ═══════════════════════════════════════════════════════════════════════════════
-- MESSAGES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "messages_select_own" ON public.messages
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = sender_id OR (select auth.uid()) = receiver_id
  );

CREATE POLICY "messages_insert_own" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = sender_id);

-- Soft delete: sadece kendi mesajını güncelleyebilir
CREATE POLICY "messages_update_own" ON public.messages
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = sender_id)
  WITH CHECK ((select auth.uid()) = sender_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Sadece kendi bildirimlerini görebilir
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- Bildirim oluşturma (trigger veya diğer kullanıcılar da oluşturabilir)
CREATE POLICY "notifications_insert_auth" ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Okundu işaretleme: sadece kendi bildirimini
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- BADGES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "badges_select_all" ON public.badges
  FOR SELECT TO authenticated
  USING (true);

-- Badge oluşturma sadece admin/service_role ile yapılmalı (insert policy yok)


-- ═══════════════════════════════════════════════════════════════════════════════
-- USER_BADGES
-- ═══════════════════════════════════════════════════════════════════════════════
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- Herkes görebilir (profilde rozet vitrini)
CREATE POLICY "user_badges_select_all" ON public.user_badges
  FOR SELECT TO authenticated
  USING (true);

-- Badge atama sadece admin/service_role ile yapılmalı (insert policy yok)


-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 003 tamamlandı.
-- Sonraki adım: 004_search_and_seed.sql dosyasını çalıştır.
-- ═══════════════════════════════════════════════════════════════════════════════
