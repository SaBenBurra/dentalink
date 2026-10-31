-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 031: gruplanmış mesaj bildirimi
-- ═══════════════════════════════════════════════════════════════════════════════
-- push Edge Function sohbetin okunmamış son mesajlarını tek bildirimde listeler;
-- silinmemiş mesajları tarihe göre sıralamak için iki kolon daha okur
-- (028 ile aynı ilke: yalnızca okunan kolonlar).
-- ═══════════════════════════════════════════════════════════════════════════════

GRANT SELECT (created_at, deleted_at) ON public.messages TO service_role;
