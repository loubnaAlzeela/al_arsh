import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
import 'gift_model.dart';
import 'wallet_model.dart';
import 'transaction_model.dart';
import 'gift_package.dart';
import 'withdrawal_request_model.dart';
import '../presentation/gift_animation_overlay.dart';
import '../../../shared/providers/auth_provider.dart';

part 'gifts_repository.g.dart';

// ── Gifts Repository ────────────────────────────────────────────────────────
class GiftsRepository {
  final SupabaseClient _client;
  const GiftsRepository(this._client);

  /// Send a gift via Edge Function
  Future<void> sendGift({
    required String postId,
    required GiftPackage package,
  }) async {
    final response = await _client.functions.invoke(
      'send_gift',
      body: {
        'post_id': postId,
        'gift_type': package.id,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to send gift: ${response.data['error']}');
    }
  }

  /// Get sent and received gifts for a user
  Future<List<GiftModel>> getGiftsHistory(String userId) async {
    final data = await _client
        .from('gifts')
        .select('*')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(50);
        
    return (data as List).map((j) => GiftModel.fromJson(j)).toList();
  }

  /// Get transaction history
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
        
    return (data as List).map((j) => TransactionModel.fromJson(j)).toList();
  }

  /// Submit a withdrawal request
  Future<void> requestWithdrawal({
    required int crownsAmount,
    required double usdAmount,
    required String paymentMethod,
    required String paymentDetails,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('غير مسجّل الدخول');

    // Check no pending request exists
    final existing = await _client
        .from('withdrawal_requests')
        .select('id')
        .eq('user_id', session.user.id)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      throw Exception('لديك طلب سحب معلق بالفعل، يرجى الانتظار حتى تتم معالجته.');
    }

    await _client.from('withdrawal_requests').insert({
      'user_id': session.user.id,
      'crowns_amount': crownsAmount,
      'amount_usd': usdAmount,
      'payment_method': paymentMethod,
      'payment_details': paymentDetails,
      'status': 'pending',
    });
  }

  /// Get all pending withdrawal requests (admin only)
  Future<List<WithdrawalRequestModel>> getPendingWithdrawals() async {
    // Use the named FK constraint to force PostgREST to join with public.users
    // (FK was fixed in migration 20260706_fix_withdrawal_fk.sql)
    final data = await _client
        .from('withdrawal_requests')
        .select('*, users!withdrawal_requests_user_id_fkey(username, display_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List).map((j) => WithdrawalRequestModel.fromJson(j)).toList();
  }

  /// Approve or reject a withdrawal request (admin)
  Future<void> processWithdrawal({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    await _client.functions.invoke('process_withdrawal', body: {
      'request_id': requestId,
      'action': status == 'approved' ? 'approve' : 'reject',
      if (adminNote != null) 'admin_note': adminNote,
    });
  }

  /// Get withdrawal requests for the current user
  Future<List<WithdrawalRequestModel>> getMyWithdrawals() async {
    final session = _client.auth.currentSession;
    if (session == null) return [];
    final data = await _client
        .from('withdrawal_requests')
        .select('*, users!withdrawal_requests_user_id_fkey(username, display_name)')
        .eq('user_id', session.user.id)
        .order('created_at', ascending: false)
        .limit(20);
    return (data as List).map((j) => WithdrawalRequestModel.fromJson(j)).toList();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────
@riverpod
GiftsRepository giftsRepository(Ref ref) => GiftsRepository(supabase);

// Wallet Stream Provider
@riverpod
Stream<WalletModel?> wallet(Ref ref) {
  final session = supabase.auth.currentSession;
  if (session == null) return Stream.value(null);

  return supabase
      .from('wallets')
      .stream(primaryKey: ['id'])
      .eq('user_id', session.user.id)
      .map((events) => events.isEmpty ? null : WalletModel.fromJson(events.first));
}

// Gifts History Future Provider
@riverpod
Future<List<GiftModel>> giftsHistory(Ref ref, String userId) {
  return ref.read(giftsRepositoryProvider).getGiftsHistory(userId);
}

// Transactions History Future Provider
@riverpod
Future<List<TransactionModel>> transactions(Ref ref, String userId) {
  return ref.read(giftsRepositoryProvider).getTransactions(userId);
}

// Send Gift Async Notifier
@riverpod
class SendGiftNotifier extends _$SendGiftNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> sendGift(String postId, GiftPackage package) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(giftsRepositoryProvider).sendGift(
        postId: postId,
        package: package,
      );

      final senderName = ref.read(currentUserProvider).valueOrNull?.displayName ?? 'داعم';
      await broadcastGiftAnimation(
        postId: postId,
        emoji: package.emoji,
        giftName: package.name,
        senderName: senderName,
      );
    });
  }
}

// Withdrawal Request Notifier
@riverpod
class WithdrawalNotifier extends _$WithdrawalNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> request({
    required int crownsAmount,
    required double usdAmount,
    required String paymentMethod,
    required String paymentDetails,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(giftsRepositoryProvider).requestWithdrawal(
        crownsAmount: crownsAmount,
        usdAmount: usdAmount,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
      );
    });
    if (state.hasError) {
      throw state.error!;
    }
  }
}

// My Withdrawal Requests Provider
@riverpod
Future<List<WithdrawalRequestModel>> myWithdrawals(Ref ref) {
  return ref.read(giftsRepositoryProvider).getMyWithdrawals();
}

// Pending Withdrawals Provider (admin)
@riverpod
Future<List<WithdrawalRequestModel>> pendingWithdrawals(Ref ref) {
  return ref.read(giftsRepositoryProvider).getPendingWithdrawals();
}
