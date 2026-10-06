// ============================================================
// ZUVOXA Edge Function: create_payment_intent
// Creates a Stripe PaymentIntent for buying crowns
// Deploy: supabase functions deploy create_payment_intent
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14?target=deno'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const PACKAGES: Record<string, { crowns: number; amount_cents: number; name: string }> = {
  coffee:  { crowns: 100,  amount_cents: 99,   name: 'فنجان قهوة ☕' },
  flowers: { crowns: 500,  amount_cents: 499,  name: 'باقة زهور 💐' },
  mic:     { crowns: 1000, amount_cents: 999,  name: 'ميكروفون ذهبي 🎤' },
  car:     { crowns: 5000, amount_cents: 4999, name: 'سيارة فاخرة 🏎️' },
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

    // ── Verify user auth ──────────────────────────────────────
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

    // ── Validate package ──────────────────────────────────────
    const { package_id } = await req.json()
    const pkg = PACKAGES[package_id]
    if (!pkg) throw new Error(`Invalid package_id: ${package_id}`)

    // ── Create PaymentIntent ──────────────────────────────────
    const paymentIntent = await stripe.paymentIntents.create({
      amount:   pkg.amount_cents,
      currency: 'usd',
      metadata: {
        user_id:    user.id,
        package_id: package_id,
        crowns:     String(pkg.crowns),
      },
      description: `ZUVOXA — ${pkg.name}`,
      automatic_payment_methods: { enabled: true },
    })

    return new Response(
      JSON.stringify({
        client_secret: paymentIntent.client_secret,
        amount:        pkg.amount_cents,
        crowns:        pkg.crowns,
        package_id:    package_id,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    console.error('create_payment_intent error:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
