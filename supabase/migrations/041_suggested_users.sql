-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 041: Yeni mesajda önerilen kişiler
-- ═══════════════════════════════════════════════════════════════════════════════
-- Sıra: takip ettiklerim, beni takip edenler, aynı üniversite, aynı şehir, en çok
-- takipçisi olanlar. Kendini, engellenenleri ve kaydını bitirmemişleri dışlar.
-- ═══════════════════════════════════════════════════════════════════════════════

-- shortcut: her istekte tüm kullanıcıları sıralar; kullanıcı sayısı on binleri geçince aday havuzunu daralt.
CREATE OR REPLACE FUNCTION public.suggested_user_ids(p_limit integer DEFAULT 20)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT u.id
    FROM public.users u
    LEFT JOIN public.users me ON me.id = (select auth.uid())
   WHERE u.id IS DISTINCT FROM (select auth.uid())
     AND u.onboarding_completed
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   ORDER BY EXISTS (
              SELECT 1 FROM public.follows f
               WHERE f.follower_id = (select auth.uid()) AND f.following_id = u.id
            ) DESC,
            EXISTS (
              SELECT 1 FROM public.follows f
               WHERE f.follower_id = u.id AND f.following_id = (select auth.uid())
            ) DESC,
            (u.university = nullif(me.university, '')) IS TRUE DESC,
            (u.city = nullif(me.city, '')) IS TRUE DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;

REVOKE EXECUTE ON FUNCTION public.suggested_user_ids(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.suggested_user_ids(integer) TO authenticated;
