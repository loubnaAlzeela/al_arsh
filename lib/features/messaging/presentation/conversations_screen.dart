import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../core/l10n/app_l10n.dart';
import '../data/conversation_model.dart';

part 'conversations_screen.g.dart';

// ── Provider ───────────────────────────────────────────────────
@riverpod
Future<List<ConversationModel>> myConversations(Ref ref) async {
  final me = supabase.auth.currentSession?.user.id;
  if (me == null) return [];

  final data = await supabase
      .from('conversations')
      .select('*, participant_1_user:users!participant_1(username, display_name, avatar_url), participant_2_user:users!participant_2(username, display_name, avatar_url)')
      .or('participant_1.eq.$me,participant_2.eq.$me')
      .order('last_message_at', ascending: false);

  return (data as List).map((row) {
    final p1 = row['participant_1'] as String;
    final isP1 = me == p1;
    final otherData = isP1
        ? row['participant_2_user'] as Map<String, dynamic>? ?? {}
        : row['participant_1_user'] as Map<String, dynamic>? ?? {};
    final otherId = isP1 ? row['participant_2'] as String : p1;

    return ConversationModel(
      id:               row['id'] as String,
      participant1:     p1,
      participant2:     row['participant_2'] as String,
      lastMessage:      row['last_message'] as String?,
      lastMessageAt:    row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null,
      createdAt:        DateTime.parse(row['created_at'] as String),
      otherUserId:      otherId,
      otherUsername:    otherData['username'] as String? ?? '',
      otherDisplayName: otherData['display_name'] as String? ?? '',
      otherAvatarUrl:   otherData['avatar_url'] as String?,
    );
  }).toList();
}

// ── Get or Create Conversation ─────────────────────────────────
Future<String> getOrCreateConversation(String otherUserId) async {
  final me = supabase.auth.currentSession?.user.id;
  if (me == null) throw Exception('Not authenticated');

  // Canonical ordering: smaller UUID is participant_1
  final p1 = me.compareTo(otherUserId) < 0 ? me : otherUserId;
  final p2 = me.compareTo(otherUserId) < 0 ? otherUserId : me;

  // Check if conversation exists
  final existing = await supabase
      .from('conversations')
      .select('id')
      .eq('participant_1', p1)
      .eq('participant_2', p2)
      .maybeSingle();

  if (existing != null) return existing['id'] as String;

  // Create new conversation
  final result = await supabase.from('conversations').insert({
    'participant_1': p1,
    'participant_2': p2,
  }).select('id').single();

  return result['id'] as String;
}

// ── Screen ─────────────────────────────────────────────────────
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(myConversationsProvider);
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.messagesTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: s.newChat,
            onPressed: () => _showNewChatDialog(context, ref),
          ),
        ],
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('${s.errorMsg}: $e', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(myConversationsProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return _EmptyConversations(onNewChat: () => _showNewChatDialog(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myConversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 80,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (ctx, i) => _ConversationTile(conv: conversations[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewChatDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appL10nProvider);
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.newChat,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: s.searchByUsername,
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final username = controller.text.trim().replaceAll('@', '');
                  if (username.isEmpty) return;
                  Navigator.pop(ctx);
                  await _startChatByUsername(context, ref, username);
                },
                child: Text(s.startChat,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChatByUsername(
    BuildContext context,
    WidgetRef ref,
    String username,
  ) async {
    try {
      final result = await supabase
          .from('users')
          .select('id, display_name, avatar_url')
          .eq('username', username)
          .maybeSingle();
      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.read(appL10nProvider).userNotFound)),
          );
        }
        return;
      }
      final convId = await getOrCreateConversation(result['id'] as String);
      ref.invalidate(myConversationsProvider);
      if (context.mounted) {
        context.push('/chat/$convId', extra: {
          'displayName': result['display_name'] as String?,
          'avatarUrl': result['avatar_url'] as String?,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ref.read(appL10nProvider).errorMsg}: $e')),
        );
      }
    }
  }
}

// ── Conversation Tile ───────────────────────────────────────────
class _ConversationTile extends ConsumerWidget {
  final ConversationModel conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return InkWell(
      onTap: () => context.push('/chat/${conv.id}', extra: {
        'displayName': conv.otherDisplayName,
        'avatarUrl': conv.otherAvatarUrl,
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _Avatar(avatarUrl: conv.otherAvatarUrl, displayName: conv.otherDisplayName),
            const SizedBox(width: 12),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv.lastMessage ?? s.startChatDots,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conv.lastMessage != null
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            if (conv.lastMessageAt != null)
              Text(
                timeago.format(conv.lastMessageAt!, locale: 'ar'),
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Widget ──────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  const _Avatar({this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initials(displayName),
              )
            : _initials(displayName),
      ),
    );
  }

  Widget _initials(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyConversations extends ConsumerWidget {
  final VoidCallback onNewChat;
  const _EmptyConversations({required this.onNewChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.noConversationsYet,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.startNewChatWithAnyUser,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onNewChat,
            icon: const Icon(Icons.edit, size: 18),
            label: Text(s.newChat),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}
