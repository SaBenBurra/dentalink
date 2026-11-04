-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 043: Uygulama adı
-- ═══════════════════════════════════════════════════════════════════════════════
-- Canlı veride adın geçtiği tek yer rozet açıklaması (004).
-- ═══════════════════════════════════════════════════════════════════════════════

UPDATE public.badges
   SET description = replace(description, 'DentLink', 'Dentigo')
 WHERE description LIKE '%DentLink%';
