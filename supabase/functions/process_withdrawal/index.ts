import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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

    // Verify auth (must be admin)
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

    // Check if admin
    const { data: userData } = await supabase
      .from('users')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle()

    if (!userData || !userData.is_admin) {
      return new Response(JSON.stringify({ error: 'Forbidden: Admins only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { request_id, action, admin_note } = body

    if (!request_id || !['approve', 'reject'].includes(action)) {
      throw new Error('Invalid parameters. Need request_id and action (approve/reject)')
    }

    // Get the request
    const { data: request } = await supabase
      .from('withdrawal_requests')
      .select('*')
      .eq('id', request_id)
      .maybeSingle()

    if (!request) throw new Error('Request not found')
    if (request.status !== 'pending') throw new Error('Request is already ' + request.status)

    const target_user_id = request.user_id
    const crowns_amount = request.crowns_amount || 0
    // Never trust the client-supplied amount_usd — derive it from crowns_amount
    // (1000 crowns = $1, matching the app's conversion rate in withdrawal_sheet.dart).
    const amount_usd = crowns_amount / 1000
    const actual_admin_note = admin_note || null;

    if (action === 'reject') {
      const { data: rejected } = await supabase
        .from('withdrawal_requests')
        .update({ status: 'rejected', admin_note: actual_admin_note })
        .eq('id', request_id)
        .eq('status', 'pending')
        .select('id')

      if (!rejected || rejected.length === 0) {
        throw new Error('Request was already processed')
      }

      return new Response(JSON.stringify({ success: true, status: 'rejected' }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // For approve, check if user has enough balance (total_earned - total_withdrawn >= amount_usd)
    const { data: wallet } = await supabase
      .from('wallets')
      .select('total_earned, total_withdrawn, balance')
      .eq('user_id', target_user_id)
      .maybeSingle()

    if (!wallet) throw new Error('Wallet not found')

    const availableToWithdraw = wallet.total_earned - wallet.total_withdrawn
    if (availableToWithdraw < amount_usd) {
      throw new Error('Insufficient earnings to withdraw this amount')
    }

    // Atomically claim the request — only succeeds if it's still pending,
    // which prevents a concurrent/duplicate approve call from double-processing it.
    const { data: approved } = await supabase
      .from('withdrawal_requests')
      .update({ status: 'approved', admin_note: actual_admin_note })
      .eq('id', request_id)
      .eq('status', 'pending')
      .select('id')

    if (!approved || approved.length === 0) {
      throw new Error('Request was already processed')
    }

    // Update wallet
    await supabase
      .from('wallets')
      .update({
        total_withdrawn: wallet.total_withdrawn + amount_usd,
        balance: Math.max(0, wallet.balance - crowns_amount)
      })
      .eq('user_id', target_user_id)

    // Record transaction
    await supabase.from('transactions').insert({
      user_id: target_user_id,
      type: 'withdrawal',
      amount: crowns_amount,
      usd_value: amount_usd,
      reference_id: request_id
    })

    return new Response(
      JSON.stringify({ success: true, withdrawn: amount_usd, status: 'approved' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
