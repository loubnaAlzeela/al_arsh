import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/cdn_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/live_repository.dart';
import '../data/live_stream_model.dart';
import 'live_badge_widget.dart';

class LiveListScreen extends ConsumerWidget {
  const LiveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final streamsAsync = ref.watch(liveStreamsProvider);
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                color: AppColors.liveRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.liveTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── King Tier Banner ──────────────────────────────────────────
          userAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              final isKing = user.tier == 'red';
              return _LiveBanner(isKing: isKing, ref: ref);
            },
          ),

          // ── Streams List ──────────────────────────────────────────────
          Expanded(
            child: streamsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.liveRed),
              ),
              error: (e, _) => Center(
                child: Text('$e', style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (streams) {
                if (streams.isEmpty) {
                  return _EmptyStreams();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: streams.length,
                  itemBuilder: (ctx, i) => _StreamCard(
                    stream: streams[i],
                    onTap: () => context.push('/live/${streams[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner: King or Locked ─────────────────────────────────────────────────
class _LiveBanner extends ConsumerWidget {
  final bool isKing;
  final WidgetRef ref;

  const _LiveBanner({required this.isKing, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isKing) {
      return _KingBanner(ref: ref);
    }
    return const _LockedBanner();
  }
}

class _KingBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _KingBanner({required this.ref});

  void _startStream(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StartStreamSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFE63946)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveRed.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.live_tv, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isArabic ? '\u{1F451} \u0645\u0644\u0643 \u0627\u0644\u062f\u0648\u0631\u064a' : '\u{1F451} League King',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.isArabic ? '\u0627\u0628\u062f\u0623 \u0628\u062b\u0627\u064b \u0645\u0628\u0627\u0634\u0631\u0627\u064b \u0627\u0644\u0622\u0646' : 'Start a live stream now',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _startStream(context),
            icon: const Icon(Icons.stream, size: 16),
            label: Text(s.liveBroadcast),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.liveRed,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends ConsumerWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: AppColors.textHint, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.liveLocked,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.liveLockedDesc,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tierRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.tierRed.withValues(alpha: 0.3)),
            ),
            child: Text(
              s.isArabic ? '\u{1F451} \u0627\u0644\u0645\u0644\u0648\u0643' : '\u{1F451} Kings',
              style: const TextStyle(
                color: AppColors.tierRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────
class _EmptyStreams extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.live_tv_outlined,
                size: 56, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            s.noLiveStreams,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isArabic ? '\u0644\u0627 \u064a\u0648\u062c\u062f \u0628\u062b \u0645\u0628\u0627\u0634\u0631 \u0627\u0644\u0622\u0646' : 'No live streams right now',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Stream Card ────────────────────────────────────────────────────────────
class _StreamCard extends ConsumerWidget {
  final LiveStreamModel stream;
  final VoidCallback onTap;

  const _StreamCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Stream Preview Header ──────────────────────────────────
            Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    AppColors.liveRed.withValues(alpha: 0.7),
                    AppColors.background,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 12, left: 12,
                    child: LiveBadgeWidget(),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${stream.viewerCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text(
                      stream.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Host Info ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: stream.hostAvatarUrl != null
                        ? CachedNetworkImageProvider(
                            getCdnUrl(stream.hostAvatarUrl!))
                        : null,
                    child: stream.hostAvatarUrl == null
                        ? const Icon(Icons.person, color: AppColors.textHint, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.hostDisplayName ?? (s.isArabic ? '\u0645\u0644\u0643' : 'King'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.military_tech,
                                size: 13, color: AppColors.tierRed),
                            const SizedBox(width: 4),
                            Text(
                              s.isArabic ? '\u062f\u0648\u0631\u064a \u0627\u0644\u0645\u0644\u0648\u0643' : 'Kings League',
                              style: const TextStyle(
                                  color: AppColors.tierRed, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.liveRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    child: Text(s.liveWatch),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// ── Start Stream Bottom Sheet ──────────────────────────────────────────────
class _StartStreamSheet extends StatefulWidget {
  final WidgetRef ref;
  const _StartStreamSheet({required this.ref});

  @override
  State<_StartStreamSheet> createState() => _StartStreamSheetState();
}

class _StartStreamSheetState extends State<_StartStreamSheet> {
  final _titleCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _isLoading = true);
    try {
      final streamId = await LiveRepository.startStream(
        title: _titleCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        context.push('/live/host/$streamId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ref.watch(appL10nProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.liveRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.live_tv, color: AppColors.liveRed, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.liveStartTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    s.isArabic ? 'حصراً لملوك الدوري 👑' : 'Exclusively for Kings 👑',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title input
          TextField(
            controller: _titleCtrl,
            textDirection: TextDirection.rtl,
            maxLength: 60,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: s.liveStreamTitleHint,
              hintTextDirection: TextDirection.rtl,
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.liveRed, width: 1.5),
              ),
              counterStyle: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),

          // Start button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _start,
            icon: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.stream, size: 20),
            label: Text(
                _isLoading ? s.loading : s.liveGoLive),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
