-- 1. User Wallets
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  balance INTEGER DEFAULT 0,        -- رصيد التاج
  total_earned DECIMAL DEFAULT 0,   -- إجمالي ما كسبه كصانع
  total_withdrawn DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Users can read their own wallet
CREATE POLICY "Users can read own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

-- 2. Transactions
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  type TEXT CHECK (type IN ('purchase','gift_sent','gift_received','withdrawal')) NOT NULL,
  amount INTEGER,                   -- بالتاج
  usd_value DECIMAL,               -- بالدولار
  reference_id UUID,               -- ID الهدية أو السحب
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Users can read their own transactions
CREATE POLICY "Users can read own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

-- 3. Gifts
CREATE TABLE gifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  receiver_id UUID REFERENCES auth.users(id) NOT NULL,
  post_id UUID REFERENCES posts(id) NOT NULL,
  gift_type TEXT CHECK (gift_type IN ('spark','crown','flame','bolt')) NOT NULL,
  crowns_spent INTEGER NOT NULL,            -- كم تاج أُنفق
  votes_added INTEGER NOT NULL,             -- كم صوت أضافت
  week_number INTEGER NOT NULL,             -- رقم الأسبوع
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;

-- Gifts are public for transparency
CREATE POLICY "Gifts are public" ON gifts
  FOR SELECT USING (true);

-- 4. Weekly Vote Aggregation
CREATE TABLE weekly_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES posts(id) NOT NULL,
  week_number INTEGER NOT NULL,
  free_votes INTEGER DEFAULT 0,
  paid_votes INTEGER DEFAULT 0,
  total_score DECIMAL GENERATED ALWAYS AS
    (free_votes * 0.70 + paid_votes * 0.30) STORED,
  UNIQUE(post_id, week_number)
);

-- Enable RLS
ALTER TABLE weekly_votes ENABLE ROW LEVEL SECURITY;

-- Weekly votes are public
CREATE POLICY "Weekly votes are public" ON weekly_votes
  FOR SELECT USING (true);

-- Trigger to automatically create a wallet for new users
CREATE OR REPLACE FUNCTION public.handle_new_user_wallet() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id)
  VALUES (new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_wallet
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_wallet();

-- Backfill wallets for existing users
INSERT INTO public.wallets (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.wallets);

-- RPC for safe balance deduction
CREATE OR REPLACE FUNCTION deduct_crowns(p_user_id UUID, p_amount INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE public.wallets
  SET balance = balance - p_amount
  WHERE user_id = p_user_id AND balance >= p_amount;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient balance or user not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC for safe balance addition
CREATE OR REPLACE FUNCTION add_crowns(p_user_id UUID, p_amount INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE public.wallets
  SET balance = balance + p_amount
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC for safe creator earnings addition
CREATE OR REPLACE FUNCTION add_creator_earnings(p_user_id UUID, p_usd_amount DECIMAL)
RETURNS void AS $$
BEGIN
  UPDATE public.wallets
  SET total_earned = total_earned + p_usd_amount
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

