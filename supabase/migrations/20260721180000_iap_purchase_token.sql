-- ============================================================
-- ZUVOXA — Google Play IAP purchase token tracking
-- Mirrors the Stripe payment-intent dedupe column (20260630_stripe_payments.sql)
-- so verify_purchase can never credit the same Play Billing purchase twice.
-- ============================================================

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS store_purchase_token text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_store_purchase_token
  ON public.transactions(store_purchase_token)
  WHERE store_purchase_token IS NOT NULL;
