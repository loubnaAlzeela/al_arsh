import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const GIFT_RATES: Record<string, { crowns: number, votes: number }> = {
  'coffee': { crowns: 100, votes: 3 },
  'flowers': { crowns: 500, votes: 15 },
  'mic': { crowns: 1000, votes: 30 },
  'car': { crowns: 5000, votes: 150 }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Verify auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { post_id, gift_type } = await req.json()
    const sender_id = user.id

    const giftInfo = GIFT_RATES[gift_type]
    if (!giftInfo) throw new Error('Invalid gift type')

    // 1. Get post details
    const { data: post, error: postErr } = await supabase
      .from('posts')
      .select('user_id, week_id')
      .eq('id', post_id)
      .maybeSingle()

    if (postErr || !post) throw new Error('Post not found')
    const receiver_id = post.user_id

    // 2. Get active week (validate it's same as post's week and active)
    const { data: week, error: weekErr } = await supabase
      .from('weeks')
      .select('id, week_number')
      .eq('id', post.week_id)
      .in('status', ['active', 'voting_closed']) // allow gifts even if voting closed? Let's say only active.
      .maybeSingle()

    if (weekErr || !week) throw new Error('Week not active or not found')

    // 3. Deduct Crowns (RPC will throw if insufficient balance)
    const { error: deductErr } = await supabase.rpc('deduct_crowns', { 
      p_user_id: sender_id, 
      p_amount: giftInfo.crowns 
    })
    
    if (deductErr) {
      return new Response(JSON.stringify({ error: 'Insufficient balance' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Calculate USD value (e.g. $0.01 per Vote)
    const usdValue = giftInfo.crowns * 0.01

    // 5. Credit creator
    await supabase.rpc('add_creator_earnings', {
      p_user_id: receiver_id,
      p_usd_amount: usdValue
    })

    // 6. Record transactions
    await supabase.from('transactions').insert([
      {
        user_id: sender_id,
        type: 'gift_sent',
        amount: -giftInfo.crowns,
        reference_id: post_id
      },
      {
        user_id: receiver_id,
        type: 'gift_received',
        amount: giftInfo.crowns,
        usd_value: usdValue,
        reference_id: post_id
      }
    ])

    // 7. Check weekly cap for paid votes
    const { data: weeklyVotes } = await supabase
      .from('weekly_votes')
      .select('paid_votes')
      .eq('post_id', post_id)
      .eq('week_number', week.week_number)
      .maybeSingle()

    let currentPaidVotes = weeklyVotes ? weeklyVotes.paid_votes : 0
    let votesToAdd = giftInfo.votes
    if (currentPaidVotes + votesToAdd > 100) {
       votesToAdd = Math.max(0, 100 - currentPaidVotes)
    }

    // 8. Insert into gifts
    const { data: giftRecord, error: giftErr } = await supabase.from('gifts').insert({
      sender_id,
      receiver_id,
      post_id,
      gift_type,
      crowns_spent: giftInfo.crowns,
      votes_added: votesToAdd,
      week_number: week.week_number
    }).select().single()

    if (giftErr) {
      // Refund the crowns since the gift was never actually recorded
      await supabase.rpc('add_crowns', { p_user_id: sender_id, p_amount: giftInfo.crowns })
      throw new Error('Failed to record gift: ' + giftErr.message)
    }

    // 9. Upsert weekly_votes
    if (weeklyVotes) {
      await supabase.from('weekly_votes')
        .update({ paid_votes: currentPaidVotes + votesToAdd })
        .eq('post_id', post_id)
        .eq('week_number', week.week_number)
    } else {
      await supabase.from('weekly_votes').insert({
        post_id: post_id,
        week_number: week.week_number,
        paid_votes: votesToAdd,
        free_votes: 0
      })
    }

    // 10. Send notification to creator
    await supabase.from('notifications').insert({
      user_id: receiver_id,
      type: 'gift_received',
      title: 'هدية جديدة! 🎁',
      body: `تلقيت هدية ${gift_type} من أحد الداعمين!`,
      related_id: post_id
    })

    return new Response(
      JSON.stringify({ success: true, gift: giftRecord }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
