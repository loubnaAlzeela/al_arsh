-- Migration: Fix withdrawal_requests foreign key to reference public.users
-- Problem: withdrawal_requests.user_id referenced auth.users(id) instead of public.users(id)
-- This caused PostgREST to fail joining withdrawal_requests with public.users

-- Step 1: Drop the existing foreign key constraint that points to auth.users
ALTER TABLE public.withdrawal_requests
  DROP CONSTRAINT IF EXISTS withdrawal_requests_user_id_fkey;

-- Step 2: Add the correct foreign key pointing to public.users(id)
ALTER TABLE public.withdrawal_requests
  ADD CONSTRAINT withdrawal_requests_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
