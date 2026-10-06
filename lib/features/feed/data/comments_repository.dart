import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
import 'comment_model.dart';

part 'comments_repository.g.dart';

class CommentsRepository {
  final SupabaseClient _client;
  const CommentsRepository(this._client);

  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _client
        .from('comments')
        .select('*, users!inner(username, display_name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);
        
    return (data as List).map((j) => CommentModel.fromJson(j)).toList();
  }

  Future<CommentModel> addComment(String postId, String content) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('يجب تسجيل الدخول لإضافة تعليق');

    final data = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': session.user.id,
          'content': content,
        })
        .select('*, users!inner(username, display_name, avatar_url)')
        .single();

    return CommentModel.fromJson(data);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }
}

@riverpod
CommentsRepository commentsRepository(Ref ref) => CommentsRepository(supabase);

@riverpod
class CommentsNotifier extends _$CommentsNotifier {
  @override
  Future<List<CommentModel>> build(String postId) async {
    return ref.read(commentsRepositoryProvider).getComments(postId);
  }

  Future<void> addComment(String content) async {
    final previous = state.valueOrNull ?? [];
    state = const AsyncLoading();
    try {
      final newComment = await ref.read(commentsRepositoryProvider).addComment(postId, content);
      state = AsyncData([newComment, ...previous]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteComment(String commentId) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((c) => c.id != commentId).toList());
    try {
      await ref.read(commentsRepositoryProvider).deleteComment(commentId);
    } catch (e) {
      // Revert on error
      state = AsyncData(previous);
      rethrow;
    }
  }
}
