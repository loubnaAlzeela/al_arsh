-- ============================================================
-- Fix: cron jobs relied on current_setting('app.supabase_url' / 'app.supabase_anon_key'),
-- which was never configured on the database (no ALTER DATABASE ... SET anywhere).
-- Every scheduled run of calculate-scores-hourly / announce-winners-weekly has been
-- failing silently, so free (unpaid) votes never sync into weekly_votes and posts
-- that only rely on free votes (mostly مجهول/موهبة users) never appear in rankings.
-- Fix: hardcode the project URL + anon key directly in the cron job body.
-- ============================================================

-- ── Re-schedule calculate_scores hourly ─────────────────────
SELECT cron.unschedule('calculate-scores-hourly') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'calculate-scores-hourly'
);

SELECT cron.schedule(
  'calculate-scores-hourly',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url     := 'https://nkrbpmlynnsgzftskysg.supabase.co/functions/v1/calculate_scores',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rcmJwbWx5bm5zZ3pmdHNreXNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjQyMjQsImV4cCI6MjA5NzIwMDIyNH0.aH5wQoYex30XR4_hYKdt_nhJxa5e3TZH1czSkGkCRfs',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- ── Re-schedule announce_winners weekly (Saturday 20:00 UTC) ─
SELECT cron.unschedule('announce-winners-weekly') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'announce-winners-weekly'
);

SELECT cron.schedule(
  'announce-winners-weekly',
  '0 20 * * 6',
  $$
  SELECT net.http_post(
    url     := 'https://nkrbpmlynnsgzftskysg.supabase.co/functions/v1/announce_winners',
    headers := jsonb_build_object(
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rcmJwbWx5bm5zZ3pmdHNreXNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjQyMjQsImV4cCI6MjA5NzIwMDIyNH0.aH5wQoYex30XR4_hYKdt_nhJxa5e3TZH1czSkGkCRfs',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
