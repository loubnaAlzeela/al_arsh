import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import '../data/live_repository.dart';
import '../data/live_stream_model.dart';
import 'live_badge_widget.dart';

class HostLiveScreen extends ConsumerStatefulWidget {
  final String streamId;
  const HostLiveScreen({super.key, required this.streamId});

  @override
  ConsumerState<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends ConsumerState<HostLiveScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  RealtimeChannel? _presenceChannel;
  int _viewerCount = 0;
  bool _isEnding = false;
  Timer? _durationTimer;
  int _durationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _joinPresence();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
  }

  String get _formattedDuration {
    final h = _durationSeconds ~/ 3600;
    final m = (_durationSeconds % 3600) ~/ 60;
    final s = _durationSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _joinPresence() {
    _presenceChannel = supabase.channel('live_${widget.streamId}');
    _presenceChannel!
      ..onPresenceSync((payload) {
        final count = _presenceChannel!.presenceState().length;
        if (mounted) setState(() => _viewerCount = count);
      })
      ..onBroadcast(
        event: 'viewer_count',
        callback: (payload) {
          final count = payload['count'] as int? ?? 0;
          if (mounted) setState(() => _viewerCount = count);
        },
      )
      ..subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({'user_id': supabase.auth.currentUser?.id});
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

  Future<void> _endStream() async {
    final s = ref.read(appL10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(s.liveEndConfirm,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(s.liveEndDesc,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveRed,
              foregroundColor: Colors.white,
            ),
            child: Text(s.liveEndButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isEnding = true);
    try {
      await _presenceChannel?.unsubscribe();
      await LiveRepository.endStream(widget.streamId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _durationTimer?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(liveMessagesProvider(widget.streamId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Host Top Bar ─────────────────────────────────────────────
            _HostTopBar(
              viewerCount: _viewerCount,
              duration: _formattedDuration,
              isEnding: _isEnding,
              onEnd: _endStream,
            ),

            // ── Chat Area ────────────────────────────────────────────────
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
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) => _ChatBubble(
                          message: messages[i]),
                    );
                  },
                ),
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────
            Container(height: 1, color: AppColors.divider),

            // ── Message Input ────────────────────────────────────────────
            _ChatInput(
              controller: _msgCtrl,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Host Top Bar ───────────────────────────────────────────────────────────
class _HostTopBar extends ConsumerWidget {
  final int viewerCount;
  final String duration;
  final bool isEnding;
  final VoidCallback onEnd;

  const _HostTopBar({
    required this.viewerCount,
    required this.duration,
    required this.isEnding,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveRed.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Live badge
          const LiveBadgeWidget(),
          const SizedBox(width: 10),
          // Duration
          Text(
            duration,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          // Viewers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$viewerCount',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // End button
          ElevatedButton(
            onPressed: isEnding ? null : onEnd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isEnding
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    s.liveEnd,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Bubble ────────────────────────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
