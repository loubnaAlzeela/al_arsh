-- ============================================================
-- AL ARSH (العرش) — Migration 02: RLS Policies
-- Run AFTER 01_tables.sql
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weeks              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications      ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────
-- USERS policies
-- ──────────────────────────────────────────────
-- Anyone authenticated can read user profiles
CREATE POLICY "users_select_all" ON public.users
  FOR SELECT TO authenticated USING (true);

-- Users can only insert their own profile row
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admin can do anything on users
CREATE POLICY "users_admin_all" ON public.users
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- WEEKS policies
-- ──────────────────────────────────────────────
-- Everyone can read weeks
CREATE POLICY "weeks_select_all" ON public.weeks
  FOR SELECT TO authenticated USING (true);

-- Only admin can insert/update/delete weeks
CREATE POLICY "weeks_admin_write" ON public.weeks
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- POSTS policies
-- ──────────────────────────────────────────────
-- Authenticated users can read all active posts
CREATE POLICY "posts_select_active" ON public.posts
  FOR SELECT TO authenticated
  USING (is_active = true);

-- Users can only insert posts for themselves
CREATE POLICY "posts_insert_own" ON public.posts
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update only their own posts (caption edits)
CREATE POLICY "posts_update_own" ON public.posts
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin can manage all posts
CREATE POLICY "posts_admin_all" ON public.posts
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- VOTES policies
-- ──────────────────────────────────────────────
-- Users can read all votes
CREATE POLICY "votes_select_all" ON public.votes
  FOR SELECT TO authenticated USING (true);

-- Users can only insert votes for themselves
CREATE POLICY "votes_insert_own" ON public.votes
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = voter_id
    -- Anti-manipulation: Cannot vote for own post
    AND NOT EXISTS (
      SELECT 1 FROM public.posts
      WHERE id = post_id AND user_id = auth.uid()
    )
    -- Anti-manipulation: Vote weight = 0 if account < 48 hours old
    -- (weight is set in application layer; RLS allows insert but weight enforced)
  );

-- Users cannot update or delete votes
-- (no update/delete policies = blocked for non-admin)

-- Admin can manage votes
CREATE POLICY "votes_admin_all" ON public.votes
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- POST DISTRIBUTIONS policies
-- ──────────────────────────────────────────────
-- Users can only see their own distribution rows
CREATE POLICY "distributions_select_own" ON public.post_distributions
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Only system (service role / edge functions) can insert
-- Regular users cannot insert distribution rows
CREATE POLICY "distributions_admin_insert" ON public.post_distributions
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- COMMENTS policies
-- ──────────────────────────────────────────────
-- Anyone authenticated can read comments
CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT TO authenticated USING (true);

-- Users can only insert comments for themselves
CREATE POLICY "comments_insert_own" ON public.comments
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can delete only their own comments
CREATE POLICY "comments_delete_own" ON public.comments
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Admin can manage all comments
CREATE POLICY "comments_admin_all" ON public.comments
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- NOTIFICATIONS policies
-- ──────────────────────────────────────────────
-- Users can only read their own notifications
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Users can only update their own notifications (mark as read)
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Only system can insert notifications
CREATE POLICY "notifications_admin_insert" ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admin can manage all notifications
CREATE POLICY "notifications_admin_all" ON public.notifications
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- ──────────────────────────────────────────────
-- STORAGE BUCKETS
-- ──────────────────────────────────────────────
-- Run this to create storage buckets (in Supabase Storage section or SQL)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars',    'avatars',    true,  5242880,   ARRAY['image/jpeg','image/png','image/webp']),
  ('posts',      'posts',      true,  104857600, ARRAY['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']),
  ('thumbnails', 'thumbnails', true,  5242880,   ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: authenticated users can upload to their own folder
CREATE POLICY "avatars_upload_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "posts_upload_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'posts' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "thumbnails_upload_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'thumbnails' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Public read for all storage buckets
CREATE POLICY "storage_public_read" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id IN ('avatars', 'posts', 'thumbnails'));
