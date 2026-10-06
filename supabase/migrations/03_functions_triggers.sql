-- ============================================================
-- AL ARSH (العرش) — Migration 03: Realtime & Helper Functions
-- Run AFTER 02_rls_policies.sql
-- ============================================================

-- ──────────────────────────────────────────────
-- ENABLE REALTIME
-- (Also enable via Supabase Dashboard → Database → Replication)
-- ──────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.votes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.weeks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;

-- ──────────────────────────────────────────────
-- HELPER: Get user tier multiplier
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_tier_multiplier(p_level text)
RETURNS decimal AS $$
BEGIN
  RETURN CASE
    WHEN p_level IN ('مجهول', 'موهبة') THEN 3.0
    WHEN p_level IN ('صاعد', 'نجم')   THEN 1.5
    WHEN p_level IN ('ملك', 'أسطورة') THEN 1.0
    ELSE 3.0
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ──────────────────────────────────────────────
-- HELPER: Calculate normalized score for a post
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.calculate_normalized_score(
  p_views   integer,
  p_likes   integer,
  p_comments integer,
  p_shares  integer,
  p_level   text
) RETURNS decimal AS $$
DECLARE
  v_multiplier     decimal;
  v_engagement     decimal;
  v_score          decimal;
BEGIN
  v_multiplier := public.get_tier_multiplier(p_level);
  v_engagement := (p_likes + p_comments * 2 + p_shares * 3)::decimal
                  / GREATEST(p_views, 1)::decimal;
  v_score := v_engagement * v_multiplier * 1000;
  RETURN ROUND(v_score, 4);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ──────────────────────────────────────────────
-- HELPER: Check if user qualifies for level up
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_level_up(p_user_id uuid)
RETURNS text AS $$
DECLARE
  v_user         public.users%ROWTYPE;
  v_total_votes  integer;
  v_new_level    text;
BEGIN
  SELECT * INTO v_user FROM public.users WHERE id = p_user_id;
  
  SELECT COALESCE(SUM(weight), 0) INTO v_total_votes
  FROM public.votes v
  JOIN public.posts p ON p.id = v.post_id
  WHERE p.user_id = p_user_id;

  v_new_level := v_user.level;

  -- Level progression rules
  IF v_user.level = 'مجهول' AND (
    v_user.streak_days >= 7 OR v_total_votes >= 100
  ) THEN
    v_new_level := 'موهبة';
  END IF;

  IF v_user.level = 'موهبة' AND v_total_votes >= 500 THEN
    v_new_level := 'صاعد';
  END IF;

  IF v_user.level = 'صاعد' AND v_total_votes >= 2000 THEN
    v_new_level := 'نجم';
  END IF;

  -- Tier auto-assignment based on level
  IF v_new_level IN ('مجهول', 'موهبة') THEN
    UPDATE public.users SET tier = 'blue' WHERE id = p_user_id AND tier != 'blue';
  ELSIF v_new_level IN ('صاعد', 'نجم') THEN
    UPDATE public.users SET tier = 'gold' WHERE id = p_user_id AND tier != 'gold';
  ELSIF v_new_level IN ('ملك', 'أسطورة') THEN
    UPDATE public.users SET tier = 'red' WHERE id = p_user_id AND tier != 'red';
  END IF;

  RETURN v_new_level;
END;
$$ LANGUAGE plpgsql;

-- ──────────────────────────────────────────────
-- TRIGGER: Update streak on post insert
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_streak_on_post()
RETURNS TRIGGER AS $$
DECLARE
  v_last_post  date;
  v_today      date := CURRENT_DATE;
BEGIN
  SELECT last_post_date INTO v_last_post
  FROM public.users WHERE id = NEW.user_id;

  IF v_last_post IS NULL THEN
    -- First post ever
    UPDATE public.users
    SET streak_days = 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  ELSIF v_last_post = v_today - INTERVAL '1 day' THEN
    -- Consecutive day
    UPDATE public.users
    SET streak_days = streak_days + 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  ELSIF v_last_post < v_today - INTERVAL '1 day' THEN
    -- Streak broken
    UPDATE public.users
    SET streak_days = 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  END IF;
  -- Same day = no change to streak

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_streak
  AFTER INSERT ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_streak_on_post();

-- ──────────────────────────────────────────────
-- TRIGGER: Update raw_likes count on vote insert
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_likes_on_vote()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET raw_likes = raw_likes + NEW.weight
    WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_likes
  AFTER INSERT ON public.votes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_likes_on_vote();

-- ──────────────────────────────────────────────
-- TRIGGER: Update raw_comments count on comment insert/delete
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET raw_comments = raw_comments + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET raw_comments = GREATEST(raw_comments - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_comments
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_comment_count();

-- ──────────────────────────────────────────────
-- SEED: Create first week (adjust dates as needed)
-- ──────────────────────────────────────────────
INSERT INTO public.weeks (week_number, start_date, end_date, voting_closes_at, announcement_at, status)
VALUES (
  1,
  date_trunc('week', now()),                          -- Monday 00:00
  date_trunc('week', now()) + INTERVAL '6 days 23:59:59',  -- Sunday 23:59
  date_trunc('week', now()) + INTERVAL '5 days 23:59:59',  -- Saturday 23:59 (voting closes)
  date_trunc('week', now()) + INTERVAL '6 days 20:00:00',  -- Sunday 20:00 (announcement)
  'active'
)
ON CONFLICT DO NOTHING;
