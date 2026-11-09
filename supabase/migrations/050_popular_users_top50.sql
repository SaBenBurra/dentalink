-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 050: Popüler kişiler ilk 50, profilde sıra
-- ═══════════════════════════════════════════════════════════════════════════════
-- Keşfet'teki "Popüler kişiler" başlığından ilk 50 kişinin tam listesi açılır.
-- Numara herkes için aynı gerçek sıradır (popular_users_ranked): kişi kendini de
-- görür, engellenen kişi (iki yönlü) satırıyla birlikte çıkar ve numarası atlanır
-- (yer tutucu yok: kimin engellediğini ele verirdi). Keşfet'in 5'i de aynı
-- sıranın ilk 5'idir. İlk 50'deki kişinin profilinde sırası (popular_user_rank).
-- Skor 048 ile aynı, ortak fonksiyona (popular_user_scores) taşındı. Yeni: hiç
-- etkileşim almamış (beğeni, yorum, kaydetme, yanıt yok) kişiler sıralamaya
-- girmez; postlardaki "+1" taban puan tek başına yetmez. Görüntülenme sayılmaz.
-- popular_user_ids (048) eski uygulama sürümleri için olduğu gibi kalır.
-- ═══════════════════════════════════════════════════════════════════════════════

-- shortcut: her istekte son 30 günün tüm post ve yorumlarını toplar; on binleri geçince skoru periyodik hesapla.
CREATE OR REPLACE FUNCTION public.popular_user_scores(
  p_now timestamptz DEFAULT now()
)
RETURNS TABLE (user_id uuid, score float8)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  WITH scores AS (
    SELECT p.user_id,
           public.post_hot_score(p.like_count, p.comment_count, p.bookmark_count,
                                 p.view_count, p_now - p.created_at) AS score,
           p.like_count + p.comment_count + p.bookmark_count AS engagement
      FROM public.posts p
     WHERE p.created_at > p_now - interval '30 days'
    UNION ALL
    SELECT c.user_id,
           0.25 * (c.like_count + 2 * c.reply_count)::float8
             / power(greatest(extract(epoch FROM p_now - c.created_at)::float8 / 3600, 0) + 2, 1.5),
           c.like_count + c.reply_count
      FROM public.comments c
     WHERE c.created_at > p_now - interval '30 days'
       AND c.like_count + c.reply_count > 0
  )
  SELECT u.id, sum(s.score)
    FROM public.users u
    JOIN scores s ON s.user_id = u.id
   WHERE u.onboarding_completed
   GROUP BY u.id
  HAVING sum(s.engagement) > 0;
$$;

-- Herkes için aynı genel sıra (kendisi dışlanmaz).
CREATE OR REPLACE FUNCTION public.popular_user_ranks(
  p_now timestamptz DEFAULT now()
)
RETURNS TABLE (user_id uuid, rank integer)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT s.user_id,
         (row_number() OVER (ORDER BY s.score DESC, s.user_id))::integer
    FROM public.popular_user_scores(p_now) s;
$$;

-- İlk p_limit sıradaki (en fazla 50) kişiler gerçek sıralarıyla; çağıranla arasında
-- engel olanlar çıkar, numaraları atlanır.
CREATE OR REPLACE FUNCTION public.popular_users_ranked(
  p_now   timestamptz DEFAULT now(),
  p_limit integer     DEFAULT 5
)
RETURNS TABLE (user_id uuid, rank integer)
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT r.user_id, r.rank
    FROM public.popular_user_ranks(p_now) r
   WHERE r.rank <= least(greatest(p_limit, 1), 50)
     AND NOT public.is_blocked_between((select auth.uid()), r.user_id)
   ORDER BY r.rank;
$$;

-- Profildeki sıra; ilk 50'de değilse NULL.
CREATE OR REPLACE FUNCTION public.popular_user_rank(
  p_user uuid,
  p_now  timestamptz DEFAULT now()
)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT r.rank
    FROM public.popular_user_ranks(p_now) r
   WHERE r.user_id = p_user
     AND r.rank <= 50;
$$;

-- SECURITY DEFINER değiller; skoru çağıranın yetkisiyle hesaplarlar.
REVOKE EXECUTE ON FUNCTION public.popular_user_scores(timestamptz) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_user_scores(timestamptz) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.popular_user_ranks(timestamptz) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_user_ranks(timestamptz) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.popular_users_ranked(timestamptz, integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_users_ranked(timestamptz, integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.popular_user_rank(uuid, timestamptz) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.popular_user_rank(uuid, timestamptz) TO authenticated;
