import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/level_badge_widget.dart';
import '../../auth/data/user_model.dart';
import '../../feed/data/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/cdn_helper.dart';
import '../../../shared/widgets/video_player_widget.dart';
import '../../gifts/presentation/received_gifts_widget.dart';
import '../../follow/presentation/follow_button_widget.dart';
import '../../messaging/presentation/conversations_screen.dart';

part 'profile_screen.g.dart';

// ── Profile Stats Model ────────────────────────────────────────────────────
class ProfileStats {
  final int totalPosts;
  final int totalVotes;
  final int bestRank;
  const ProfileStats({
    required this.totalPosts,
    required this.totalVotes,
    required this.bestRank,
  });
}

// ── Providers ──────────────────────────────────────────────────────────────
@riverpod
Future<UserModel?> userProfile(Ref ref, String? userId) async {
  final resolvedId = userId ?? supabase.auth.currentSession?.user.id;
  if (resolvedId == null) return null;
  final data = await supabase
      .from('users')
      .select()
      .eq('id', resolvedId)
      .maybeSingle();
  return data != null ? UserModel.fromJson(data) : null;
}

@riverpod
Future<List<PostModel>> userPosts(Ref ref, String userId) async {
  final data = await supabase
      .from('posts')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true)
      .order('created_at', ascending: false)
      .limit(30);
  return (data as List).map((j) => PostModel.fromJson({
    ...j,
    'creator_label': 'منشئ',
    'week_status': 'announced',
    'tier': 'blue',
    'level': 'مجهول',
  })).toList();
}

@riverpod
Future<ProfileStats> profileStats(Ref ref, String userId) async {
  // Total posts count
  final postsResult = await supabase
      .from('posts')
      .select()
      .eq('user_id', userId)
      .eq('is_active', true)
      .count(CountOption.exact);

  // Total votes received
  final votesResult = await supabase
      .from('votes')
      .select('posts!inner(user_id)')
      .eq('posts.user_id', userId)
      .count(CountOption.exact);

  return ProfileStats(
    totalPosts: postsResult.count,
    totalVotes: votesResult.count,
    bestRank: 0, // Could be computed from rankings history
  );
}

// ── Screen ─────────────────────────────────────────────────────────────────
// ── _OwnProfileLoader: loads own profile only after currentUser is known ──
/// Separate widget for own-profile so all ref.watch calls happen
/// unconditionally inside its own build() — required by Riverpod.
class _OwnProfileLoader extends ConsumerWidget {
  const _OwnProfileLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final s = ref.watch(appL10nProvider);

    return currentUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${s.profileLoadError}: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _ProfileContent(userId: user.id, isOwnProfile: true, currentUser: user);
      },
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ملف مستخدم آخر — نعرف الـ ID مسبقاً
    if (userId != null) {
      final currentUser = ref.watch(currentUserProvider).valueOrNull;
      final isOwnProfile = userId == currentUser?.id;
      return _ProfileContent(
        userId: userId!,
        isOwnProfile: isOwnProfile,
        currentUser: currentUser,
      );
    }
    // ملفي الشخصي — نحتاج أولاً لمعرفة الـ ID من currentUserProvider
    return const _OwnProfileLoader();
  }
}

/// Widget مستقل يحمل بيانات الملف الشخصي بعد معرفة الـ userId.
/// كل ref.watch هنا غير مشروط ← يطابق قواعد Riverpod.
class _ProfileContent extends ConsumerWidget {
  final String userId;
  final bool isOwnProfile;
  final dynamic currentUser;
  const _ProfileContent({
    required this.userId,
    required this.isOwnProfile,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(userProfileProvider(userId));
    final postsAsync    = ref.watch(userPostsProvider(userId));
    final statsAsync    = ref.watch(profileStatsProvider(userId));
    final s             = ref.watch(appL10nProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        if (user == null) {
          return Scaffold(body: Center(child: Text(s.userNotFound)));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(isOwnProfile ? s.myProfile : user.displayName),
            actions: [
              // ── Notification bell (shown in profile since FAB is hidden here) ──
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                  onPressed: () => context.push(AppRoutes.wallet),
                ),
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(AppRoutes.editProfile),
                ),
              if (currentUser?.isAdmin == true)
                PopupMenuButton(
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'admin', child: Text(s.adminPanelMenu)),
                  ],
                  onSelected: (v) {
                    if (v == 'admin') context.push(AppRoutes.admin);
                  },
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Avatar + tier ring
                    TierAvatarWidget(
                      avatarUrl: user.avatarUrl,
                      tier: user.tier,
                      radius: 48,
                    ),
                    const SizedBox(height: 12),
                    // Display name
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Level badge
                    LevelBadgeWidget(level: user.level),
                    const SizedBox(height: 20),

                    // ── Follow stats (shown for all profiles) ──
                    FollowStatsWidget(userId: user.id),
                    const SizedBox(height: 16),

                    // ── Follow + Message buttons (only for other users) ──
                    if (!isOwnProfile) ...
                      [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FollowButtonWidget(targetUserId: user.id),
                            const SizedBox(width: 12),
                            _MessageButton(targetUser: user),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                    // Stats row
                    statsAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              value: '${stats.totalPosts}',
                              label: s.totalPosts,
                            ),
                            _StatDivider(),
                            _StatItem(
                              value: '${stats.totalVotes}',
                              label: s.totalVotes,
                            ),
                            _StatDivider(),
                            _StatItem(
                              value: '${user.streakDays}',
                              label: s.streakDays,
                              icon: Icons.local_fire_department,
                              iconColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Level progress bar
                    _LevelProgressBar(user: user),
                    const SizedBox(height: 24),

                    // Received gifts
                    ReceivedGiftsWidget(userId: user.id),
                    const SizedBox(height: 16),

                    // Posts grid header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                  ],
                ),
              ),

              // Posts grid
              postsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
                data: (posts) => posts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.grid_off_outlined,
                                    size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  isOwnProfile ? s.noPostsOwn : s.noPostsOther,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _PostGridItem(post: posts[i]),
                          childCount: posts.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ── Level Progress Bar ─────────────────────────────────────────────────────
class _LevelProgressBar extends StatelessWidget {
  final UserModel user;
  const _LevelProgressBar({required this.user});

  static const _levelThresholds = {
    'مجهول':  100,   // need 100 votes for موهبة
    'موهبة':  500,   // need 500 for صاعد
    'صاعد':   2000,  // need 2000 for نجم
    'نجم':    0,     // win-based from here
    'ملك':    0,
    'أسطورة': 0,
  };

  @override
  Widget build(BuildContext context) {
    final threshold = _levelThresholds[user.level] ?? 0;
    if (threshold == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Consumer(
          builder: (context, ref, _) {
            final s = ref.watch(appL10nProvider);
            return Text(
              s.maxLevelMsg,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      );
    }

    final progress = (user.totalCompetitionPoints / threshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(appL10nProvider);
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.levelProgress,
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    '${user.totalCompetitionPoints} / $threshold',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: progress,
                backgroundColor: AppColors.surface,
                linearGradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                ),
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stat Item ──────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  const _StatItem({required this.value, required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    width: 1,
    color: AppColors.divider,
  );
}

// ── Post Grid Item ─────────────────────────────────────────────────────────
class _PostGridItem extends StatelessWidget {
  final PostModel post;
  const _PostGridItem({required this.post});

  void _showMediaPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(color: Colors.black87),
          ),
          Center(
            child: post.contentType == 'video' && post.contentUrl != null
                ? AspectRatio(
                    aspectRatio: 9 / 16,
                    child: VideoPlayerWidget(videoUrl: getCdnUrl(post.contentUrl!)),
                  )
                : CachedNetworkImage(
                    imageUrl: getCdnUrl(post.contentUrl ?? post.thumbnailUrl ?? ''),
                    fit: BoxFit.contain,
                  ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMediaPreview(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          post.thumbnailUrl != null || post.contentUrl != null
              ? CachedNetworkImage(
                  imageUrl: getCdnUrl(post.thumbnailUrl ?? post.contentUrl ?? ''),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.image_not_supported, color: AppColors.textHint),
                  ),
                )
              : Container(
                  color: AppColors.surface,
                  child: Icon(
                    post.contentType == 'video' ? Icons.videocam : Icons.image,
                    color: AppColors.textHint,
                  ),
                ),
          if (post.contentType == 'video')
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.play_circle_filled, color: Colors.white, size: 18),
            ),
          // Likes overlay
          Positioned(
            bottom: 4,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 12, color: Colors.white70),
                const SizedBox(width: 2),
                Text(
                  '${post.rawLikes}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Button ──────────────────────────────────────────────
class _MessageButton extends ConsumerStatefulWidget {
  final dynamic targetUser;
  const _MessageButton({required this.targetUser});

  @override
  ConsumerState<_MessageButton> createState() => _MessageButtonState();
}

class _MessageButtonState extends ConsumerState<_MessageButton> {
  bool _loading = false;

  Future<void> _openChat() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final convId = await getOrCreateConversation(widget.targetUser.id as String);
      if (mounted) {
        context.push(
          '/chat/$convId',
          extra: {
            'displayName': widget.targetUser.displayName as String,
            'avatarUrl': widget.targetUser.avatarUrl as String?,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _loading ? null : _openChat,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          ref.watch(appL10nProvider).messageBtn,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
