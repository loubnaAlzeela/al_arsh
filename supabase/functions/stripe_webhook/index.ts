// ============================================================
// ZUVOXA Edge Function: stripe_webhook
// Handles Stripe payment events and credits crowns to wallet
// Deploy: supabase functions deploy stripe_webhook
// Add this URL in Stripe Dashboard → Developers → Webhooks:
//   https://<project-ref>.supabase.co/functions/v1/stripe_webhook
//   Events: payment_intent.succeeded
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14?target=deno'

const PACKAGES: Record<string, number> = {
  coffee: 100,
  flowers: 500,
  mic: 1000,
  car: 5000,
}

Deno.serve(async (req) => {
  const stripeKey     = Deno.env.get('STRIPE_SECRET_KEY')!
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

  if (!stripeKey || !webhookSecret) {
    return new Response('Stripe not configured', { status: 500 })
  }

  const stripe = new Stripe(stripeKey, {
    apiVersion: '2024-06-20',
    httpClient: Stripe.createFetchHttpClient(),
  })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // ── Verify Stripe signature ───────────────────────────────
  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response('Missing stripe-signature', { status: 400 })
  }

  const body = await req.text()
  let event: Stripe.Event

  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret)
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  // ── Handle payment_intent.succeeded ──────────────────────
  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object as Stripe.PaymentIntent
    const { user_id, package_id, crowns } = paymentIntent.metadata

    if (!user_id || !package_id) {
      console.error('Missing metadata in PaymentIntent')
      return new Response('Missing metadata', { status: 400 })
    }

    const crownsToAdd = parseInt(crowns) || PACKAGES[package_id] || 0

    try {
      // 0. Claim this PaymentIntent FIRST via the unique index on
      //    stripe_payment_intent_id — if the webhook redelivers or races
      //    confirm_stripe_payment, only one INSERT wins, so crowns are
      //    never credited twice for the same payment.
      const { error: insertError } = await supabase.from('transactions').insert({
        user_id:                   user_id,
        type:                      'purchase',
        amount:                    crownsToAdd,
        usd_value:                 paymentIntent.amount / 100,
        stripe_payment_intent_id:  paymentIntent.id,
        reference_id:              package_id,
        created_at:                new Date().toISOString(),
      })

      if (insertError) {
        if (insertError.code === '23505') { // unique_violation — already claimed
          console.log(`PaymentIntent ${paymentIntent.id} already processed. Skipping.`)
          return new Response(JSON.stringify({ received: true, note: 'Already processed' }), {
            headers: { 'Content-Type': 'application/json' },
          })
        }
        throw insertError
      }

      // 1. Add crowns via RPC (atomic operation)
      const { error: rpcError } = await supabase.rpc('add_crowns', {
        p_user_id: user_id,
        p_amount:  crownsToAdd,
      })
      if (rpcError) throw rpcError

      // 3. Send in-app notification
      await supabase.from('notifications').insert({
        user_id,
        type:       'purchase',
        title:      '✅ تم الشراء بنجاح!',
        body:       `تم إضافة ${crownsToAdd} تاج إلى محفظتك`,
        created_at: new Date().toISOString(),
      })

      console.log(`✅ Added ${crownsToAdd} crowns to user ${user_id}`)

    } catch (err: any) {
      console.error('Failed to credit crowns:', err.message)
      return new Response(`Failed: ${err.message}`, { status: 500 })
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
