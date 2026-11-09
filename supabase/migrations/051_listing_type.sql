-- ═══════════════════════════════════════════════════════════════════════════════
-- Dentigo — Migration 051: Ticaret ilanı türü
-- ═══════════════════════════════════════════════════════════════════════════════
-- Ayrı dosya: yeni enum değeri, eklendiği işlem commit olmadan kullanılamaz
-- (052'deki fonksiyonlar ve indeks onu kullanır).
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TYPE public.post_type ADD VALUE IF NOT EXISTS 'listing';
