// ============================================================
// Al Arsh Edge Function: calculate_scores
// Runs every hour via Supabase Cron
// Supabase CLI: supabase functions deploy calculate_scores
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const TIER_MULTIPLIER: Record<string, number> = {
  'مجهول':  3.0,
  'موهبة':  3.0,
  'صاعد':   1.5,
  'نجم':    1.5,
  'ملك':    1.0,
  'أسطورة': 1.0,
}

function calculateScore(
  views: number,
  likes: number,
  comments: number,
  shares: number,
  level: string
): number {
  const multiplier = TIER_MULTIPLIER[level] ?? 3.0
  const engagementRate = (likes + comments * 2 + shares * 3) / Math.max(views, 1)
  return Math.round(engagementRate * multiplier * 1000 * 10000) / 10000
}

async function isAuthorized(req: Request): Promise<boolean> {
  // Allow the scheduled cron job via a shared secret header
  const cronSecret = req.headers.get('x-cron-secret')
  if (cronSecret && cronSecret === Deno.env.get('CRON_SECRET')) return true

  // Otherwise require a logged-in admin user
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return false
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) return false

  const { data: userData } = await supabase
    .from('users')
    .select('is_admin')
    .eq('id', user.id)
    .maybeSingle()

  return !!userData?.is_admin
}

Deno.serve(async (req) => {
  try {
    if (!(await isAuthorized(req))) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 1. Get active week
    const { data: week, error: weekErr } = await supabase
      .from('weeks')
      .select('id, week_number')
      .in('status', ['active', 'voting_closed'])
      .order('week_number', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (weekErr || !week) {
      return new Response(JSON.stringify({ error: 'No active week found' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 2. Get all active posts with user level
    const { data: posts, error: postsErr } = await supabase
      .from('posts')
      .select('id, user_id, raw_views, raw_likes, raw_comments, raw_shares, users!inner(level)')
      .eq('week_id', week.id)
      .eq('is_active', true)

    if (postsErr) throw postsErr

    let processedCount = 0
    const userScoreMap: Record<string, number> = {}

    // 3. Calculate and update score per post
    for (const post of posts ?? []) {
      const level = (post.users as any).level as string
      const score = calculateScore(
        post.raw_views,
        post.raw_likes,
        post.raw_comments,
        post.raw_shares,
        level
      )

      const { error: updateErr } = await supabase
        .from('posts')
        .update({ normalized_score: score })
        .eq('id', post.id)

      if (!updateErr) {
        processedCount++
        // Accumulate scores per user
        userScoreMap[post.user_id] = (userScoreMap[post.user_id] ?? 0) + score
      }
    }

    // 4. Update weekly_competition_points per user
    for (const [userId, totalScore] of Object.entries(userScoreMap)) {
      await supabase
        .from('users')
        .update({ weekly_competition_points: Math.round(totalScore) })
        .eq('id', userId)
    }

    // 5. Sync free votes to weekly_votes
    const { data: votesData } = await supabase
      .from('votes')
      .select('post_id')
      .eq('week_id', week.id)

    const freeVotesMap: Record<string, number> = {}
    if (votesData) {
      for (const v of votesData) {
        freeVotesMap[v.post_id] = (freeVotesMap[v.post_id] || 0) + 1
      }
    }

    for (const post of posts ?? []) {
      const freeVotesCount = freeVotesMap[post.id] || 0
      
      const { data: wv } = await supabase.from('weekly_votes')
        .select('id')
        .eq('post_id', post.id)
        .eq('week_number', week.week_number)
        .maybeSingle()
        
      if (wv) {
        await supabase.from('weekly_votes')
          .update({ free_votes: freeVotesCount })
          .eq('id', wv.id)
      } else {
        await supabase.from('weekly_votes')
          .insert({
            post_id: post.id,
            week_number: week.week_number,
            free_votes: freeVotesCount,
            paid_votes: 0
          })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        week_id: week.id,
        posts_processed: processedCount,
        users_updated: Object.keys(userScoreMap).length,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
