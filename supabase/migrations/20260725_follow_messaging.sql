-- ══════════════════════════════════════════════════════════════
-- ZUVOXA — Follow & Messaging: Policies Only (idempotent)
-- Run this if the tables already exist but policies need reset
-- ══════════════════════════════════════════════════════════════

-- ── FOLLOWS ────────────────────────────────────────────────────
ALTER TABLE IF EXISTS public.follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "follows_select" ON public.follows;
DROP POLICY IF EXISTS "follows_insert" ON public.follows;
DROP POLICY IF EXISTS "follows_delete" ON public.follows;

CREATE POLICY "follows_select" ON public.follows
  FOR SELECT USING (true);

CREATE POLICY "follows_insert" ON public.follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete" ON public.follows
  FOR DELETE USING (auth.uid() = follower_id);

-- ── CONVERSATIONS ───────────────────────────────────────────────
ALTER TABLE IF EXISTS public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update" ON public.conversations;

CREATE POLICY "conversations_select" ON public.conversations
  FOR SELECT USING (
    auth.uid() = participant_1 OR auth.uid() = participant_2
  );

CREATE POLICY "conversations_insert" ON public.conversations
  FOR INSERT WITH CHECK (
    auth.uid() = participant_1 OR auth.uid() = participant_2
  );

CREATE POLICY "conversations_update" ON public.conversations
  FOR UPDATE USING (
    auth.uid() = participant_1 OR auth.uid() = participant_2
  );

-- ── MESSAGES ────────────────────────────────────────────────────
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;

CREATE POLICY "messages_select" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );

CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );

CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.participant_1 = auth.uid() OR c.participant_2 = auth.uid())
    )
  );
