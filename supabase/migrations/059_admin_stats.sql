-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 059: Panel istatistikleri
-- ═══════════════════════════════════════════════════════════════════════════════
-- admin_stats(p_days): stats.view. Son p_days günün (1–365, Europe/Istanbul günleri)
--   günlük sayıları ve bir özet, tek jsonb:
--   summary: total_users, new_users, active_users, open_reports, open_support,
--            median_first_response_sec
--   daily:   [{day, users, cases, questions, listings, comments, reports}]
-- Kullanıcı sayıları kaydı bitmiş hesaplardır (onboarding_completed): panel hesapları
-- (054) ve yarım kayıtlar sayılmaz.
-- Aktif kullanıcı: dönem içinde oturumu açılmış ya da yenilenmiş hesap (auth.sessions).
--   Bilinen sınır: çıkış yapan ya da banlanan hesabın oturumu silinir, sayılmaz.
-- Medyan ilk cevap: dönemde açılan sohbetlerde created_at → first_response_at.
-- Gizlenen içerik de sayılır (o gün paylaşılmıştı).
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.admin_stats(p_days integer DEFAULT 30)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_days  integer := least(greatest(coalesce(p_days, 30), 1), 365);
  v_first date := (now() AT TIME ZONE 'Europe/Istanbul')::date - (v_days - 1);
  v_since timestamptz := v_first::timestamp AT TIME ZONE 'Europe/Istanbul';
BEGIN
  IF NOT public.has_permission('stats.view') THEN
    RAISE EXCEPTION 'not allowed' USING ERRCODE = '42501';
  END IF;

  RETURN jsonb_build_object(
    'summary', jsonb_build_object(
      'total_users', (SELECT count(*) FROM public.users WHERE onboarding_completed),
      'new_users', (SELECT count(*) FROM public.users
                     WHERE onboarding_completed AND created_at >= v_since),
      'active_users', (SELECT count(DISTINCT s.user_id) FROM auth.sessions s
                         JOIN public.users u ON u.id = s.user_id AND u.onboarding_completed
                        WHERE greatest(s.created_at, s.updated_at) >= v_since),
      'open_reports', (SELECT count(*) FROM public.reports WHERE status = 'open'),
      'open_support', (SELECT count(*) FROM public.support_threads WHERE status = 'open'),
      'median_first_response_sec', (
        SELECT round(extract(epoch FROM percentile_cont(0.5)
                 WITHIN GROUP (ORDER BY first_response_at - created_at)))
          FROM public.support_threads
         WHERE created_at >= v_since AND first_response_at IS NOT NULL)),
    'daily', (
      SELECT jsonb_agg(jsonb_build_object(
               'day', d.day,
               'users', coalesce(u.n, 0),
               'cases', coalesce(p.cases, 0),
               'questions', coalesce(p.questions, 0),
               'listings', coalesce(p.listings, 0),
               'comments', coalesce(c.n, 0),
               'reports', coalesce(r.n, 0))
             ORDER BY d.day)
        FROM (SELECT g::date AS day
                FROM generate_series(v_first, v_first + (v_days - 1), interval '1 day') g) d
        -- Her tablo bir kez taranır (created_at >= v_since), güne göre gruplanır.
        LEFT JOIN (SELECT (created_at AT TIME ZONE 'Europe/Istanbul')::date AS day, count(*) AS n
                     FROM public.users WHERE onboarding_completed AND created_at >= v_since
                    GROUP BY 1) u USING (day)
        LEFT JOIN (SELECT (created_at AT TIME ZONE 'Europe/Istanbul')::date AS day,
                          count(*) FILTER (WHERE type = 'case')     AS cases,
                          count(*) FILTER (WHERE type = 'question') AS questions,
                          count(*) FILTER (WHERE type = 'listing')  AS listings
                     FROM public.posts WHERE created_at >= v_since
                    GROUP BY 1) p USING (day)
        LEFT JOIN (SELECT (created_at AT TIME ZONE 'Europe/Istanbul')::date AS day, count(*) AS n
                     FROM public.comments WHERE created_at >= v_since
                    GROUP BY 1) c USING (day)
        LEFT JOIN (SELECT (created_at AT TIME ZONE 'Europe/Istanbul')::date AS day, count(*) AS n
                     FROM public.reports WHERE created_at >= v_since
                    GROUP BY 1) r USING (day)));
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_stats(integer) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.admin_stats(integer) TO authenticated;
