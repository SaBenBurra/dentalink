-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 045: "Benzer vakalar" kalktı
-- ═══════════════════════════════════════════════════════════════════════════════
-- Post sayfasındaki bölüm kaldırıldı; related_case_ids (040) artık çağrılmıyor.
-- ═══════════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.related_case_ids(uuid, integer);
