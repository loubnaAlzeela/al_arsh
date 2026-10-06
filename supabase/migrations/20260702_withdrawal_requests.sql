-- Migration: Create withdrawal_requests table

CREATE TABLE IF NOT EXISTS public.withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount_usd DECIMAL(10, 2) NOT NULL CHECK (amount_usd > 0),
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending' NOT NULL,
  payment_details TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add new columns safely
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='withdrawal_requests' AND column_name='crowns_amount') THEN
        ALTER TABLE public.withdrawal_requests ADD COLUMN crowns_amount INTEGER NOT NULL DEFAULT 5000 CHECK (crowns_amount >= 5000);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='withdrawal_requests' AND column_name='payment_method') THEN
        ALTER TABLE public.withdrawal_requests ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'bank';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='withdrawal_requests' AND column_name='admin_note') THEN
        ALTER TABLE public.withdrawal_requests ADD COLUMN admin_note TEXT;
    END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON public.withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status  ON public.withdrawal_requests(status);

-- Enable RLS
ALTER TABLE public.withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid errors when re-running
DROP POLICY IF EXISTS "Users can insert own requests" ON public.withdrawal_requests;
DROP POLICY IF EXISTS "Users can read own requests" ON public.withdrawal_requests;
DROP POLICY IF EXISTS "Admins can view all withdrawal requests" ON public.withdrawal_requests;
DROP POLICY IF EXISTS "Admins can update withdrawal requests" ON public.withdrawal_requests;

-- Users can insert their own requests
CREATE POLICY "Users can insert own requests" ON public.withdrawal_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can read their own requests
CREATE POLICY "Users can read own requests" ON public.withdrawal_requests
  FOR SELECT USING (auth.uid() = user_id);

-- Admins can view all requests
CREATE POLICY "Admins can view all withdrawal requests" ON public.withdrawal_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- Admins can update requests
CREATE POLICY "Admins can update withdrawal requests" ON public.withdrawal_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  );

-- Trigger for updated_at using a simple custom function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.withdrawal_requests;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.withdrawal_requests
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
