-- ============================================================
-- ZUVOXA — Stripe Payments Migration
-- ============================================================

-- Add Stripe payment intent ID to transactions
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id text,
  ADD COLUMN IF NOT EXISTS usd_value numeric(10,2);

-- Unique Index to prevent duplicate processing of the same payment intent
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_stripe_pi
  ON public.transactions(stripe_payment_intent_id)
  WHERE stripe_payment_intent_id IS NOT NULL;

-- add_crowns RPC — atomically updates or creates wallet
CREATE OR REPLACE FUNCTION public.add_crowns(p_user_id uuid, p_amount int)
RETURNS void AS $$
BEGIN
  INSERT INTO public.wallets (user_id, balance, total_earned, total_withdrawn)
  VALUES (p_user_id, p_amount, p_amount, 0)
  ON CONFLICT (user_id) DO UPDATE
    SET balance      = wallets.balance + p_amount,
        total_earned = wallets.total_earned + p_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.add_crowns(uuid, int) TO service_role;
