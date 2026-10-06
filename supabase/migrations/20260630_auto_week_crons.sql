-- ============================================================
-- ZUVOXA — Auto Week Management Crons
-- Makes competition weeks run continuously without stopping
-- ============================================================

-- ── 1. Function: close voting when time is up ────────────────
CREATE OR REPLACE FUNCTION public.auto_close_voting()
RETURNS void AS $$
BEGIN
  UPDATE public.weeks
  SET status = 'voting_closed'
  WHERE status = 'active'
    AND voting_closes_at <= NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 2. Function: auto-create new week if none exists ─────────
-- Called after announce_winners; also acts as a safety net.
CREATE OR REPLACE FUNCTION public.ensure_active_week()
RETURNS void AS $$
DECLARE
  v_active_count int;
  v_last_week_number int;
  v_start date;
  v_end timestamp;
  v_voting_close timestamp;
  v_announcement timestamp;
BEGIN
  -- Count active or voting_closed weeks
  SELECT COUNT(*) INTO v_active_count
  FROM public.weeks
  WHERE status IN ('active', 'voting_closed');

  -- If there's already an active/voting week, do nothing
  IF v_active_count > 0 THEN
    RETURN;
  END IF;

  -- Get last week number
  SELECT COALESCE(MAX(week_number), 0) INTO v_last_week_number
  FROM public.weeks;

  -- Build new week dates (7-day week)
  v_start         := NOW();
  v_end           := NOW() + INTERVAL '7 days';
  v_voting_close  := NOW() + INTERVAL '6 days';   -- voting closes 1 day before end
  v_announcement  := NOW() + INTERVAL '6 days 20 hours'; -- announced 4h before end

  INSERT INTO public.weeks (
    week_number,
    start_date,
    end_date,
    voting_closes_at,
    announcement_at,
    status
  ) VALUES (
    v_last_week_number + 1,
    v_start,
    v_end,
    v_voting_close,
    v_announcement,
    'active'
  );

  RAISE NOTICE 'Created new week %', v_last_week_number + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION public.auto_close_voting() TO postgres;
GRANT EXECUTE ON FUNCTION public.ensure_active_week() TO postgres;

-- ── 3. Cron: Close voting every 30 minutes (safety check) ───
SELECT cron.unschedule('auto-close-voting') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'auto-close-voting'
);

SELECT cron.schedule(
  'auto-close-voting',
  '*/30 * * * *',   -- every 30 minutes
  $$ SELECT public.auto_close_voting(); $$
);

-- ── 4. Cron: Ensure active week exists (runs every hour) ─────
SELECT cron.unschedule('ensure-active-week') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'ensure-active-week'
);

SELECT cron.schedule(
  'ensure-active-week',
  '5 * * * *',   -- every hour at :05
  $$ SELECT public.ensure_active_week(); $$
);

-- ── 5. Cron: Trigger announce_winners every Saturday 8PM UTC ─
-- This calls the Edge Function that announces winners AND creates next week
SELECT cron.unschedule('announce-winners-weekly') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'announce-winners-weekly'
);

SELECT cron.schedule(
  'announce-winners-weekly',
  '0 20 * * 6',   -- Saturday at 20:00 UTC (midnight Arabic time)
  $$
  SELECT net.http_post(
    url     := current_setting('app.supabase_url') || '/functions/v1/announce_winners',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key'),
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
