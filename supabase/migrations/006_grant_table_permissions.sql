-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 006: Tablo Düzeyi Yetkilendirme (GRANT)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Sorun: RLS politikaları satır düzeyinde erişimi kontrol eder, ancak
--        tabloya erişim için GRANT izinleri de gereklidir.
--        Bu izinler olmadan "permission denied for table users" (42501) hatası alınır.
--
-- Hedef: Supabase Dashboard → SQL Editor → New Query → Yapıştır → Run
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── USERS ────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;

-- ── POSTS ────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;

-- ── POST_IMAGES ──────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.post_images TO authenticated;

-- ── TAGS ─────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT ON public.tags TO authenticated;

-- ── POST_TAGS ────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.post_tags TO authenticated;

-- ── COMMENTS ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.comments TO authenticated;

-- ── LIKES ────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.likes TO authenticated;

-- ── BOOKMARKS ────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.bookmarks TO authenticated;

-- ── FOLLOWS ──────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.follows TO authenticated;

-- ── CONVERSATIONS ────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.conversations TO authenticated;

-- ── MESSAGES ─────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;

-- ── NOTIFICATIONS ────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;

-- ── BADGES ───────────────────────────────────────────────────────────────────
GRANT SELECT ON public.badges TO authenticated;

-- ── USER_BADGES ──────────────────────────────────────────────────────────────
GRANT SELECT ON public.user_badges TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 006 tamamlandı.
-- Artık authenticated kullanıcılar RLS politikalarına uygun şekilde
-- tablolara erişebilir.
-- ═══════════════════════════════════════════════════════════════════════════════
