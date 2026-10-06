// ============================================================
// Al Arsh Edge Function: distribute_post
// Triggered via Supabase Database Webhook on posts INSERT
// Supabase CLI: supabase functions deploy distribute_post
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const GUARANTEED_VIEWERS = 500
const BATCH_SIZE = 100  // Insert in batches to avoid payload limits

Deno.serve(async (req) => {
  try {
    const body = await req.json()

    // Webhook payload from Supabase DB trigger
    const record = body.record ?? body
    const postId  = record.id as string
    const userId  = record.user_id as string
    const weekId  = record.week_id as string

    if (!postId || !userId || !weekId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: id, user_id, week_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 1. Get post author's tier
    const { data: author } = await supabase
      .from('users')
      .select('tier')
      .eq('id', userId)
      .maybeSingle()

    if (!author) {
      return new Response(JSON.stringify({ error: 'Post author not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 2. Get random active users from SAME tier (excluding the post author)
    const { data: candidates } = await supabase
      .from('users')
      .select('id')
      .eq('tier', author.tier)
      .eq('is_banned', false)
      .neq('id', userId)
      .limit(GUARANTEED_VIEWERS * 3)  // Get 3x pool for better randomness

    if (!candidates || candidates.length === 0) {
      return new Response(
        JSON.stringify({ success: true, distributed_to: 0, reason: 'No candidates in tier' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 3. Shuffle and pick up to GUARANTEED_VIEWERS
    const shuffled = candidates
      .map(u => ({ id: u.id, sort: Math.random() }))
      .sort((a, b) => a.sort - b.sort)
      .slice(0, GUARANTEED_VIEWERS)
      .map(u => u.id)

    // 4. Batch insert into post_distributions
    let totalInserted = 0
    const now = new Date().toISOString()

    for (let i = 0; i < shuffled.length; i += BATCH_SIZE) {
      const batch = shuffled.slice(i, i + BATCH_SIZE)
      const rows = batch.map(uid => ({
        post_id:  postId,
        user_id:  uid,
        shown_at: now,
      }))

      const { error: insertErr, count } = await supabase
        .from('post_distributions')
        .upsert(rows, { onConflict: 'post_id,user_id', ignoreDuplicates: true, count: 'exact' })

      if (!insertErr && count) totalInserted += count
    }

    return new Response(
      JSON.stringify({
        success: true,
        post_id:        postId,
        tier:           author.tier,
        distributed_to: totalInserted,
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
