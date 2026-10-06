-- ============================================================
-- AL ARSH (العرش) — DATABASE SCHEMA — Migration 01: Tables
-- Run this in Supabase SQL Editor
-- ============================================================

-- ──────────────────────────────────────────────
-- 1. USERS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id                        uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username                  text UNIQUE NOT NULL,
  display_name              text NOT NULL,
  avatar_url                text,
  level                     text NOT NULL DEFAULT 'مجهول'
                              CHECK (level IN ('مجهول','موهبة','صاعد','نجم','ملك','أسطورة')),
  tier                      text NOT NULL DEFAULT 'blue'
                              CHECK (tier IN ('blue','gold','red')),
  total_competition_points  integer NOT NULL DEFAULT 0,
  weekly_competition_points integer NOT NULL DEFAULT 0,
  audience_points           integer NOT NULL DEFAULT 0,
  streak_days               integer NOT NULL DEFAULT 0,
  last_post_date            date,
  is_banned                 boolean NOT NULL DEFAULT false,
  is_admin                  boolean NOT NULL DEFAULT false,
  red_tier_wins             integer NOT NULL DEFAULT 0,
  created_at                timestamptz NOT NULL DEFAULT now()
);

-- ──────────────────────────────────────────────
-- 2. WEEKS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.weeks (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_number       integer NOT NULL,
  start_date        timestamptz NOT NULL,
  end_date          timestamptz NOT NULL,
  voting_closes_at  timestamptz NOT NULL,
  announcement_at   timestamptz NOT NULL,
  status            text NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active','voting_closed','announced')),
  blue_winner_id    uuid REFERENCES public.users(id) ON DELETE SET NULL,
  gold_winner_id    uuid REFERENCES public.users(id) ON DELETE SET NULL,
  red_winner_id     uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ──────────────────────────────────────────────
-- 3. POSTS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.posts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  week_id           uuid NOT NULL REFERENCES public.weeks(id) ON DELETE CASCADE,
  content_type      text NOT NULL CHECK (content_type IN ('video','image','text')),
  content_url       text,
  thumbnail_url     text,
  caption           text CHECK (char_length(caption) <= 200),
  category          text NOT NULL
                      CHECK (category IN ('موهبة','كوميديا','تجارة','تحدي','فكرة','أخرى')),
  raw_views         integer NOT NULL DEFAULT 0,
  raw_likes         integer NOT NULL DEFAULT 0,
  raw_comments      integer NOT NULL DEFAULT 0,
  raw_shares        integer NOT NULL DEFAULT 0,
  normalized_score  decimal(12,4) NOT NULL DEFAULT 0,
  is_active         boolean NOT NULL DEFAULT true,
  is_reported       boolean NOT NULL DEFAULT false,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ──────────────────────────────────────────────
-- 4. VOTES
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.votes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id    uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id     uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  week_id     uuid NOT NULL REFERENCES public.weeks(id) ON DELETE CASCADE,
  weight      integer NOT NULL DEFAULT 1,  -- 0 for accounts < 48h old
  voted_at    timestamptz NOT NULL DEFAULT now(),
  -- Anti-manipulation: one vote per user per week
  CONSTRAINT one_vote_per_week UNIQUE (voter_id, week_id)
);

-- ──────────────────────────────────────────────
-- 5. POST DISTRIBUTIONS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.post_distributions (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id   uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id   uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shown_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT unique_distribution UNIQUE (post_id, user_id)
);

-- ──────────────────────────────────────────────
-- 6. COMMENTS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.comments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content     text NOT NULL CHECK (char_length(content) <= 500),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ──────────────────────────────────────────────
-- 7. NOTIFICATIONS
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        text NOT NULL
                CHECK (type IN ('vote_received','week_winner','level_up','streak','new_follower')),
  title       text NOT NULL,
  body        text NOT NULL,
  related_id  uuid,  -- post_id, week_id, or user_id depending on type
  is_read     boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ──────────────────────────────────────────────
-- INDEXES for performance
-- ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_posts_week_id       ON public.posts(week_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id       ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_score         ON public.posts(normalized_score DESC);
CREATE INDEX IF NOT EXISTS idx_votes_post_id       ON public.votes(post_id);
CREATE INDEX IF NOT EXISTS idx_votes_voter_week    ON public.votes(voter_id, week_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user  ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_distributions_user  ON public.post_distributions(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post       ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_weeks_status        ON public.weeks(status);

-- ──────────────────────────────────────────────
-- ANONYMOUS VIEW (hides user_id during active/voting_closed weeks)
-- ──────────────────────────────────────────────
CREATE OR REPLACE VIEW public.posts_anonymous AS
SELECT
  p.id,
  p.week_id,
  -- Only expose user_id when week is announced
  CASE
    WHEN w.status = 'announced' THEN p.user_id
    ELSE NULL
  END AS user_id,
  CASE
    WHEN w.status = 'announced' THEN u.username
    ELSE NULL
  END AS username,
  CASE
    WHEN w.status = 'announced' THEN u.display_name
    ELSE NULL
  END AS display_name,
  CASE
    WHEN w.status = 'announced' THEN u.avatar_url
    ELSE NULL
  END AS avatar_url,
  -- Anonymous creator number derived from post id (consistent within week)
  ('منشئ #' || (abs(hashtext(p.id::text)) % 9000 + 1000)::text) AS creator_label,
  p.content_type,
  p.content_url,
  p.thumbnail_url,
  p.caption,
  p.category,
  p.raw_views,
  p.raw_likes,
  p.raw_comments,
  p.raw_shares,
  p.normalized_score,
  p.is_active,
  p.created_at,
  u.tier,
  u.level,
  w.status AS week_status
FROM public.posts p
JOIN public.weeks w ON w.id = p.week_id
JOIN public.users u ON u.id = p.user_id
WHERE p.is_active = true;
