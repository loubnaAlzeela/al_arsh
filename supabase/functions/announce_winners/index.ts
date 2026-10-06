// ============================================================
// Al Arsh Edge Function: announce_winners
// Run manually or via Saturday cron
// Supabase CLI: supabase functions deploy announce_winners
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const LEVEL_PROMOTION: Record<string, string> = {
  'مجهول': 'موهبة',
  'موهبة': 'صاعد',
  'صاعد':  'نجم',
  'نجم':   'ملك',
  'ملك':   'أسطورة',
}

const TIER_MAP: Record<string, string> = {
  'مجهول':  'blue',
  'موهبة':  'blue',
  'صاعد':   'gold',
  'نجم':    'gold',
  'ملك':    'red',
  'أسطورة': 'red',
}

/// كراونز الجائزة لكل دوري
const TIER_PRIZE_CROWNS: Record<string, number> = {
  'blue': 150,
  'gold': 300,
  'red':  500,
}

async function findTopUser(weekId: string, tier: string): Promise<string | null> {
  const { data } = await supabase
    .from('users')
    .select('id, weekly_competition_points')
    .eq('tier', tier)
    .eq('is_banned', false)
    .gt('weekly_competition_points', 0)
    .order('weekly_competition_points', { ascending: false })
    .limit(1)
    .maybeSingle()

  return data?.id ?? null
}

async function sendNotification(userId: string, type: string, title: string, body: string) {
  await supabase.from('notifications').insert({
    user_id:    userId,
    type,
    title,
    body,
    created_at: new Date().toISOString(),
  })
}

/// منح كراونز جائزة للفائز وتسجيل المعاملة
async function grantPrizeCrowns(userId: string, tier: string, weekNumber: number) {
  const crowns = TIER_PRIZE_CROWNS[tier] ?? 0
  if (crowns <= 0) return

  // 1. جلب أو إنشاء المحفظة
  const { data: wallet } = await supabase
    .from('wallets')
    .select('id, balance, total_earned')
    .eq('user_id', userId)
    .maybeSingle()

  if (wallet) {
    // تحديث المحفظة الموجودة
    await supabase
      .from('wallets')
      .update({
        balance:      wallet.balance + crowns,
        total_earned: (wallet.total_earned ?? 0) + crowns,
      })
      .eq('id', wallet.id)
  } else {
    // إنشاء محفظة جديدة
    await supabase.from('wallets').insert({
      user_id:       userId,
      balance:       crowns,
      total_earned:  crowns,
      total_withdrawn: 0,
    })
  }

  // 2. تسجيل المعاملة
  await supabase.from('transactions').insert({
    user_id:  userId,
    type:     'prize',
    amount:   crowns,
    reference_id: `week_${weekNumber}_${tier}`,
    created_at: new Date().toISOString(),
  })
}

async function promoteLevelIfQualified(userId: string, wonInTier: string) {
  const { data: user } = await supabase
    .from('users')
    .select('level, red_tier_wins')
    .eq('id', userId)
    .maybeSingle()

  if (!user) return

  let newLevel = user.level
  let newRedTierWins = user.red_tier_wins ?? 0

  if (wonInTier === 'blue' && user.level === 'مجهول') newLevel = 'موهبة'
  else if (wonInTier === 'blue' && user.level === 'موهبة') newLevel = 'صاعد'
  else if (wonInTier === 'gold' && user.level === 'صاعد') newLevel = 'نجم'
  else if (wonInTier === 'red' && user.level === 'نجم') newLevel = 'ملك'
  else if (wonInTier === 'red' && user.level === 'ملك') {
    newRedTierWins++
    if (newRedTierWins >= 3) newLevel = 'أسطورة'
  }

  const newTier = TIER_MAP[newLevel] ?? user.level

  if (newLevel !== user.level) {
    await supabase.from('users')
      .update({ level: newLevel, tier: newTier, red_tier_wins: newRedTierWins })
      .eq('id', userId)

    await sendNotification(
      userId,
      'level_up',
      'ترقية المستوى! ⬆️',
      `تهانينا! وصلت إلى مستوى ${newLevel}`
    )
  }
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

    // 1. Get current active or voting_closed week
    const { data: week } = await supabase
      .from('weeks')
      .select('id, week_number')
      .in('status', ['active', 'voting_closed'])
      .order('week_number', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (!week) {
      return new Response(JSON.stringify({ error: 'No active week to announce' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 2. Find top user per tier
    const [blueWinnerId, goldWinnerId, redWinnerId] = await Promise.all([
      findTopUser(week.id, 'blue'),
      findTopUser(week.id, 'gold'),
      findTopUser(week.id, 'red'),
    ])

    // 3. Update week record
    await supabase
      .from('weeks')
      .update({
        status:          'announced',
        blue_winner_id:  blueWinnerId,
        gold_winner_id:  goldWinnerId,
        red_winner_id:   redWinnerId,
      })
      .eq('id', week.id)

    // 4. Send winner notifications + level up promotions
    const winners = [
      { id: blueWinnerId, tier: 'blue', label: 'دوري الصاعدين' },
      { id: goldWinnerId, tier: 'gold', label: 'دوري النخبة' },
      { id: redWinnerId,  tier: 'red',  label: 'دوري الملوك' },
    ]

    for (const { id: winnerId, tier, label } of winners) {
      if (!winnerId) continue

      const prizeAmount = TIER_PRIZE_CROWNS[tier] ?? 0

      // إرسال إشعار يتضمن عدد الكراونز
      await sendNotification(
        winnerId,
        'week_winner',
        `🏆 أنت بطل الأسبوع ${week.week_number}!`,
        `فزت في ${label} — حصلت على ${prizeAmount} كراون وترقية المستوى!`
      )

      // منح الكراونز
      await grantPrizeCrowns(winnerId, tier, week.week_number)

      // ترقية المستوى
      await promoteLevelIfQualified(winnerId, tier)
    }

    // 5. Reset weekly points for all users
    await supabase
      .from('users')
      .update({ weekly_competition_points: 0 })
      .gt('weekly_competition_points', 0)

    // 6. Create next week
    const nextWeekNumber = week.week_number + 1
    const startDate = new Date()
    const endDate   = new Date(startDate.getTime() + 6 * 24 * 60 * 60 * 1000)
    const votingClose   = new Date(endDate.getTime() - 24 * 60 * 60 * 1000)
    const announcement  = new Date(endDate.getTime() - 4 * 60 * 60 * 1000)

    await supabase.from('weeks').insert({
      week_number:      nextWeekNumber,
      start_date:       startDate.toISOString(),
      end_date:         endDate.toISOString(),
      voting_closes_at: votingClose.toISOString(),
      announcement_at:  announcement.toISOString(),
      status:           'active',
    })

    return new Response(
      JSON.stringify({
        success: true,
        week_number:    week.week_number,
        blue_winner_id: blueWinnerId,
        gold_winner_id: goldWinnerId,
        red_winner_id:  redWinnerId,
        next_week:      nextWeekNumber,
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
