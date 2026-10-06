-- ============================================================
-- Re-schedule calculate_scores / announce_winners crons to send a
-- shared secret header, since those functions now require it (or
-- an admin login) instead of trusting any caller with the public
-- anon key. Run AFTER setting the CRON_SECRET edge function secret
-- to the same value used below.
-- ============================================================

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
      'x-cron-secret', 'ef5b13b8e03e6d4bc55c6ac13fd0542c1dde2867fc7a2e50a3bed8f52039d813',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

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
      'x-cron-secret', 'ef5b13b8e03e6d4bc55c6ac13fd0542c1dde2867fc7a2e50a3bed8f52039d813',
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
