-- ─────────────────────────────────────────────────────────────────────────────
-- Live Streams — Al Arsh (Zuvoxa)
-- Only users with tier = 'red' (دوري الملوك) can START a stream.
-- All authenticated users can VIEW streams and send messages.
-- ─────────────────────────────────────────────────────────────────────────────

-- Live Streams table
create table if not exists public.live_streams (
  id              uuid primary key default gen_random_uuid(),
  host_user_id    uuid not null references public.users(id) on delete cascade,
  title           text not null default 'بث مباشر',
  is_live         boolean not null default true,
  viewer_count    int not null default 0,
  peak_viewers    int not null default 0,
  created_at      timestamptz not null default now(),
  ended_at        timestamptz
);

-- Live Messages (chat) table
create table if not exists public.live_messages (
  id            uuid primary key default gen_random_uuid(),
  stream_id     uuid not null references public.live_streams(id) on delete cascade,
  user_id       uuid not null references public.users(id) on delete cascade,
  display_name  text not null,
  avatar_url    text,
  content       text not null,
  created_at    timestamptz not null default now()
);

-- Indexes
create index if not exists idx_live_streams_is_live on public.live_streams(is_live);
create index if not exists idx_live_streams_host on public.live_streams(host_user_id);
create index if not exists idx_live_messages_stream on public.live_messages(stream_id, created_at desc);

-- RLS
alter table public.live_streams enable row level security;
alter table public.live_messages enable row level security;

-- Policies: live_streams
-- Everyone can read live streams
create policy "Anyone can view live streams"
  on public.live_streams for select
  using (true);

-- Only red-tier users can insert a stream
create policy "Red tier users can start streams"
  on public.live_streams for insert
  with check (
    exists (
      select 1 from public.users u
      where u.id = auth.uid() and u.tier = 'red'
    )
  );

-- Only the host can update their stream
create policy "Host can update own stream"
  on public.live_streams for update
  using (host_user_id = auth.uid());

-- Policies: live_messages
create policy "Anyone can view messages"
  on public.live_messages for select
  using (true);

create policy "Authenticated users can send messages"
  on public.live_messages for insert
  with check (auth.uid() = user_id);

-- Realtime
alter publication supabase_realtime add table public.live_streams;
alter publication supabase_realtime add table public.live_messages;
