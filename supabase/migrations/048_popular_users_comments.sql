-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 048: Popüler kişilere yorum etkileşimi
-- ═══════════════════════════════════════════════════════════════════════════════
-- Skor = son 30 gündeki postların post_hot_score toplamı (047)
--      + 0.25 × son 30 gündeki yorumların skoru toplamı.
-- Yorum skoru postlardaki kalıpla: (beğeni + 2×yanıt) / (saat + 2)^1.5. Postların
-- "+1" tabanı yorumda yok: etkileşimsiz yorum çoğaltmak puan getirmez. Ağırlık
-- düşük ki tek bir çok beğenilen yorum paylaşım yapanları geçmesin. Artık
-- yalnızca yorum yapanlar da listeye girebilir (skoru > 0 ise).
-- ═══════════════════════════════════════════════════════════════════════════════

-- shortcut: her istekte son 30 günün tüm post ve yorumlarını toplar; on binleri geçince skoru periyodik hesapla.
CREATE OR REPLACE FUNCTION public.popular_user_ids(
  p_now   timestamptz DEFAULT now(),
  p_limit integer     DEFAULT 5
)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  WITH scores AS (
    SELECT p.user_id,
           public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                 p.view_count, p_now - p.created_at) AS score
      FROM public.posts p
     WHERE p.created_at > p_now - interval '30 days'
    UNION ALL
    SELECT c.user_id,
           0.25 * (c.like_count + 2 * c.reply_count)::float8
             / power(greatest(extract(epoch FROM p_now - c.created_at)::float8 / 3600, 0) + 2, 1.5)
      FROM public.comments c
     WHERE c.created_at > p_now - interval '30 days'
       AND c.like_count + c.reply_count > 0
  )
  SELECT u.id
    FROM public.users u
    JOIN scores s ON s.user_id = u.id
   WHERE u.id IS DISTINCT FROM (select auth.uid())
     AND u.onboarding_completed
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   GROUP BY u.id
   ORDER BY sum(s.score) DESC, u.id
   LIMIT least(greatest(p_limit, 1), 20);
$$;
