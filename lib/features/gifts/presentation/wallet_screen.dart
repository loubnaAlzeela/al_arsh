import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../core/l10n/app_l10n.dart';
import '../data/gifts_repository.dart';
import '../data/transaction_model.dart';
import 'buy_crowns_sheet.dart';
import 'withdrawal_sheet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  void _refreshAll() {
    final session = supabase.auth.currentSession;
    if (session == null) return;
    ref.invalidate(walletProvider);
    ref.invalidate(transactionsProvider(session.user.id));
  }

  Future<void> _openBuySheet() async {
    await BuyCrownsSheet.show(context);
    // Refresh right after the sheet closes (Webhook may have arrived by now)
    _refreshAll();
  }

  Future<void> _openWithdrawalSheet(int balance) async {
    final success = await WithdrawalSheet.show(context, availableCrowns: balance);
    if (success == true) {
      _refreshAll();
      ref.invalidate(myWithdrawalsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appL10nProvider);
    final session = supabase.auth.currentSession;
    if (session == null) {
      return Scaffold(body: Center(child: Text(s.isArabic ? 'الرجاء تسجيل الدخول' : 'Please log in')));
    }

    final userId = session.user.id;
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.wallet),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.isArabic ? 'تحديث' : 'Refresh',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: walletAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('${s.errorMsg}: $e')),
                  data: (wallet) {
                    final balance = wallet?.balance ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.isArabic ? 'رصيد الأصوات' : 'Votes Balance',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                NumberFormat('#,###').format(balance),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('🎟️', style: TextStyle(fontSize: 32)),
                            ],
                          ),
                          if (balance >= 100) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s.isArabic ? 'رصيدك يكفي لإهداء: ${balance >= 5000 ? '${balance ~/ 5000} سيارة 🏎️' : balance >= 1000 ? '${balance ~/ 1000} ميكروفون 🎤' : balance >= 500 ? '${balance ~/ 500} باقة زهور 💐' : '${balance ~/ 100} فنجان قهوة ☕'}' :
                                'Balance enough to gift: ${balance >= 5000 ? '${balance ~/ 5000} Car 🏎️' : balance >= 1000 ? '${balance ~/ 1000} Mic 🎤' : balance >= 500 ? '${balance ~/ 500} Flowers 💐' : '${balance ~/ 100} Coffee ☕'}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _openBuySheet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryDark,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Text(s.isArabic ? 'شراء أصوات' : 'Buy Votes', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _openWithdrawalSheet(balance),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payments_outlined, size: 16),
                                      const SizedBox(width: 6),
                                      Text(s.isArabic ? 'سحب الأرباح' : 'Withdraw', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // ── Withdrawal Requests History ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  s.isArabic ? 'طلبات السحب' : 'Withdrawal Requests',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Consumer(
              builder: (ctx, r, _) {
                final requestsAsync = r.watch(myWithdrawalsProvider);
                return requestsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  data: (requests) => requests.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              s.isArabic ? 'لا توجد طلبات سحب' : 'No withdrawal requests',
                              style: const TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _WithdrawalRequestTile(request: requests[i]),
                            childCount: requests.length,
                          ),
                        ),
                );
              },
            ),

            // ── Transaction History ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  s.isArabic ? 'سجل المعاملات' : 'Transaction History',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            transactionsAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              )),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('${s.errorMsg}: $e'))),
              data: (transactions) => transactions.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(s.isArabic ? 'لا توجد معاملات بعد' : 'No transactions yet', style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TransactionTile(transaction: transactions[index]),
                        childCount: transactions.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Withdrawal Request Tile ─────────────────────────────────────────────────
class _WithdrawalRequestTile extends ConsumerWidget {
  final dynamic request;
  const _WithdrawalRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (request.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = s.isArabic ? 'مقبول' : 'Approved';
        break;
      case 'rejected':
        statusColor = AppColors.accent;
        statusIcon = Icons.cancel;
        statusLabel = s.isArabic ? 'مرفوض' : 'Rejected';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        statusLabel = s.isArabic ? 'قيد المراجعة' : 'Under Review';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      request.paymentMethodLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.crownsAmount} 🎟️  •  \$${request.usdAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (request.adminNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${s.isArabic ? 'ملاحظة:' : 'Note:'} ${request.adminNote}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
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

class _TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    IconData icon;
    Color iconColor;
    String title;
    String amountText;
    Color amountColor;

    switch (transaction.type) {
      case 'purchase':
        icon = Icons.how_to_vote;
        iconColor = AppColors.primary;
        title = s.isArabic ? 'شراء أصوات' : 'Buy Votes';
        amountText = '+${transaction.amount} 🎟️';
        amountColor = AppColors.success;
        break;
      case 'gift_sent':
        icon = Icons.how_to_vote;
        iconColor = AppColors.tierRed;
        title = s.isArabic ? 'تصويت لمنشور' : 'Vote on post';
        amountText = '${transaction.amount} 🎟️';
        amountColor = AppColors.accent;
        break;
      case 'gift_received':
        icon = Icons.star;
        iconColor = AppColors.success;
        title = s.isArabic ? 'تلقي تصويت' : 'Received vote';
        amountText = '+${transaction.amount} 🎟️';
        amountColor = AppColors.success;
        break;
      case 'withdrawal':
        icon = Icons.account_balance_wallet;
        iconColor = AppColors.tierBlue;
        title = s.isArabic ? 'سحب أرباح' : 'Withdrawal';
        amountText = '-\$${transaction.usdValue?.toStringAsFixed(2)}';
        amountColor = AppColors.textSecondary;
        break;
      default:
        icon = Icons.receipt;
        iconColor = AppColors.textHint;
        title = s.isArabic ? 'معاملة' : 'Transaction';
        amountText = '${transaction.amount} 🎟️';
        amountColor = Colors.white;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        timeago.format(transaction.createdAt, locale: 'ar'),
        style: const TextStyle(color: AppColors.textHint, fontSize: 12),
      ),
      trailing: Text(
        amountText,
        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
