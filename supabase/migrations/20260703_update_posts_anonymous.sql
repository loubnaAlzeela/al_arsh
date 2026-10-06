CREATE OR REPLACE VIEW public.posts_anonymous AS
SELECT
  p.id,
  p.week_id,
  -- Expose user_id when week is announced OR when it's the current user's own post
  CASE
    WHEN w.status = 'announced' OR p.user_id = auth.uid() THEN p.user_id
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
