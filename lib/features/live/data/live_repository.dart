import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import 'live_stream_model.dart';

// ── Active Streams List (Realtime) ─────────────────────────────────────────
final liveStreamsProvider = StreamProvider.autoDispose<List<LiveStreamModel>>((ref) {
  return supabase
      .from('live_streams')
      .stream(primaryKey: ['id'])
      .eq('is_live', true)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((r) => LiveStreamModel.fromJson(r)).toList());
});

// ── Stream Detail (single stream) ─────────────────────────────────────────
final liveStreamDetailProvider =
    StreamProvider.autoDispose.family<LiveStreamModel?, String>((ref, streamId) {
  return supabase
      .from('live_streams')
      .stream(primaryKey: ['id'])
      .eq('id', streamId)
      .map((rows) {
        if (rows.isEmpty) return null;
        return LiveStreamModel.fromJson(rows.first);
      });
});

// ── Live Messages Stream ───────────────────────────────────────────────────
final liveMessagesProvider =
    StreamProvider.autoDispose.family<List<LiveMessageModel>, String>((ref, streamId) {
  return supabase
      .from('live_messages')
      .stream(primaryKey: ['id'])
      .eq('stream_id', streamId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map((r) => LiveMessageModel.fromJson(r)).toList());
});

// ── Viewer Count Notifier ──────────────────────────────────────────────────
final viewerCountProvider =
    StateProvider.autoDispose.family<int, String>((ref, streamId) => 0);

// ── Live Repository Actions ────────────────────────────────────────────────
class LiveRepository {
  /// Start a new live stream (red-tier only — also enforced by RLS)
  static Future<String> startStream({required String title}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('غير مسجل الدخول');

    final result = await supabase
        .from('live_streams')
        .insert({
          'host_user_id': userId,
          'title': title.trim().isEmpty ? 'بث مباشر' : title.trim(),
          'is_live': true,
        })
        .select('id')
        .single();

    return result['id'] as String;
  }

  /// End the stream (host only)
  static Future<void> endStream(String streamId) async {
    await supabase
        .from('live_streams')
        .update({
          'is_live': false,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', streamId);
  }

  /// Send a chat message
  static Future<void> sendMessage({
    required String streamId,
    required String content,
    required String displayName,
    String? avatarUrl,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('غير مسجل الدخول');
    if (content.trim().isEmpty) return;

    await supabase.from('live_messages').insert({
      'stream_id':    streamId,
      'user_id':      userId,
      'display_name': displayName,
      'avatar_url':   avatarUrl,
      'content':      content.trim(),
    });
  }

  /// Fetch host info enriched stream
  static Future<LiveStreamModel?> fetchStreamWithHost(String streamId) async {
    final data = await supabase
        .from('live_streams')
        .select('*, users!host_user_id(display_name, avatar_url, level)')
        .eq('id', streamId)
        .maybeSingle();
    if (data == null) return null;
    return LiveStreamModel.fromJson(data);
  }

  /// Fetch active streams with host info
  static Future<List<LiveStreamModel>> fetchActiveStreams() async {
    final data = await supabase
        .from('live_streams')
        .select('*, users!host_user_id(display_name, avatar_url, level)')
        .eq('is_live', true)
        .order('created_at', ascending: false);
    return (data as List).map((r) => LiveStreamModel.fromJson(r)).toList();
  }
}
