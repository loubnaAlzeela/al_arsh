// ============================================================
// ZUVOXA Edge Function: verify_purchase
// Verifies a Google Play in-app purchase receipt server-side via the
// Android Publisher API, then credits crowns exactly once per purchase.
// Deploy: supabase functions deploy verify_purchase
//
// Required secrets:
//   GOOGLE_SERVICE_ACCOUNT_EMAIL   — service account with access to the
//                                    Play Console (Account Users) and the
//                                    "Android Publisher API" enabled
//   GOOGLE_SERVICE_ACCOUNT_KEY     — the service account's PEM private key
//                                    (the "private_key" field from its
//                                    downloaded JSON key file)
//   ANDROID_PACKAGE_NAME           — e.g. com.zuvoxa.app (optional,
//                                    defaults to com.zuvoxa.app)
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Must match GiftPackage.productId / crownsCost / usdPrice in lib/features/gifts/data/gift_package.dart
const PACKAGE_CROWNS: Record<string, number> = {
  iap_coffee: 100,
  iap_flowers: 500,
  iap_mic: 1000,
  iap_car: 5000,
}

const PACKAGE_USD: Record<string, number> = {
  iap_coffee: 0.99,
  iap_flowers: 4.99,
  iap_mic: 9.99,
  iap_car: 49.99,
}

async function getGoogleAccessToken(): Promise<string> {
  const clientEmail = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_EMAIL')
  const privateKeyPem = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_KEY')
  if (!clientEmail || !privateKeyPem) {
    throw new Error('Google service account not configured')
  }

  const privateKey = await importPKCS8(
    privateKeyPem.replace(/\\n/g, '\n'),
    'RS256',
  )

  const now = Math.floor(Date.now() / 1000)
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/androidpublisher',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(clientEmail)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey)

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  })

  if (!tokenRes.ok) {
    throw new Error(`Google token exchange failed: ${await tokenRes.text()}`)
  }

  const { access_token } = await tokenRes.json()
  return access_token
}

/// Verifies a consumable purchase token against the Android Publisher API.
/// Returns true only if the purchase is in the "purchased" state (0).
async function verifyWithGooglePlay(
  productId: string,
  purchaseToken: string,
): Promise<boolean> {
  const packageName = Deno.env.get('ANDROID_PACKAGE_NAME') || 'com.zuvoxa.app'
  const accessToken = await getGoogleAccessToken()

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })

  if (!res.ok) {
    console.error('Android Publisher API error:', await res.text())
    return false
  }

  const data = await res.json()
  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
  return data.purchaseState === 0
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
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

    const { product_id, receipt_data, source } = await req.json()

    const crownsToAdd = PACKAGE_CROWNS[product_id]
    const usdValue = PACKAGE_USD[product_id]
    if (!crownsToAdd) throw new Error('Invalid product_id')

    if (source !== 'google_play') {
      throw new Error(`Unsupported purchase source: ${source}`)
    }
    if (!receipt_data) throw new Error('Missing receipt_data')

    // ── Idempotency: never credit the same purchase token twice ──
    const { data: existingTx } = await supabase
      .from('transactions')
      .select('id')
      .eq('store_purchase_token', receipt_data)
      .maybeSingle()

    if (existingTx) {
      return new Response(
        JSON.stringify({ success: true, crowns_added: 0, note: 'Already processed' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Verify the receipt with Google before crediting anything ──
    const valid = await verifyWithGooglePlay(product_id, receipt_data)
    if (!valid) {
      return new Response(JSON.stringify({ error: 'Purchase could not be verified' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. Claim the purchase token FIRST via the unique index on
    //    store_purchase_token. If two requests for the same receipt race
    //    each other, only one INSERT can win — the loser aborts here
    //    instead of both going on to credit crowns twice.
    const { error: insertError } = await supabase.from('transactions').insert({
      user_id: user.id,
      type: 'purchase',
      amount: crownsToAdd,
      usd_value: usdValue,
      reference_id: null,
      store_purchase_token: receipt_data,
    })
    if (insertError) {
      if (insertError.code === '23505') { // unique_violation — already claimed
        return new Response(
          JSON.stringify({ success: true, crowns_added: 0, note: 'Already processed' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      throw insertError
    }

    // 2. Now that this request owns the purchase token, credit the wallet.
    const { error: rpcError } = await supabase.rpc('add_crowns', {
      p_user_id: user.id,
      p_amount: crownsToAdd,
    })
    if (rpcError) throw rpcError

    return new Response(
      JSON.stringify({ success: true, crowns_added: crownsToAdd }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error: any) {
    console.error('verify_purchase error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
