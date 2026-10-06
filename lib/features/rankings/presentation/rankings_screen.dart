import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';
import '../../../shared/providers/current_week_provider.dart';
import '../../../shared/widgets/countdown_timer_widget.dart';
import '../../../shared/widgets/level_badge_widget.dart';
import '../../feed/data/post_model.dart';
import '../../rankings/data/week_model.dart';
import '../../../core/utils/cdn_helper.dart';

part 'rankings_screen.g.dart';

// ── Rankings Repository ────────────────────────────────────────────────────
@riverpod
Future<List<PostModel>> tierRankings(Ref ref, String weekId, String tier) async {
  final data = await supabase
      .from('posts_anonymous')
      .select('*, weekly_votes!inner(paid_votes, total_score)')
      .eq('week_id', weekId)
      .eq('tier', tier)
      .eq('is_active', true)
      .order('total_score', referencedTable: 'weekly_votes', ascending: false)
      .limit(10);

  return (data as List).map((j) {
    final wv = (j['weekly_votes'] is List) ? j['weekly_votes'].first : j['weekly_votes'];
    j['paid_votes'] = wv != null ? wv['paid_votes'] : 0;
    j['normalized_score'] = wv != null ? wv['total_score'] : j['normalized_score'];
    return PostModel.fromJson(j);
  }).toList();
}

// ── Rankings Screen ────────────────────────────────────────────────────────
class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(currentWeekProvider);
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.rankingsTitle)),
      body: weekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (week) {
          if (week == null) {
            return Center(child: Text(s.noActiveWeeks));
          }
          return Column(
            children: [
              // Countdown
              Padding(
                padding: const EdgeInsets.all(16),
                child: CountdownTimerWidget(
                  targetTime: week.isActive
                      ? week.votingClosesAt
                      : week.announcementAt,
                  label: week.isActive
                      ? s.votingClosesIn
                      : s.announcementIn,
                  color: week.isActive ? AppColors.primary : AppColors.accent,
                ),
              ),
              // Tab bar
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.tierBlue, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(s.tierBlueLabel,
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                          ),
                          Tab(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.tierGold, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(s.tierGoldLabel,
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                          ),
                          Tab(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.tierRed, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(s.tierRedLabel,
                                  style: const TextStyle(fontSize: 12)),
                            ]),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TierTab(weekId: week.id, tier: 'blue', week: week),
                            _TierTab(weekId: week.id, tier: 'gold', week: week),
                            _TierTab(weekId: week.id, tier: 'red',  week: week),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Tier Tab ───────────────────────────────────────────────────────────────
class _TierTab extends ConsumerWidget {
  final String weekId;
  final String tier;
  final WeekModel week;

  const _TierTab({
    required this.weekId,
    required this.tier,
    required this.week,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(tierRankingsProvider(weekId, tier));
    final tierColor = AppColors.getTierColor(tier);
    final s = ref.watch(appL10nProvider);

    return rankingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (posts) => Column(
        children: [
          if (tier == 'red')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.live),
                icon: const Icon(Icons.live_tv),
                label: Text(s.liveTitle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.liveRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          Expanded(
            child: posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 64, color: tierColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(s.noPostsYet),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) => _RankingItem(
                      post: posts[i],
                      rank: i + 1,
                      tierColor: tierColor,
                      isRevealed: week.isAnnounced,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Ranking Item Card ──────────────────────────────────────────────────────
class _RankingItem extends StatelessWidget {
  final PostModel post;
  final int rank;
  final Color tierColor;
  final bool isRevealed;

  const _RankingItem({
    required this.post, required this.rank,
    required this.tierColor, required this.isRevealed,
  });

  Widget _rankBadge() {
    if (rank == 1) return const _RankCrown(color: Color(0xFFFFD700));
    if (rank == 2) return const _RankCrown(color: Color(0xFFC0C0C0));
    if (rank == 3) return const _RankCrown(color: Color(0xFFCD7F32));
    return Container(
      width: 36, height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Text('$rank',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentSession?.user.id;
    return GestureDetector(
      onTap: post.userId != null
          ? () {
              if (post.userId == currentUserId) {
                context.go(AppRoutes.profile);
              } else {
                context.push(AppRoutes.profileView.replaceAll(':userId', post.userId!));
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: rank <= 3
              ? tierColor.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rank <= 3 ? tierColor.withValues(alpha: 0.3) : AppColors.divider,
          ),
        ),
        child: Row(
        children: [
          _rankBadge(),
          const SizedBox(width: 12),
          // Thumbnail
          if (post.thumbnailUrl != null || post.contentUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: getCdnUrl(post.thumbnailUrl ?? post.contentUrl ?? ''),
                width: 56, height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 56, height: 56, color: AppColors.surface),
                errorWidget: (_, __, ___) =>
                    Container(width: 56, height: 56, color: AppColors.surface,
                        child: const Icon(Icons.image_not_supported, size: 24)),
              ),
            )
          else
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                post.contentType == 'video' ? Icons.videocam : Icons.image,
                color: AppColors.textHint,
              ),
            ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRevealed
                      ? (post.displayName ?? post.creatorLabel)
                      : post.creatorLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                LevelBadgeWidget(level: post.level, fontSize: 10),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 13, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text('${post.rawLikes}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Icon(Icons.stars_outlined, size: 13, color: tierColor),
                    const SizedBox(width: 4),
                    Text(post.normalizedScore.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tierColor,
                            )),
                    const SizedBox(width: 12),
                    const Icon(Icons.card_giftcard, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${post.paidVotes}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            )),
                  ],
                ),
              ],
            ),
          ),
          // Winner crown for rank 1 after announcement
          if (rank == 1 && isRevealed)
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
        ],
      ),
    ),
  );
}
}

class _RankCrown extends StatelessWidget {
  final Color color;
  const _RankCrown({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.emoji_events, color: color, size: 22),
  );
}
