import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';

part 'follow_button_widget.g.dart';

// ── Providers ──────────────────────────────────────────────────
@riverpod
Future<int> followerCount(Ref ref, String userId) async {
  final result = await supabase
      .from('follows')
      .select()
      .eq('following_id', userId)
      .count();
  return result.count;
}

@riverpod
Future<int> followingCount(Ref ref, String userId) async {
  final result = await supabase
      .from('follows')
      .select()
      .eq('follower_id', userId)
      .count();
  return result.count;
}

@riverpod
Future<bool> isFollowing(Ref ref, String targetUserId) async {
  final me = supabase.auth.currentSession?.user.id;
  if (me == null) return false;
  final result = await supabase
      .from('follows')
      .select()
      .eq('follower_id', me)
      .eq('following_id', targetUserId)
      .maybeSingle();
  return result != null;
}

// ── Follow Button Widget ────────────────────────────────────────
class FollowButtonWidget extends ConsumerStatefulWidget {
  final String targetUserId;
  const FollowButtonWidget({super.key, required this.targetUserId});

  @override
  ConsumerState<FollowButtonWidget> createState() => _FollowButtonWidgetState();
}

class _FollowButtonWidgetState extends ConsumerState<FollowButtonWidget>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    final me = supabase.auth.currentSession?.user.id;
    if (me == null || _loading) return;

    setState(() => _loading = true);
    _animController.forward().then((_) => _animController.reverse());

    try {
      if (currentlyFollowing) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', me)
            .eq('following_id', widget.targetUserId);
      } else {
        await supabase.from('follows').insert({
          'follower_id': me,
          'following_id': widget.targetUserId,
        });
      }
      ref.invalidate(isFollowingProvider(widget.targetUserId));
      ref.invalidate(followerCountProvider(widget.targetUserId));
    } catch (e) {
      debugPrint('Follow error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(appL10nProvider).genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appL10nProvider);
    final followAsync = ref.watch(isFollowingProvider(widget.targetUserId));

    return followAsync.when(
      loading: () => _buildButton(isFollowing: false, loading: true, s: s),
      error: (_, __) => const SizedBox.shrink(),
      data: (isFollowing) => _buildButton(isFollowing: isFollowing, loading: _loading, s: s),
    );
  }

  Widget _buildButton({required bool isFollowing, required bool loading, required AppL10n s}) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 40,
        constraints: const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          gradient: isFollowing
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isFollowing ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(20),
          border: isFollowing
              ? Border.all(color: AppColors.border, width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: loading ? null : () => _toggleFollow(isFollowing),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isFollowing ? AppColors.textSecondary : Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing ? Icons.check : Icons.person_add_alt_1,
                            size: 16,
                            color: isFollowing ? AppColors.textSecondary : Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFollowing ? s.followingBtn : s.followBtn,
                            style: TextStyle(
                              color: isFollowing ? AppColors.textSecondary : Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Follower/Following Stats Widget ────────────────────────────
class FollowStatsWidget extends ConsumerWidget {
  final String userId;
  const FollowStatsWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followerCountProvider(userId));
    final followingAsync = ref.watch(followingCountProvider(userId));
    final s = ref.watch(appL10nProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FollowStat(
          label: s.follower,
          countAsync: followersAsync,
        ),
        Container(
          height: 28,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.divider,
        ),
        _FollowStat(
          label: s.following,
          countAsync: followingAsync,
        ),
      ],
    );
  }
}

class _FollowStat extends StatelessWidget {
  final String label;
  final AsyncValue<int> countAsync;
  const _FollowStat({required this.label, required this.countAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        countAsync.when(
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          error: (_, __) => const Text('—'),
          data: (count) => Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
