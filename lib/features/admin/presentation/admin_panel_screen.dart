import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../main.dart';
import '../../../shared/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../gifts/data/gifts_repository.dart';
import '../../gifts/data/withdrawal_request_model.dart';

part 'admin_panel_screen.g.dart';

// ── Admin Stats Model ──────────────────────────────────────────────────────
class AdminStats {
  final int totalUsers;
  final int totalPostsThisWeek;
  final int totalVotesThisWeek;
  final int reportedPosts;

  const AdminStats({
    required this.totalUsers,
    required this.totalPostsThisWeek,
    required this.totalVotesThisWeek,
    required this.reportedPosts,
  });
}

// ── Reported Post Model ────────────────────────────────────────────────────
class ReportedPost {
  final String id;
  final String caption;
  final String category;
  final String userId;
  final DateTime createdAt;

  const ReportedPost({
    required this.id,
    required this.caption,
    required this.category,
    required this.userId,
    required this.createdAt,
  });

  factory ReportedPost.fromJson(Map<String, dynamic> json) => ReportedPost(
    id:        json['id'] as String,
    caption:   json['caption'] as String? ?? '',
    category:  json['category'] as String,
    userId:    json['user_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ── Providers ──────────────────────────────────────────────────────────────
@riverpod
Future<AdminStats> adminStats(Ref ref, String weekId) async {
  final usersResult = await supabase.from('users').select().count(CountOption.exact);
  final postsResult = await supabase
      .from('posts').select().eq('week_id', weekId).count(CountOption.exact);
  final votesResult = await supabase
      .from('votes').select().eq('week_id', weekId).count(CountOption.exact);
  final reportedResult = await supabase
      .from('posts').select().eq('is_reported', true).count(CountOption.exact);

  return AdminStats(
    totalUsers:          usersResult.count,
    totalPostsThisWeek:  postsResult.count,
    totalVotesThisWeek:  votesResult.count,
    reportedPosts:       reportedResult.count,
  );
}

@riverpod
Future<List<ReportedPost>> reportedPosts(Ref ref) async {
  final data = await supabase
      .from('posts')
      .select()
      .eq('is_reported', true)
      .eq('is_active', true)
      .order('created_at', ascending: false);
  return (data as List).map((j) => ReportedPost.fromJson(j)).toList();
}

// ── Screen ─────────────────────────────────────────────────────────────────
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final s = ref.watch(appL10nProvider);

    // Access guard
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(s.isArabic ? 'وصول مرفوض' : 'Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.accent),
              const SizedBox(height: 16),
              Text(s.isArabic ? 'ليس لديك صلاحية الوصول' : 'You do not have access'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminPanelMenu),
        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(s.isArabic ? 'وضع الإدارة — تصرف بحذر' : 'Admin Mode — Proceed with caution',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Actions ──
            Text(s.isArabic ? 'الإجراءات' : 'Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _AdminActionButton(
              icon: Icons.calculate_outlined,
              label: s.recalculateScores,
              color: AppColors.tierBlue,
              onTap: () => _callEdgeFunction(context, ref, 'calculate_scores'),
            ),
            const SizedBox(height: 10),
            _AdminActionButton(
              icon: Icons.emoji_events,
              label: s.announceWinners,
              color: AppColors.primary,
              onTap: () => _confirmAndCall(context, ref, 'announce_winners',
                  s.isArabic ? 'هل أنت متأكد من الإعلان عن الفائزين؟ لا يمكن التراجع.' : 'Are you sure you want to announce winners? This cannot be undone.'),
            ),
            const SizedBox(height: 10),
            _AdminActionButton(
              icon: Icons.payments_outlined,
              label: s.isArabic ? 'معالجة سحب الأرباح' : 'Process Withdrawals',
              color: AppColors.success,
              onTap: () => _showPayoutDialog(context, ref),
            ),
            const SizedBox(height: 24),

            // ── Pending Withdrawal Requests ──
            Text(s.isArabic ? 'طلبات السحب المعلقة' : 'Pending Withdrawals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Consumer(
              builder: (ctx, ref2, _) {
                final pendingAsync = ref2.watch(pendingWithdrawalsProvider);
                return pendingAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('${s.errorMsg}: $e', style: const TextStyle(color: AppColors.accent)),
                  data: (requests) => requests.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(s.isArabic ? 'لا توجد طلبات سحب معلقة ✨' : 'No pending withdrawals ✨'),
                          ),
                        )
                      : Column(
                          children: requests
                              .map((r) => _WithdrawalRequestAdminTile(
                                    request: r,
                                    onApprove: () async {
                                      await _processWithdrawal(
                                        context, ref2, r.id, 'approved');
                                    },
                                    onReject: () => _showRejectDialog(
                                        context, ref2, r.id),
                                  ))
                              .toList(),
                        ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Week Management ──
            Text(s.isArabic ? 'إدارة الأسابيع' : 'Weeks Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _AdminActionButton(
              icon: Icons.add_circle_outline,
              label: s.createWeek,
              color: AppColors.success,
              onTap: () => _showCreateWeekDialog(context, ref),
            ),
            const SizedBox(height: 24),

            // ── Reported Posts ──
            Text(s.reportedPosts,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Consumer(
              builder: (ctx, ref2, _) {
                final reportedAsync = ref2.watch(reportedPostsProvider);
                return reportedAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (posts) => posts.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(s.isArabic ? 'لا توجد منشورات مبلغ عنها 🎉' : 'No reported posts 🎉'),
                          ),
                        )
                      : Column(
                          children: posts
                              .map((p) => _ReportedPostTile(
                                    post: p,
                                    onBan: () => _banPost(context, ref2, p.id),
                                    onKeep: () => _keepPost(context, ref2, p.id),
                                  ))
                              .toList(),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callEdgeFunction(BuildContext context, WidgetRef ref, String fnName) async {
    final s = ref.read(appL10nProvider);
    try {
      await supabase.functions.invoke(fnName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.isArabic ? 'تم تنفيذ: $fnName' : 'Executed: $fnName')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.errorMsg}: $e')),
      );
    }
  }

  Future<void> _confirmAndCall(
      BuildContext context, WidgetRef ref, String fnName, String message) async {
    final s = ref.read(appL10nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirm),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _callEdgeFunction(context, ref, fnName);
    }
  }

  Future<void> _banPost(BuildContext context, WidgetRef ref, String postId) async {
    final s = ref.read(appL10nProvider);
    await supabase.from('posts').update({'is_active': false, 'is_reported': false}).eq('id', postId);
    ref.invalidate(reportedPostsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'تم حظر المنشور' : 'Post banned')));
  }

  Future<void> _keepPost(BuildContext context, WidgetRef ref, String postId) async {
    final s = ref.read(appL10nProvider);
    await supabase.from('posts').update({'is_reported': false}).eq('id', postId);
    ref.invalidate(reportedPostsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.isArabic ? 'تم الإبقاء على المنشور' : 'Post kept')));
  }

  Future<void> _showCreateWeekDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appL10nProvider);
    final now = DateTime.now();
    final start = now;
    final end   = now.add(const Duration(days: 6));
    final votingClose  = end.subtract(const Duration(hours: 24));
    final announcement = end.subtract(const Duration(hours: 4));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.createWeek),
        content: Text(
          s.isArabic ?
          'سيبدأ: ${start.toLocal()}\n'
          'ينتهي: ${end.toLocal()}\n'
          'إغلاق التصويت: ${votingClose.toLocal()}\n'
          'الإعلان: ${announcement.toLocal()}' :
          'Starts: ${start.toLocal()}\n'
          'Ends: ${end.toLocal()}\n'
          'Voting Closes: ${votingClose.toLocal()}\n'
          'Announcement: ${announcement.toLocal()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Get last week number
                final lastWeek = await supabase
                    .from('weeks')
                    .select('week_number')
                    .order('week_number', ascending: false)
                    .limit(1)
                    .maybeSingle();
                final nextNumber = (lastWeek?['week_number'] as int? ?? 0) + 1;

                await supabase.from('weeks').insert({
                  'week_number':      nextNumber,
                  'start_date':       start.toIso8601String(),
                  'end_date':         end.toIso8601String(),
                  'voting_closes_at': votingClose.toIso8601String(),
                  'announcement_at':  announcement.toIso8601String(),
                  'status':           'active',
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.isArabic ? 'تم إنشاء الأسبوع $nextNumber' : 'Week $nextNumber created')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${s.errorMsg}: $e')),
                );
              }
            },
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayoutDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appL10nProvider);
    final userIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isArabic ? 'سحب أرباح' : 'Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdCtrl,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: amountCtrl,
              decoration: InputDecoration(labelText: s.isArabic ? 'المبلغ (USD)' : 'Amount (USD)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (userIdCtrl.text.isEmpty || amount == null || amount <= 0) return;
              
              Navigator.pop(ctx);
              try {
                await supabase.functions.invoke('process_withdrawal', body: {
                  'target_user_id': userIdCtrl.text,
                  'amount_usd': amount,
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.isArabic ? 'تمت معالجة السحب بنجاح!' : 'Withdrawal processed successfully!')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${s.errorMsg}: $e')),
                );
              }
            },
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String status, {
    String? note,
  }) async {
    final s = ref.read(appL10nProvider);
    try {
      await ref.read(giftsRepositoryProvider).processWithdrawal(
        requestId: requestId,
        status: status,
        adminNote: note,
      );
      ref.invalidate(pendingWithdrawalsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? (s.isArabic ? '✅ تمت موافقة الطلب بنجاح' : '✅ Request approved') : (s.isArabic ? '❌ تم رفض الطلب' : '❌ Request rejected')),
          backgroundColor: status == 'approved' ? AppColors.success : AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.errorMsg}: $e'), backgroundColor: AppColors.accent),
      );
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    final s = ref.read(appL10nProvider);
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isArabic ? 'رفض طلب السحب' : 'Reject Withdrawal'),
        content: TextField(
          controller: noteCtrl,
          decoration: InputDecoration(
            labelText: s.isArabic ? 'سبب الرفض (اختياري)' : 'Rejection Reason (Optional)',
            hintText: s.isArabic ? 'مثلاً: بيانات غير صحيحة' : 'e.g. Invalid data',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(s.isArabic ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _processWithdrawal(
        context, ref, requestId, 'rejected',
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
    }
  }
}

// ── Admin Action Button ────────────────────────────────────────────────────
class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 14),
        ],
      ),
    ),
  );
}

// ── Reported Post Tile ─────────────────────────────────────────────────────
class _ReportedPostTile extends ConsumerWidget {
  final ReportedPost post;
  final VoidCallback onBan;
  final VoidCallback onKeep;

  const _ReportedPostTile({
    required this.post, required this.onBan, required this.onKeep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s.translateCategory(post.category),
                  style: const TextStyle(color: AppColors.accent, fontSize: 11)),
            ),
          ],
        ),
        if (post.caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(post.caption,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onKeep,
                icon: const Icon(Icons.check, size: 16),
                label: Text(s.keepPost),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                  minimumSize: const Size.fromHeight(36),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onBan,
                icon: const Icon(Icons.block, size: 16),
                label: Text(s.banPost),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(36),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}

// ── Withdrawal Request Admin Tile ──────────────────────────────────────────
class _WithdrawalRequestAdminTile extends ConsumerWidget {
  final WithdrawalRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _WithdrawalRequestAdminTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.person, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayName ?? request.username ?? request.userId.substring(0, 8),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '@${request.username ?? '—'}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${request.usdAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Details row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _InfoChip(label: '${request.crownsAmount} 🎟️'),
              _InfoChip(label: request.paymentMethodLabel),
              _InfoChip(label: request.paymentDetails),
            ],
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(s.isArabic ? 'رفض' : 'Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(38),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(s.isArabic ? 'موافقة' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(38),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
  );
}
