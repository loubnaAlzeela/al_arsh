-- ============================================================
-- Fix: check_level_up() computed a new level but never persisted it to
-- users.level (it only ever updated `tier`), and nothing ever called it —
-- no trigger, no cron, no edge function. Result: the "100 votes / 7-day
-- streak" promotion rule advertised in the app UI (app_strings.dart
-- levelDescriptions) has never actually promoted anyone. The only real
-- promotion path was winning a weekly tier (announce_winners edge function).
-- ============================================================

-- 1. Rewrite check_level_up: actually persist the new level, climb through
--    every qualifying level in one call (not just one hop), and notify the
--    user like the win-based promotion path already does.
CREATE OR REPLACE FUNCTION public.check_level_up(p_user_id uuid)
RETURNS text AS $$
DECLARE
  v_user         public.users%ROWTYPE;
  v_total_votes  integer;
  v_old_level    text;
  v_new_level    text;
  v_new_tier     text;
BEGIN
  SELECT * INTO v_user FROM public.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT COALESCE(SUM(weight), 0) INTO v_total_votes
  FROM public.votes v
  JOIN public.posts p ON p.id = v.post_id
  WHERE p.user_id = p_user_id;

  v_old_level := v_user.level;
  v_new_level := v_user.level;

  LOOP
    IF v_new_level = 'مجهول' AND (v_user.streak_days >= 7 OR v_total_votes >= 100) THEN
      v_new_level := 'موهبة';
    ELSIF v_new_level = 'موهبة' AND v_total_votes >= 500 THEN
      v_new_level := 'صاعد';
    ELSIF v_new_level = 'صاعد' AND v_total_votes >= 2000 THEN
      v_new_level := 'نجم';
    ELSE
      EXIT;
    END IF;
  END LOOP;

  v_new_tier := CASE
    WHEN v_new_level IN ('مجهول', 'موهبة') THEN 'blue'
    WHEN v_new_level IN ('صاعد', 'نجم')   THEN 'gold'
    ELSE 'red'
  END;

  IF v_new_level != v_old_level THEN
    UPDATE public.users
    SET level = v_new_level, tier = v_new_tier
    WHERE id = p_user_id;

    INSERT INTO public.notifications (user_id, type, title, body, created_at)
    VALUES (
      p_user_id,
      'level_up',
      'ترقية المستوى! ⬆️',
      'تهانينا! وصلت إلى مستوى ' || v_new_level,
      NOW()
    );
  ELSIF v_user.tier != v_new_tier THEN
    UPDATE public.users SET tier = v_new_tier WHERE id = p_user_id;
  END IF;

  RETURN v_new_level;
END;
$$ LANGUAGE plpgsql;

-- 2. Wire it into the vote trigger — total_votes changes whenever someone
--    receives a new vote.
CREATE OR REPLACE FUNCTION public.update_likes_on_vote()
RETURNS TRIGGER AS $$
DECLARE
  v_owner uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET raw_likes = raw_likes + NEW.weight
    WHERE id = NEW.post_id
    RETURNING user_id INTO v_owner;

    IF v_owner IS NOT NULL THEN
      PERFORM public.check_level_up(v_owner);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Wire it into the streak trigger — streak_days changes whenever the
--    user publishes a new post.
CREATE OR REPLACE FUNCTION public.update_streak_on_post()
RETURNS TRIGGER AS $$
DECLARE
  v_last_post  date;
  v_today      date := CURRENT_DATE;
BEGIN
  SELECT last_post_date INTO v_last_post
  FROM public.users WHERE id = NEW.user_id;

  IF v_last_post IS NULL THEN
    UPDATE public.users
    SET streak_days = 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  ELSIF v_last_post = v_today - INTERVAL '1 day' THEN
    UPDATE public.users
    SET streak_days = streak_days + 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  ELSIF v_last_post < v_today - INTERVAL '1 day' THEN
    UPDATE public.users
    SET streak_days = 1, last_post_date = v_today
    WHERE id = NEW.user_id;
  END IF;
  -- Same day = no change to streak

  PERFORM public.check_level_up(NEW.user_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. One-time backfill: promote any existing user who already qualifies
--    under the fixed rule but was never updated because the function used
--    to be inert.
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  FOR v_user_id IN SELECT id FROM public.users WHERE level != 'أسطورة' LOOP
    PERFORM public.check_level_up(v_user_id);
  END LOOP;
END $$;
