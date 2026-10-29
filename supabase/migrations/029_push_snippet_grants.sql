-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 029: push metinlerinde alıntı (post başlığı, yorum)
-- ═══════════════════════════════════════════════════════════════════════════════
-- push Edge Function bildirim metnine post başlığını ya da yorumun başını koyar
-- (028 ile aynı ilke: yalnızca okunan kolonlar).
-- ═══════════════════════════════════════════════════════════════════════════════

GRANT SELECT (id, title) ON public.posts TO service_role;
GRANT SELECT (id, content) ON public.comments TO service_role;
