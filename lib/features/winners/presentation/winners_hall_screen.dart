import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';
import '../../../shared/widgets/level_badge_widget.dart';
import '../../auth/data/user_model.dart';

part 'winners_hall_screen.g.dart';

// ── Winners data model ─────────────────────────────────────────────────────
class WeekWinner {
  final String weekId;
  final int weekNumber;
  final DateTime startDate;
  final DateTime announcementAt;
  final UserModel? blueWinner;
  final UserModel? goldWinner;
  final UserModel? redWinner;

  const WeekWinner({
    required this.weekId,
    required this.weekNumber,
    required this.startDate,
    required this.announcementAt,
    this.blueWinner,
    this.goldWinner,
    this.redWinner,
  });
}

// ── Provider ───────────────────────────────────────────────────────────────
@riverpod
Future<List<WeekWinner>> pastWinners(Ref ref) async {
  final weeks = await supabase
      .from('weeks')
      .select()
      .eq('status', 'announced')
      .order('week_number', ascending: false)
      .limit(20);

  final results = <WeekWinner>[];
  for (final week in weeks as List) {
    Future<UserModel?> fetchUser(String? id) async {
      if (id == null) return null;
      final data = await supabase.from('users').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    }

    final futures = await Future.wait([
      fetchUser(week['blue_winner_id']),
      fetchUser(week['gold_winner_id']),
      fetchUser(week['red_winner_id']),
    ]);

    results.add(WeekWinner(
      weekId:         week['id'],
      weekNumber:     week['week_number'],
      startDate:      DateTime.parse(week['start_date']),
      announcementAt: DateTime.parse(week['announcement_at']),
      blueWinner:     futures[0],
      goldWinner:     futures[1],
      redWinner:      futures[2],
    ));
  }
  return results;
}

// ── Screen ─────────────────────────────────────────────────────────────────
class WinnersHallScreen extends ConsumerWidget {
  const WinnersHallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winnersAsync = ref.watch(pastWinnersProvider);
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.winnersHall),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.emoji_events, color: AppColors.primary),
          ),
        ],
      ),
      body: winnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (weeks) => weeks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        size: 72, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(s.noWinnersYet,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: weeks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) => _WeekCard(winner: weeks[i]),
              ),
      ),
    );
  }
}

// ── Week Card ──────────────────────────────────────────────────────────────
class _WeekCard extends ConsumerWidget {
  final WeekWinner winner;
  const _WeekCard({required this.winner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    final dateStr = DateFormat('d MMM yyyy', 'ar').format(winner.announcementAt);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Week header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${s.week} ${winner.weekNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Winners row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (winner.blueWinner != null)
                  Expanded(
                    child: _WinnerTile(user: winner.blueWinner!, tier: 'blue'),
                  ),
                if (winner.blueWinner != null && winner.goldWinner != null)
                  const SizedBox(width: 8),
                if (winner.goldWinner != null)
                  Expanded(
                    child: _WinnerTile(user: winner.goldWinner!, tier: 'gold'),
                  ),
                if (winner.goldWinner != null && winner.redWinner != null)
                  const SizedBox(width: 8),
                if (winner.redWinner != null)
                  Expanded(
                    child: _WinnerTile(user: winner.redWinner!, tier: 'red'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Winner Tile ────────────────────────────────────────────────────────────
class _WinnerTile extends ConsumerWidget {
  final UserModel user;
  final String tier;
  const _WinnerTile({required this.user, required this.tier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    final tierColor = AppColors.getTierColor(tier);
    final tierLabel = tier == 'blue'
        ? s.tierBlueLabel
        : tier == 'gold'
            ? s.tierGoldLabel
            : s.tierRedLabel;

    return GestureDetector(
      onTap: () => context.push('/profile/${user.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Crown icon
            Icon(Icons.emoji_events, color: tierColor, size: 18),
            const SizedBox(height: 6),
            // Avatar
            TierAvatarWidget(
              avatarUrl: user.avatarUrl,
              tier: tier,
              radius: 24,
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Level badge
            LevelBadgeWidget(level: user.level, fontSize: 9),
            const SizedBox(height: 4),
            // Tier label
            Text(
              tierLabel,
              style: TextStyle(
                color: tierColor,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
