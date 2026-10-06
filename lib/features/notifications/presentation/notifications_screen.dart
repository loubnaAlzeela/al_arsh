import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';

part 'notifications_screen.g.dart';

// ── Notification Model ─────────────────────────────────────────────────────
class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id:        json['id'] as String,
    userId:    json['user_id'] as String,
    type:      json['type'] as String,
    title:     json['title'] as String,
    body:      json['body'] as String,
    relatedId: json['related_id'] as String?,
    isRead:    json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ── Provider ───────────────────────────────────────────────────────────────
@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async {
    final session = supabase.auth.currentSession;
    if (session == null) return [];
    return _fetch(session.user.id);
  }

  Future<List<NotificationModel>> _fetch(String userId) async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((j) => NotificationModel.fromJson(j)).toList();
  }

  Future<void> markAllRead() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', session.user.id)
        .eq('is_read', false);
    ref.invalidateSelf();
  }

  Future<void> markOneRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.id == id
          ? NotificationModel(
              id: n.id, userId: n.userId, type: n.type,
              title: n.title, body: n.body, relatedId: n.relatedId,
              isRead: true, createdAt: n.createdAt)
          : n).toList(),
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsNotifierProvider);
    final s = ref.watch(appL10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsNotifierProvider.notifier).markAllRead(),
            child: Text(s.markAllRead,
                style: const TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (notifications) => notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text(s.noNotifications,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (ctx, i) =>
                    _NotificationTile(notif: notifications[i]),
              ),
      ),
    );
  }
}

// ── Notification Tile ──────────────────────────────────────────────────────
class _NotificationTile extends ConsumerWidget {
  final NotificationModel notif;
  const _NotificationTile({required this.notif});

  IconData get _icon {
    switch (notif.type) {
      case 'vote_received':  return Icons.favorite;
      case 'gift_received':  return Icons.card_giftcard;
      case 'week_winner':    return Icons.emoji_events;
      case 'level_up':       return Icons.trending_up;
      case 'streak':         return Icons.local_fire_department;
      case 'new_follower':   return Icons.person_add;
      default:               return Icons.notifications;
    }
  }

  Color get _iconColor {
    switch (notif.type) {
      case 'vote_received':  return AppColors.accent;
      case 'gift_received':  return AppColors.primary;
      case 'week_winner':    return AppColors.primary;
      case 'level_up':       return AppColors.success;
      case 'streak':         return Colors.orange;
      case 'new_follower':   return AppColors.tierBlue;
      default:               return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref
          .read(notificationsNotifierProvider.notifier)
          .markOneRead(notif.id),
      child: Container(
        color: notif.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notif.createdAt, locale: 'ar'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
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
