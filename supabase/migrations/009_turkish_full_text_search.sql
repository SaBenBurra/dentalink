-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 009: Turkish Full-Text Search
-- ═══════════════════════════════════════════════════════════════════════════════
-- Hedef: Supabase Dashboard → SQL Editor → New Query → Yapıştır → Run
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. POSTS TABLOSU GÜNCELLEMESİ
-- ─────────────────────────────────────────────────────────────────────────────
-- Eski 'simple' sözlük kullanan sütunu kaldırıp 'turkish' ile yeniden ekliyoruz.

ALTER TABLE public.posts DROP COLUMN IF EXISTS search_vector;

ALTER TABLE public.posts ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('turkish', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('turkish', coalesce(content, '')), 'B')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_posts_search ON public.posts USING GIN (search_vector);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. USERS TABLOSU GÜNCELLEMESİ
-- ─────────────────────────────────────────────────────────────────────────────
-- Eski 'simple' sözlük kullanan sütunu kaldırıp 'turkish' ile yeniden ekliyoruz.

ALTER TABLE public.users DROP COLUMN IF EXISTS search_vector;

ALTER TABLE public.users ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('turkish', coalesce(full_name, '')), 'A') ||
    setweight(to_tsvector('turkish', coalesce(username, '')), 'A') ||
    setweight(to_tsvector('turkish', coalesce(university, '')), 'B')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_users_search ON public.users USING GIN (search_vector);
