-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 054: Panel hesapları kullanıcı aramasında görünmez
-- ═══════════════════════════════════════════════════════════════════════════════
-- Panel personeli ayrı hesapla, kullanıcı adı + şifreyle girer (ADMIN_PANEL.md).
-- staff, support_messages.sender_id ve staff_actions public.users'a bağlı
-- olduğundan panel hesabının da bir users satırı var; onboarding_completed =
-- false kalır. Önerilenler (041) ve popüler kullanıcılar (050) bunları zaten
-- dışlıyordu; arama dışlamıyordu. Kaydını bitirmemiş uygulama kullanıcıları da
-- artık aramada çıkmaz (profilleri boş).
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.search_user_ids(p_query text, p_limit integer DEFAULT 30)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT u.id
    FROM public.users u,
         (SELECT public.search_tsquery(p_query, false) AS tsq) q
   WHERE q.tsq IS NOT NULL
     AND u.search_vector @@ q.tsq
     AND u.onboarding_completed
     AND u.id IS DISTINCT FROM (select auth.uid())
     AND NOT public.is_blocked_between((select auth.uid()), u.id)
   ORDER BY ts_rank(u.search_vector, q.tsq) DESC,
            u.followers_count DESC,
            u.id
   LIMIT least(greatest(p_limit, 1), 50);
$$;
