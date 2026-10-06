import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../features/rankings/data/week_model.dart';

part 'current_week_provider.g.dart';

// ── Current Active Week ────────────────────────────────────────────────────
@riverpod
class CurrentWeek extends _$CurrentWeek {
  RealtimeChannel? _channel;

  @override
  Future<WeekModel?> build() async {
    // Subscribe to realtime updates on weeks table
    _channel = supabase
        .channel('public:weeks')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'weeks',
          callback: (payload) {
            // Refresh when week status changes
            ref.invalidateSelf();
          },
        )
        .subscribe();

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return _fetchCurrentWeek();
  }

  Future<WeekModel?> _fetchCurrentWeek() async {
    // First, try to find an active or voting_closed week
    final data = await supabase
        .from('weeks')
        .select()
        .inFilter('status', ['active', 'voting_closed'])
        .order('week_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null) return WeekModel.fromJson(data);

    // No active week found — call ensure_active_week to create one,
    // then return the latest announced week in the meantime.
    try {
      await supabase.rpc('ensure_active_week');
    } catch (_) {}

    // Re-fetch after attempting to create
    final refetch = await supabase
        .from('weeks')
        .select()
        .inFilter('status', ['active', 'voting_closed'])
        .order('week_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (refetch != null) return WeekModel.fromJson(refetch);

    // Still nothing — return the most recent announced week as a fallback
    final announced = await supabase
        .from('weeks')
        .select()
        .eq('status', 'announced')
        .order('week_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (announced == null) return null;
    return WeekModel.fromJson(announced);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCurrentWeek);
  }
}

// ── Unread Notifications Count ─────────────────────────────────────────────
@riverpod
class UnreadNotificationsCount extends _$UnreadNotificationsCount {
  RealtimeChannel? _channel;

  @override
  Future<int> build() async {
    final session = supabase.auth.currentSession;
    if (session == null) return 0;

    _channel = supabase
        .channel('public:notifications:${session.user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: session.user.id,
          ),
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    return _fetchCount(session.user.id);
  }

  Future<int> _fetchCount(String userId) async {
    final result = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);
    return result.count;
  }
}
