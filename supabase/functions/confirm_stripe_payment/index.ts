// ============================================================
// ZUVOXA Edge Function: confirm_stripe_payment
// Called directly from Flutter after presentPaymentSheet() succeeds.
// Verifies the PaymentIntent with Stripe and credits crowns immediately.
// No Webhook required.
// Deploy: supabase functions deploy confirm_stripe_payment
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14?target=deno'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const PACKAGES: Record<string, number> = {
  coffee:  100,
  flowers: 500,
  mic:     1000,
  car:     5000,
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeKey) throw new Error('STRIPE_SECRET_KEY not configured')

    const stripe = new Stripe(stripeKey, {
      apiVersion: '2024-06-20',
      httpClient: Stripe.createFetchHttpClient(),
    })

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // ── Verify user auth ─────────────────────────────────────
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

    // ── Parse request ─────────────────────────────────────────
    const { payment_intent_id } = await req.json()
    if (!payment_intent_id) throw new Error('Missing payment_intent_id')

    // ── Retrieve PaymentIntent from Stripe ───────────────────
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id)

    // Security: ensure this PaymentIntent belongs to this user
    if (paymentIntent.metadata.user_id !== user.id) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Must be succeeded
    if (paymentIntent.status !== 'succeeded') {
      return new Response(JSON.stringify({ error: `Payment not succeeded: ${paymentIntent.status}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── Credit crowns ────────────────────────────────────────
    const { package_id, crowns } = paymentIntent.metadata
    const crownsToAdd = parseInt(crowns) || PACKAGES[package_id] || 0

    if (crownsToAdd <= 0) throw new Error('Invalid package')

    // 1. Claim this PaymentIntent FIRST via the unique index on
    //    stripe_payment_intent_id. If two requests race (retry, double-tap,
    //    webhook firing at the same time as this call), only one INSERT can
    //    win — the loser aborts here instead of both crediting crowns.
    const { error: insertError } = await supabase.from('transactions').insert({
      user_id:                  user.id,
      type:                     'purchase',
      amount:                   crownsToAdd,
      usd_value:                paymentIntent.amount / 100,
      stripe_payment_intent_id: paymentIntent.id,
      reference_id:             package_id,
      created_at:               new Date().toISOString(),
    })

    if (insertError) {
      if (insertError.code === '23505') { // unique_violation — already claimed
        console.log(`PaymentIntent ${paymentIntent.id} already processed.`)
        return new Response(
          JSON.stringify({ success: true, already_processed: true }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      throw insertError
    }

    // 2. Now that this request owns the PaymentIntent, credit the wallet.
    const { error: rpcError } = await supabase.rpc('add_crowns', {
      p_user_id: user.id,
      p_amount:  crownsToAdd,
    })
    if (rpcError) throw rpcError

    // 3. Notify user
    await supabase.from('notifications').insert({
      user_id:    user.id,
      type:       'purchase',
      title:      '✅ تم الشراء بنجاح!',
      body:       `تم إضافة ${crownsToAdd} صوت إلى محفظتك`,
      created_at: new Date().toISOString(),
    })

    console.log(`✅ Confirmed: Added ${crownsToAdd} crowns to user ${user.id}`)

    return new Response(
      JSON.stringify({ success: true, crowns_added: crownsToAdd }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    console.error('confirm_stripe_payment error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
