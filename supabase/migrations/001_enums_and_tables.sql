-- ═══════════════════════════════════════════════════════════════════════════════
-- DentLink — Migration 001: ENUM Tipleri ve Tablolar
-- ═══════════════════════════════════════════════════════════════════════════════
-- Çalıştırma sırası: Bu dosya İLK çalıştırılmalıdır.
-- Hedef: Supabase Dashboard → SQL Editor → New Query → Yapıştır → Run
-- ═══════════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. ENUM TİPLERİ
-- ─────────────────────────────────────────────────────────────────────────────

-- Kullanıcı Unvanları (Dart: UserTitle.dbValue ile eşleşir)
DO $$ BEGIN
  CREATE TYPE user_title AS ENUM (
    'ogrenci',
    'dis_hekimi',
    'endodontist',
    'ortodontist',
    'periodontolog',
    'protez_uzmani',
    'pedodontist',
    'agiz_dis_cene_cerrahi',
    'agiz_dis_cene_radyologu',
    'restoratif_dis_tedavisi_uzmani',
    'oral_diagnoz_uzmani'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Diş Hekimliği Branşları (Dart: DentalBranch.dbValue ile eşleşir)
DO $$ BEGIN
  CREATE TYPE dental_branch AS ENUM (
    'pedodontist',
    'endodontist',
    'ortodontist',
    'periodontolog',
    'protez_uzmani',
    'agiz_dis_cene_cerrahi',
    'agiz_dis_cene_radyologu',
    'oral_diagnoz_uzmani',
    'restoratif_dis_tedavisi_uzmani'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Gönderi Türleri (Dart: PostType.dbValue ile eşleşir)
DO $$ BEGIN
  CREATE TYPE post_type AS ENUM ('case', 'question');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Bildirim Türleri (Dart: NotificationType.dbValue ile eşleşir)
DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM (
    'like', 'comment', 'follow', 'message', 'best_answer', 'badge'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. TABLOLAR
-- ─────────────────────────────────────────────────────────────────────────────

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.1  USERS (Kullanıcı Profilleri)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Not: Bu tablo zaten mevcut olabilir. DROP + CREATE yerine güvenli yaklaşım:
-- Tablo yoksa oluştur, varsa eksik sütunları ALTER ile ekle.

CREATE TABLE IF NOT EXISTS public.users (
  id            uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         text UNIQUE,
  phone         text UNIQUE,
  full_name     text        NOT NULL,
  username      text        NOT NULL UNIQUE,
  avatar_url    text,
  title         user_title  NOT NULL DEFAULT 'dis_hekimi',
  bio           text,
  university    text,
  city          text,
  experience_years integer CHECK (experience_years >= 0),
  workplace     text,

  -- Denormalize sayaçlar (trigger ile güncellenir)
  followers_count  integer NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
  following_count  integer NOT NULL DEFAULT 0 CHECK (following_count >= 0),
  posts_count      integer NOT NULL DEFAULT 0 CHECK (posts_count >= 0),

  -- Durum
  onboarding_completed boolean NOT NULL DEFAULT false,
  is_verified          boolean NOT NULL DEFAULT false,

  -- Zaman damgaları
  last_seen_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- Mevcut tabloya eksik sütunları güvenle ekle
DO $$ BEGIN
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS followers_count integer NOT NULL DEFAULT 0;
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS following_count integer NOT NULL DEFAULT 0;
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS posts_count integer NOT NULL DEFAULT 0;
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;
  ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.2  POSTS (Gönderiler — Vaka + Soru tek tabloda)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.posts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        post_type   NOT NULL,
  title       text        NOT NULL,
  content     text        NOT NULL,

  -- Sadece 'case' tipinde kullanılır (question için NULL)
  branch      dental_branch,

  -- Sadece 'question' tipinde kullanılır
  is_solved   boolean NOT NULL DEFAULT false,

  -- Denormalize sayaçlar
  like_count      integer NOT NULL DEFAULT 0 CHECK (like_count >= 0),
  comment_count   integer NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
  bookmark_count  integer NOT NULL DEFAULT 0 CHECK (bookmark_count >= 0),
  view_count      integer NOT NULL DEFAULT 0 CHECK (view_count >= 0),

  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.3  POST_IMAGES (Gönderi Görselleri)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.post_images (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid    NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  image_url   text    NOT NULL,
  sort_order  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.4  TAGS (Etiketler)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.tags (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text    NOT NULL UNIQUE,
  slug        text    NOT NULL UNIQUE,
  usage_count integer NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
  created_at  timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.5  POST_TAGS (Gönderi ↔ Etiket ilişki tablosu, M:N)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.post_tags (
  post_id uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  tag_id  uuid NOT NULL REFERENCES public.tags(id)  ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.6  COMMENTS (Yorumlar)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.comments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id         uuid    NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id         uuid    NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content         text    NOT NULL,
  is_best_answer  boolean NOT NULL DEFAULT false,

  like_count      integer NOT NULL DEFAULT 0 CHECK (like_count >= 0),

  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.7  LIKES (Beğeniler — Polimorfik: post XOR comment)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.likes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id     uuid REFERENCES public.posts(id)    ON DELETE CASCADE,
  comment_id  uuid REFERENCES public.comments(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),

  -- Tam olarak biri dolu olmalı (XOR)
  CONSTRAINT likes_target_check CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR
    (post_id IS NULL AND comment_id IS NOT NULL)
  )
);

-- Aynı kullanıcı aynı hedefi iki kere beğenemez
-- (partial unique: NULL değerler unique constraint'te yok sayılır PG'de)
CREATE UNIQUE INDEX IF NOT EXISTS idx_likes_unique_post
  ON public.likes (user_id, post_id) WHERE post_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_likes_unique_comment
  ON public.likes (user_id, comment_id) WHERE comment_id IS NOT NULL;


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.8  BOOKMARKS (Kaydedilenler)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id     uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),

  UNIQUE (user_id, post_id)
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.9  FOLLOWS (Takip İlişkileri)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.follows (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id   uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id  uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT follows_no_self CHECK (follower_id != following_id),
  UNIQUE (follower_id, following_id)
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.10  CONVERSATIONS (Sohbetler)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.conversations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user2_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  last_message_at       timestamptz,
  last_message_preview  text,
  user1_unread_count    integer NOT NULL DEFAULT 0 CHECK (user1_unread_count >= 0),
  user2_unread_count    integer NOT NULL DEFAULT 0 CHECK (user2_unread_count >= 0),

  created_at  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT conversations_no_self CHECK (user1_id != user2_id)
);

-- Aynı iki kullanıcı arasında tek sohbet (sıra fark etmez)
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique_pair
  ON public.conversations (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id));


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.11  MESSAGES (Mesajlar)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content         text NOT NULL,
  is_read         boolean     NOT NULL DEFAULT false,
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.12  NOTIFICATIONS (Bildirimler)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid              NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  actor_id    uuid              NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  post_id     uuid REFERENCES public.posts(id)    ON DELETE CASCADE,
  comment_id  uuid REFERENCES public.comments(id) ON DELETE CASCADE,
  is_read     boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2.13  BADGES + USER_BADGES (Rozet Sistemi)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.badges (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE,
  description text NOT NULL,
  icon_name   text NOT NULL,
  criteria    jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_badges (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  badge_id  uuid NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (user_id, badge_id)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. İNDEKSLER
-- ─────────────────────────────────────────────────────────────────────────────

-- Users
CREATE INDEX IF NOT EXISTS idx_users_username    ON public.users (username);
CREATE INDEX IF NOT EXISTS idx_users_title       ON public.users (title);
CREATE INDEX IF NOT EXISTS idx_users_city        ON public.users (city) WHERE city IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_created_at  ON public.users (created_at DESC);

-- Posts
CREATE INDEX IF NOT EXISTS idx_posts_user_id      ON public.posts (user_id);
CREATE INDEX IF NOT EXISTS idx_posts_type         ON public.posts (type);
CREATE INDEX IF NOT EXISTS idx_posts_branch       ON public.posts (branch) WHERE branch IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_posts_created_at   ON public.posts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user_type    ON public.posts (user_id, type);

-- Post Images
CREATE INDEX IF NOT EXISTS idx_post_images_post_id ON public.post_images (post_id, sort_order);

-- Tags
CREATE INDEX IF NOT EXISTS idx_tags_slug         ON public.tags (slug);
CREATE INDEX IF NOT EXISTS idx_tags_usage_count  ON public.tags (usage_count DESC);

-- Post Tags
CREATE INDEX IF NOT EXISTS idx_post_tags_tag_id  ON public.post_tags (tag_id);

-- Comments
CREATE INDEX IF NOT EXISTS idx_comments_post_id  ON public.comments (post_id, created_at);
CREATE INDEX IF NOT EXISTS idx_comments_user_id  ON public.comments (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_best     ON public.comments (post_id) WHERE is_best_answer = true;

-- Likes
CREATE INDEX IF NOT EXISTS idx_likes_post_id     ON public.likes (post_id) WHERE post_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_comment_id  ON public.likes (comment_id) WHERE comment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_likes_user_id     ON public.likes (user_id);

-- Bookmarks
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks (user_id, created_at DESC);

-- Follows
CREATE INDEX IF NOT EXISTS idx_follows_follower_id  ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows (following_id);

-- Conversations
CREATE INDEX IF NOT EXISTS idx_conversations_user1    ON public.conversations (user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2    ON public.conversations (user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_msg ON public.conversations (last_message_at DESC NULLS LAST);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages (conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_sender       ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread       ON public.messages (receiver_id) WHERE is_read = false AND deleted_at IS NULL;

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id  ON public.notifications (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread   ON public.notifications (user_id) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_actor_id ON public.notifications (actor_id);

-- User Badges
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON public.user_badges (user_id);


-- ═══════════════════════════════════════════════════════════════════════════════
-- ✅ Migration 001 tamamlandı.
-- Sonraki adım: 002_triggers.sql dosyasını çalıştır.
-- ═══════════════════════════════════════════════════════════════════════════════
