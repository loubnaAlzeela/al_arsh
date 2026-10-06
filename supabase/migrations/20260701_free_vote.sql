-- Migration: Update default wallet balance to 1 for the free vote feature

-- 1. Alter the default value for the balance column
ALTER TABLE public.wallets ALTER COLUMN balance SET DEFAULT 1;

-- 2. Give 1 free vote to all existing users who have exactly 0 balance 
--    (so they are not left out of the free vote feature if they registered earlier)
UPDATE public.wallets
SET balance = 1
WHERE balance = 0;
