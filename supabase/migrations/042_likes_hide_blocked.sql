-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 042: Beğenenler listesinde engel
-- ═══════════════════════════════════════════════════════════════════════════════
-- Beğenenler listesi açıldı; engel iki yönlü gizler (023), posts ve comments ile
-- aynı kural likes için de geçerli. like_count sayaçları değişmez.
-- ═══════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "likes_select_all" ON public.likes;
CREATE POLICY "likes_select_all" ON public.likes
  FOR SELECT TO authenticated
  USING (NOT public.is_blocked_between((select auth.uid()), user_id));
