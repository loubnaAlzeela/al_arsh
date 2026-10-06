import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/cdn_helper.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/live_repository.dart';
import '../data/live_stream_model.dart';
import 'live_badge_widget.dart';

class WatchLiveScreen extends ConsumerStatefulWidget {
  final String streamId;
  const WatchLiveScreen({super.key, required this.streamId});

  @override
  ConsumerState<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends ConsumerState<WatchLiveScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  RealtimeChannel? _presenceChannel;
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _joinPresence();
  }

  void _joinPresence() {
    _presenceChannel = supabase.channel('live_${widget.streamId}');
    _presenceChannel!
      ..onPresenceSync((payload) {
        final count = _presenceChannel!.presenceState().length;
        if (mounted) setState(() => _viewerCount = count);
      })
      ..subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({
            'user_id': supabase.auth.currentUser?.id ?? 'anonymous',
          });
        }
      });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _msgCtrl.clear();
    await LiveRepository.sendMessage(
      streamId: widget.streamId,
      content: text,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamAsync = ref.watch(liveStreamDetailProvider(widget.streamId));
    final messagesAsync = ref.watch(liveMessagesProvider(widget.streamId));
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: streamAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.liveRed)),
          error: (e, _) => Center(child: Text('$e')),
          data: (stream) {
            if (stream == null || !stream.isLive) {
              return _StreamEndedView();
            }
            return Column(
              children: [
                // ── Watch Top Bar ──────────────────────────────────────
                _WatchTopBar(
                  stream: stream,
                  viewerCount: _viewerCount,
                  onBack: () => Navigator.pop(context),
                ),

                // ── Chat Messages ──────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8)],
                      ),
                    ),
                    child: messagesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (messages) {
                        if (messages.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom();
                          });
                        }
                        return messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline,
                                        size: 48, color: AppColors.textHint),
                                    const SizedBox(height: 12),
                                    Text(
                                      s.isArabic ? 'كن أول من يُعلّق!' : 'Be the first to comment!',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                itemCount: messages.length,
                                itemBuilder: (ctx, i) =>
                                    _ChatBubble(message: messages[i]),
                              );
                      },
                    ),
                  ),
                ),

                Container(height: 1, color: AppColors.divider),

                // ── Message Input ──────────────────────────────────────
                _ChatInput(
                  controller: _msgCtrl,
                  onSend: _sendMessage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Watch Top Bar ──────────────────────────────────────────────────────────
class _WatchTopBar extends ConsumerWidget {
  final LiveStreamModel stream;
  final int viewerCount;
  final VoidCallback onBack;

  const _WatchTopBar({
    required this.stream,
    required this.viewerCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveRed.withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textSecondary, size: 20),
            onPressed: onBack,
          ),
          // Host avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: stream.hostAvatarUrl != null
                ? CachedNetworkImageProvider(getCdnUrl(stream.hostAvatarUrl!))
                : null,
            child: stream.hostAvatarUrl == null
                ? const Icon(Icons.person, size: 20, color: AppColors.textHint)
                : null,
          ),
          const SizedBox(width: 8),
          // Title + host
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stream.hostDisplayName ?? (s.isArabic ? 'ملك' : 'King'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Live badge
          const LiveBadgeWidget(),
          const SizedBox(width: 10),
          // Viewers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  '$viewerCount',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stream Ended ───────────────────────────────────────────────────────────
class _StreamEndedView extends ConsumerWidget {
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
                size: 52, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            s.liveEnded,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isArabic ? 'انتهى البث المباشر' : 'Live stream ended',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(s.liveBackToList),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble (reused from host) ─────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final LiveMessageModel message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.userId == supabase.auth.currentUser?.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: message.avatarUrl != null
                  ? NetworkImage(message.avatarUrl!)
                  : null,
              child: message.avatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: AppColors.textHint)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, right: 4),
                    child: Text(
                      message.displayName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.liveRed.withValues(alpha: 0.85)
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe
                          ? const Radius.circular(14)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    message.content,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Chat Input ─────────────────────────────────────────────────────────────
class _ChatInput extends ConsumerWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: s.liveChatHint,
                hintStyle: const TextStyle(color: AppColors.textHint),
                hintTextDirection: TextDirection.rtl,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.liveRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
