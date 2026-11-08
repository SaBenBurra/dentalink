-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 047: Keşfet'te popüler kişiler
-- ═══════════════════════════════════════════════════════════════════════════════
-- Kişinin skoru, son 30 gündeki postlarının post_hot_score (035) toplamıdır:
-- postlardaki gibi etkileşim yaşla söner, yeni ve çok etkileşim alan paylaşımlar
-- kişiyi üste taşır. 30 günde postu olmayan listeye girmez. Kendini,
-- engellenenleri ve kaydını bitirmemişleri dışlar.
-- ═══════════════════════════════════════════════════════════════════════════════

-- shortcut: her istekte son 30 günün tüm postlarını toplar; post sayısı on binleri geçince skoru periyodik hesapla.
CREATE OR REPLACE FUNCTION public.popular_user_ids(
  p_now   timestamptz DEFAULT now(),
  p_limit integer     DEFAULT 5
)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT u.id
    FROM public.users u
    JOIN public.posts p ON p.user_id = u.id
   WHERE u.id IS DISTINCT FROM (select auth.uid())
     AND u.onboarding_completed
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
     AND p.created_at > p_now - interval '30 days'
   GROUP BY u.id
   ORDER BY sum(public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                      p.view_count, p_now - p.created_at)) DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 20);
$$;

REVOKE EXECUTE ON FUNCTION public.popular_user_ids(timestamptz, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_user_ids(timestamptz, integer) TO authenticated;
-- Bu fonksiyon SECURITY DEFINER değil; skoru çağıranın yetkisiyle hesaplar.
GRANT EXECUTE ON FUNCTION public.post_hot_score(integer, integer, integer, integer, interval)
  TO authenticated;
