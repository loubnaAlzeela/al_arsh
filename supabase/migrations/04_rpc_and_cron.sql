-- ============================================================
-- AL ARSH — Migration 04: Missing SQL Functions
-- Run AFTER 03_functions_triggers.sql
-- ============================================================

-- ──────────────────────────────────────────────
-- increment_views RPC (called from Flutter app)
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.increment_views(post_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.posts
  SET raw_views = raw_views + 1
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.increment_views(uuid) TO authenticated;

-- ──────────────────────────────────────────────
-- hashtext function (used in posts_anonymous view)
-- Ensure it exists (it's built-in to Postgres, but let's guard)
-- ──────────────────────────────────────────────

-- ──────────────────────────────────────────────
-- Cron Jobs (require pg_cron extension)
-- ──────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Run calculate_scores every hour
SELECT cron.schedule(
  'calculate-scores-hourly',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/calculate_scores',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- ──────────────────────────────────────────────
-- Database Webhook for distribute_post
-- Set this up in Supabase Dashboard:
-- Database → Webhooks → Create a new webhook
--   Name: distribute_post_on_insert
--   Table: posts
--   Events: INSERT
--   URL: https://<project-ref>.supabase.co/functions/v1/distribute_post
--   HTTP Method: POST
--   Headers: Authorization: Bearer <service_role_key>
-- ──────────────────────────────────────────────

-- ──────────────────────────────────────────────
-- Function to get leaderboard (used by admin)
-- ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_week_leaderboard(p_week_id uuid, p_tier text)
RETURNS TABLE (
  user_id    uuid,
  username   text,
  display_name text,
  avatar_url text,
  level      text,
  total_score decimal
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.level,
    COALESCE(SUM(p.normalized_score), 0) as total_score
  FROM public.users u
  JOIN public.posts p ON p.user_id = u.id
  WHERE p.week_id = p_week_id
    AND u.tier = p_tier
    AND p.is_active = true
  GROUP BY u.id, u.username, u.display_name, u.avatar_url, u.level
  ORDER BY total_score DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;
