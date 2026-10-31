-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 030: mesaj push'larını birleştirme
-- ═══════════════════════════════════════════════════════════════════════════════
-- push Edge Function, alıcının o sohbette zaten okunmamış mesajı varsa yeni
-- push atmaz; bunun için mesajın sohbetini ve okunmamış sayaçlarını okur
-- (028 ile aynı ilke: yalnızca okunan kolonlar).
-- ═══════════════════════════════════════════════════════════════════════════════

GRANT SELECT (conversation_id) ON public.messages TO service_role;
GRANT SELECT (id, user1_id, user1_unread_count, user2_unread_count) ON public.conversations TO service_role;
