import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../features/auth/data/user_model.dart';

part 'auth_provider.g.dart';

// ── Auth State Stream ──────────────────────────────────────────────────────
@riverpod
Stream<AuthState> authState(Ref ref) {
  return supabase.auth.onAuthStateChange;
}

// ── Current Supabase Session ───────────────────────────────────────────────
@riverpod
Session? currentSession(Ref ref) {
  return supabase.auth.currentSession;
}

// ── Current User (from public.users table) ────────────────────────────────
@riverpod
class CurrentUser extends _$CurrentUser {
  @override
  Future<UserModel?> build() async {
    // Listen to auth state changes and rebuild
    ref.watch(authStateProvider);
    return _fetchCurrentUser();
  }

  Future<UserModel?> _fetchCurrentUser() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Call after profile setup to refresh the user data
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCurrentUser);
  }

  /// Update user profile fields
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null)   updates['avatar_url']   = avatarUrl;

    if (updates.isEmpty) return;

    await supabase
        .from('users')
        .update(updates)
        .eq('id', session.user.id);

    await refresh();
  }
}
