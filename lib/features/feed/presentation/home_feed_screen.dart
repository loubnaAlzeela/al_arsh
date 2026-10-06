import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/locale_provider.dart';
import '../../../shared/providers/current_week_provider.dart';
import '../../../shared/widgets/level_badge_widget.dart';
import '../../../shared/widgets/countdown_timer_widget.dart';
import '../data/feed_repository.dart';
import '../data/post_model.dart';
import '../../../core/utils/cdn_helper.dart';
import '../../../shared/widgets/video_player_widget.dart';
import '../../../core/utils/device_id_helper.dart';
import '../../gifts/presentation/gift_sheet.dart';
import '../../gifts/presentation/gift_animation_overlay.dart';
import '../../../core/constants/app_strings.dart';
import '../../follow/presentation/follow_button_widget.dart';
import 'comments_sheet.dart';
import '../../../main.dart';


class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _pageController = PageController();
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final week = ref.read(currentWeekProvider).valueOrNull;
      if (week != null) _loadInitialIfNeeded(week.id);
    });
  }

  void _loadInitialIfNeeded(String weekId) {
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    ref.read(feedNotifierProvider.notifier).loadFeed(weekId);
  }

  void _onPageScroll() {
    final posts = ref.read(feedNotifierProvider).valueOrNull ?? [];
    final page = _pageController.page?.round() ?? 0;
    if (page >= posts.length - 3) {
      final week = ref.read(currentWeekProvider).valueOrNull;
      final notifier = ref.read(feedNotifierProvider.notifier);
      if (week != null && notifier.hasMore) {
        notifier.loadFeed(week.id, category: notifier.currentCategory);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekAsync = ref.watch(currentWeekProvider);
    final feedAsync = ref.watch(feedNotifierProvider);
    final s = ref.watch(appL10nProvider);

    ref.listen<AsyncValue>(currentWeekProvider, (_, next) {
      final week = next.valueOrNull;
      if (week != null) _loadInitialIfNeeded(week.id);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: weekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
        data: (week) {
          if (week == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(s.noActiveWeeks, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$e', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(feedNotifierProvider.notifier).refresh(week.id),
                    child: Text(s.retry),
                  ),
                ],
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library_outlined, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text(s.noPostsYet,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(s.beFirst,
                          style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  // ── Full-screen vertical PageView (TikTok style) ──
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) => PostCardWidget(
                      key: ValueKey(posts[i].id),
                      post: posts[i],
                      week: week,
                      onVote: () async {
                        final notifier = ref.read(feedNotifierProvider.notifier);
                        try {
                          await ref.read(feedRepositoryProvider).castVote(
                                postId: posts[i].id,
                                weekId: week.id,
                              );
                          notifier.updateVote(posts[i].creatorLabel);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
                    ),
                  ),

                  // ── Top overlay: logo + actions + countdown + categories ──
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Timer (center) + actions (end)
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Countdown timer (centered perfectly)
                                  CountdownTimerWidget(
                                    targetTime: week.isActive ? week.votingClosesAt : week.announcementAt,
                                    label: week.isActive ? s.votingClosesIn : s.announcementIn,
                                    color: week.isActive ? AppColors.primary : AppColors.accent,
                                  ),
                                  // Actions: language + notifications (end)
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Language toggle
                                        Consumer(builder: (ctx, langRef, _) {
                                          final loc = langRef.watch(localeProvider);
                                          return GestureDetector(
                                            onTap: () => langRef.read(localeProvider.notifier).toggle(),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                              child: Text(
                                                loc.languageCode == 'ar' ? 'EN' : 'AR',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        // Notifications
                                        IconButton(
                                          icon: const Icon(Icons.notifications_outlined,
                                              color: Colors.white, size: 28),
                                          onPressed: () => context.push(AppRoutes.notifications),
                                          tooltip: s.notifications,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Guest login banner
                              const _GuestLoginBanner(),
                              const SizedBox(height: 4),

                              SizedBox(
                                height: 34,
                                child: Consumer(builder: (context, ref, _) {
                                  final categories = s.categoriesWithAll;
                                  // We use the Arabic list as the actual value to set in DB filter
                                  // (must stay in sync with categoriesWithAll's length/order).
                                  final dbCategories = ['الكل', ...AppStrings.categories];
                                  final currentCategory =
                                      ref.watch(feedNotifierProvider.notifier).currentCategory ?? 'الكل';
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final cat = categories[index];
                                      final dbCat = dbCategories[index];
                                      final isSelected = dbCat == currentCategory;
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: GestureDetector(
                                          onTap: () => ref
                                              .read(feedNotifierProvider.notifier)
                                              .setCategory(week.id, dbCat == 'الكل' ? null : dbCat),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.black.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : Colors.white38,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              cat,
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white,
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Post Card Widget (Full-Screen TikTok Style) ────────────────────────────
class PostCardWidget extends ConsumerStatefulWidget {
  final PostModel post;
  final dynamic week;
  final VoidCallback onVote;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.week,
    required this.onVote,
  });

  @override
  ConsumerState<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends ConsumerState<PostCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  bool _viewRecorded = false;

  @override
  void initState() {
    super.initState();
    _recordViewIfNeeded();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onVoteTap() {
    final hasVotedThisWeek =
        ref.read(feedNotifierProvider).valueOrNull?.any((p) => p.hasVoted) ?? false;
    if (widget.post.hasVoted || hasVotedThisWeek || widget.week.status != 'active') return;
    widget.onVote();
  }

  Future<void> _recordViewIfNeeded() async {
    if (_viewRecorded) return;
    _viewRecorded = true;
    try {
      final viewerKey = await DeviceIdHelper.getViewerKey();
      await ref.read(feedRepositoryProvider).recordView(widget.post.id, viewerKey);
    } catch (e) {
      // Ignore silently
    }
  }

  void _onLikeTap() async {
    _heartController.forward(from: 0);
    try {
      final result = await ref.read(feedRepositoryProvider).toggleLike(widget.post.id);
      ref.read(feedNotifierProvider.notifier).updateLike(
            widget.post.id,
            result['liked'] as bool,
            result['count'] as int,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ref.read(appL10nProvider).likeError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final s = ref.watch(appL10nProvider);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Media background (fills entire screen) ──
          if (post.contentType == 'video' && post.contentUrl != null)
            VideoPlayerWidget(videoUrl: getCdnUrl(post.contentUrl!))
          else if (post.thumbnailUrl != null || post.contentUrl != null)
            CachedNetworkImage(
              imageUrl: getCdnUrl(post.thumbnailUrl ?? post.contentUrl ?? ''),
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(color: Theme.of(context).scaffoldBackgroundColor),
              errorWidget: (ctx, url, err) => Container(
                color: Colors.black12,
                child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 48),
              ),
            )
          else
            Container(color: Theme.of(context).scaffoldBackgroundColor),

          // ── Top gradient (for top overlay readability) ──
          Positioned(
            top: 0, left: 0, right: 0, height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Bottom gradient (for creator info + actions) ──
          Positioned(
            bottom: 0, left: 0, right: 0, height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Report button (below top overlay) ──
          Positioned(
            top: 200, right: 4,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white60, size: 22),
              color: AppColors.surface,
              onSelected: (value) async {
                if (value == 'report') {
                  await supabase.from('posts').update({'is_reported': true}).eq('id', post.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.reportedMsg)),
                    );
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'report',
                  child: Text(s.reportPost, style: const TextStyle(color: AppColors.liveRed)),
                ),
              ],
            ),
          ),

          // ── Bottom overlay: creator info + actions ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ── Creator info (tap to view profile) ──
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final currentUserId = supabase.auth.currentSession?.user.id;
                          if (post.userId != null) {
                            if (post.userId == currentUserId) {
                              context.go(AppRoutes.profile);
                            } else {
                              context.push(
                                  AppRoutes.profileView.replaceAll(':userId', post.userId!));
                            }
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            post.isRevealed && post.avatarUrl != null
                                ? TierAvatarWidget(
                                    avatarUrl: post.avatarUrl, tier: post.tier, radius: 22)
                                : Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.15),
                                      border: Border.all(
                                          color: AppColors.getTierColor(post.tier), width: 2),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white70, size: 22),
                                  ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    post.isRevealed
                                        ? (post.displayName ?? post.creatorLabel)
                                        : post.creatorLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (post.caption != null && post.caption!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      post.caption!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Vote button
                            if (widget.week.status == 'active' &&
                                !post.id.startsWith('static_') &&
                                post.userId != supabase.auth.currentUser?.id)
                              Consumer(
                                builder: (context, ref, child) {
                                  final hasVotedThisWeek = ref
                                          .watch(feedNotifierProvider)
                                          .valueOrNull
                                          ?.any((p) => p.hasVoted) ??
                                      false;
                                  final isVotedForThis = post.hasVoted;
                                  final isDisabled = hasVotedThisWeek && !isVotedForThis;

                                  return GestureDetector(
                                    onTap: isDisabled ? null : _onVoteTap,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: isVotedForThis
                                            ? AppColors.success.withValues(alpha: 0.2)
                                            : isDisabled
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : AppColors.primary,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: isVotedForThis
                                              ? AppColors.success
                                              : isDisabled
                                                  ? Colors.white30
                                                  : AppColors.primary,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isVotedForThis
                                                ? Icons.how_to_vote
                                                : Icons.how_to_vote_outlined,
                                            color: isVotedForThis
                                                ? AppColors.success
                                                : isDisabled
                                                    ? Colors.white54
                                                    : Colors.black,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isVotedForThis
                                                ? s.votedLabel
                                                : isDisabled
                                                    ? s.usedVoteLabel
                                                    : s.voteNowLabel,
                                            style: TextStyle(
                                              color: isVotedForThis
                                                  ? AppColors.success
                                                  : isDisabled
                                                      ? Colors.white54
                                                      : Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Gift Button
                            if (widget.week.status == 'active' &&
                                !post.id.startsWith('static_') &&
                                post.userId != supabase.auth.currentUser?.id) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => GiftSheet.show(context, post.id),
                                child: const Icon(Icons.card_giftcard,
                                    color: AppColors.primary, size: 30),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Action buttons (Vertical Stack) ──
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mute Toggle Button
                        ValueListenableBuilder<bool>(
                          valueListenable: globalIsMuted,
                          builder: (context, isMuted, child) {
                            return GestureDetector(
                              onTap: () => globalIsMuted.value = !globalIsMuted.value,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Follow Button
                        if (post.userId != supabase.auth.currentUser?.id)
                          post.userId == null
                              ? GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(s.cannotFollowAnon)),
                                    );
                                  },
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_add,
                                        color: Colors.white54,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                )
                              : Consumer(
                                  builder: (context, ref, child) {
                                    final isFollowingAsync = ref.watch(isFollowingProvider(post.userId!));
                                    final isFollowing = isFollowingAsync.valueOrNull ?? false;

                                    return GestureDetector(
                                      onTap: () async {
                                        final me = supabase.auth.currentSession?.user.id;
                                        if (me == null) return;
                                        if (isFollowing) {
                                          await supabase.from('follows').delete().eq('follower_id', me).eq('following_id', post.userId!);
                                        } else {
                                          await supabase.from('follows').insert({'follower_id': me, 'following_id': post.userId!});
                                        }
                                        ref.invalidate(isFollowingProvider(post.userId!));
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isFollowing ? Icons.person_remove : Icons.person_add,
                                            color: isFollowing ? Colors.white70 : AppColors.primary,
                                            size: 30,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        if (post.userId != supabase.auth.currentUser?.id)
                          const SizedBox(height: 16),

                        // Views
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_outlined, color: Colors.white70, size: 24),
                            const SizedBox(height: 3),
                            Text(
                              '${post.rawViews}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Comments
                        GestureDetector(
                          onTap: () => CommentsSheet.show(context, post.id),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                              const SizedBox(height: 3),
                              Text(
                                '${post.rawComments}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Like
                        AnimatedBuilder(
                          animation: _heartScale,
                          builder: (ctx, _) => Transform.scale(
                            scale: _heartScale.value,
                            child: GestureDetector(
                              onTap: _onLikeTap,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: post.isLiked ? AppColors.accent : Colors.white,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${post.rawLikes}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── TikTok-style gift animations, broadcast live to every viewer ──
          GiftAnimationLayer(postId: post.id),
        ],
      ),
    );
  }
}

// ── Guest Login Banner ──────────────────────────────────────────────────────────
/// Shows a slim "سجّل الدخول" banner for unauthenticated users.
/// Completely hidden for authenticated users.
class _GuestLoginBanner extends ConsumerWidget {
  const _GuestLoginBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = supabase.auth.currentSession;
    if (session != null) return const SizedBox.shrink();

    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.login),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_outlined, color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'سجّل الدخول للمشاركة' : 'Sign in to participate',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
