-- ============================================================
-- Security hardening — found via full app audit (2026-10-06)
-- Apply manually in Supabase SQL Editor (see note on migration
-- history drift from earlier sessions — this file is written to
-- be safe to run standalone / re-run).
-- ============================================================

-- 1. Prevent self-escalation: a user could previously UPDATE any column on
--    their own `users` row, including is_admin, tier, level, points, is_banned.
--    Restrict client self-updates to profile display fields only.
REVOKE UPDATE ON public.users FROM authenticated;
GRANT UPDATE (display_name, avatar_url) ON public.users TO authenticated;

-- 2. The financial RPCs were callable directly by any authenticated client
--    (Postgres grants EXECUTE to PUBLIC by default and nothing ever revoked
--    it), letting anyone drain another user's wallet or mint crowns for
--    themselves. They must only ever be called from our service-role edge
--    functions.
REVOKE EXECUTE ON FUNCTION public.deduct_crowns(uuid, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.add_crowns(uuid, integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.add_creator_earnings(uuid, decimal) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.deduct_crowns(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.add_crowns(uuid, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.add_creator_earnings(uuid, decimal) TO service_role;

-- 3. increment_views(uuid) has no dedup at all and isn't called anywhere in
--    the app (record_view is the real, deduped RPC the client uses) — it was
--    just an open door to inflate any post's view count. Remove client access.
REVOKE EXECUTE ON FUNCTION public.increment_views(uuid) FROM authenticated;

-- 4. notifications.type was missing the purchase/gift values the app (and
--    send_gift/confirm_stripe_payment/stripe_webhook) actually insert, so
--    those notifications silently failed to be created.
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('vote_received','week_winner','level_up','streak','new_follower','purchase','gift_sent','gift_received'));

-- 5. transactions.type was missing 'prize', used by announce_winners for the
--    weekly tournament payouts, so every prize payout left no audit trail.
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_type_check;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_type_check
  CHECK (type IN ('purchase','gift_sent','gift_received','withdrawal','prize'));

-- 6. messages_update let EITHER conversation participant edit ANY message in
--    it, not just their own (no sender_id check, no WITH CHECK).
DROP POLICY IF EXISTS "messages_update" ON public.messages;
CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE USING (auth.uid() = sender_id)
  WITH CHECK (auth.uid() = sender_id);
