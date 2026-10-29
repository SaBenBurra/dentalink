-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 028: push Edge Function için service_role yetkileri
-- ═══════════════════════════════════════════════════════════════════════════════
-- Bu projede service_role'ün public tablolarında varsayılan GRANT'i yok; push
-- fonksiyonu "permission denied for table messages" (42501) ile düşüyordu.
-- Yalnızca fonksiyonun okuduğu/sildiği kolonlar ve tablolar verilir.
-- ═══════════════════════════════════════════════════════════════════════════════

GRANT USAGE ON SCHEMA public TO service_role;

GRANT SELECT (id, sender_id, receiver_id, content) ON public.messages TO service_role;
GRANT SELECT (id, user_id, actor_id, type, post_id, comment_id) ON public.notifications TO service_role;
GRANT SELECT (id, full_name, avatar_url) ON public.users TO service_role;
GRANT SELECT, DELETE ON public.push_tokens TO service_role;
