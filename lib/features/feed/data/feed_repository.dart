import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
import '../data/post_model.dart';

part 'feed_repository.g.dart';

// ── Feed Repository ────────────────────────────────────────────────────────
class FeedRepository {
  final SupabaseClient _client;
  const FeedRepository(this._client);

  /// Fetch paginated anonymous posts for a given week
  Future<List<PostModel>> getWeeklyFeed({
    required String weekId,
    required int page,
    int pageSize = 10,
    String? category,
  }) async {
    final from = page * pageSize;
    var query = _client
        .from('posts_anonymous')
        .select()
        .eq('week_id', weekId)
        .eq('is_active', true);

    if (category != null && category.isNotEmpty && category != 'الكل') {
      query = query.eq('category', category);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(from, from + pageSize - 1);

    return (data as List).map((j) => PostModel.fromJson(j)).toList();
  }

  /// Check if current user has already voted this week
  Future<Map<String, String>?> getMyVoteForWeek(String weekId) async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final result = await _client
        .from('votes')
        .select('post_id')
        .eq('voter_id', session.user.id)
        .eq('week_id', weekId)
        .maybeSingle();
    
    if (result == null) return null;
    final postId = result['post_id'] as String;

    // Fetch creatorLabel from posts_anonymous
    final postResult = await _client
        .from('posts_anonymous')
        .select('creator_label')
        .eq('id', postId)
        .maybeSingle();

    return {
      'post_id': postId,
      'creator_label': postResult?['creator_label'] as String? ?? '',
    };
  }

  /// Cast a vote for a post
  Future<void> castVote({
    required String postId,
    required String weekId,
  }) async {
    final session = _client.auth.currentSession!;
    final userId  = session.user.id;

    // Determine vote weight (0 if account < 48 hours)
    final createdAt = DateTime.parse(session.user.createdAt);
    final isOldEnough = DateTime.now().difference(createdAt).inHours >= 48;

    await _client.from('votes').insert({
      'voter_id': userId,
      'post_id':  postId,
      'week_id':  weekId,
      'weight':   isOldEnough ? 1 : 0,
      'voted_at': DateTime.now().toIso8601String(),
    });

    // Views are now recorded separately via recordView
  }

  /// Increment view count for a post using secure RPC
  Future<void> recordView(String postId, String viewerKey) async {
    await _client.rpc('record_view', params: {'p_post_id': postId, 'p_viewer_key': viewerKey});
  }

  /// Toggle like status
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final result = await _client.rpc('toggle_like', params: {'p_post_id': postId});
    return result as Map<String, dynamic>;
  }

  /// Get liked post IDs for current user
  Future<List<String>> getMyLikedPosts() async {
    final session = _client.auth.currentSession;
    if (session == null) return [];
    
    final result = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', session.user.id);
        
    return (result as List).map((e) => e['post_id'] as String).toList();
  }
}

// ── Feed Provider ──────────────────────────────────────────────────────────
@riverpod
FeedRepository feedRepository(Ref ref) => FeedRepository(supabase);

// ── Voted Post ID for current week ────────────────────────────────────────
@riverpod
Future<Map<String, String>?> myVoteForWeek(Ref ref, String weekId) {
  return ref.read(feedRepositoryProvider).getMyVoteForWeek(weekId);
}

// ── Feed State ─────────────────────────────────────────────────────────────
@riverpod
class FeedNotifier extends _$FeedNotifier {
  static const _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentWeekId;
  String? _currentCategory;

  @override
  Future<List<PostModel>> build() async {
    return [];
  }

  Future<void> loadFeed(String weekId, {String? category}) async {
    if (_currentWeekId != weekId || _currentCategory != category) {
      // New week or category — reset
      _currentWeekId = weekId;
      _currentCategory = category;
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncLoading();
    }

    List<PostModel> posts = await ref.read(feedRepositoryProvider).getWeeklyFeed(
      weekId: weekId,
      page: _currentPage,
      pageSize: _pageSize,
      category: _currentCategory,
    );

    // إضافة فيديوهات ثابتة إذا لم يكن هناك منشورات في التحميل الأول
    if (_currentPage == 0 && posts.isEmpty) {
      posts = [
        PostModel(
          id: 'static_1',
          weekId: weekId,
          creatorLabel: 'منشئ #1001',
          contentType: 'video',
          contentUrl: 'https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4',
          caption: 'مرحباً بك في التطبيق!',
          category: _currentCategory ?? 'الكل',
          rawViews: 1205, rawLikes: 342, rawComments: 24, rawShares: 12, normalizedScore: 0.8,
          isActive: true, createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          tier: 'blue', level: 'مجهول', weekStatus: 'active'
        ),
        PostModel(
          id: 'static_2',
          weekId: weekId,
          creatorLabel: 'منشئ #1002',
          contentType: 'video',
          contentUrl: 'https://storage.googleapis.com/exoplayer-test-media-1/mp4/android-screens-10s.mp4',
          caption: 'شارك فيديوهاتك الآن مع الآخرين 🚀',
          category: _currentCategory ?? 'الكل',
          rawViews: 856, rawLikes: 124, rawComments: 8, rawShares: 3, normalizedScore: 0.5,
          isActive: true, createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          tier: 'blue', level: 'مجهول', weekStatus: 'active'
        ),
        PostModel(
          id: 'static_3',
          weekId: weekId,
          creatorLabel: 'منشئ #1003',
          contentType: 'video',
          contentUrl: 'https://storage.googleapis.com/exoplayer-test-media-1/mp4/dizzy-with-tx3g.mp4',
          caption: 'استمتع بأفضل المحتوى الحصري',
          category: _currentCategory ?? 'الكل',
          rawViews: 2341, rawLikes: 890, rawComments: 56, rawShares: 45, normalizedScore: 0.95,
          isActive: true, createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          tier: 'blue', level: 'مجهول', weekStatus: 'active'
        ),
      ];
    }

    if (posts.length < _pageSize) _hasMore = false;
    _currentPage++;

    // Mark voted and liked post
    final votedInfo = await ref.read(feedRepositoryProvider).getMyVoteForWeek(weekId);
    final votedCreatorLabel = votedInfo?['creator_label'];
    
    final likedIds = await ref.read(feedRepositoryProvider).getMyLikedPosts();
    
    final withLocalState = posts.map((p) => PostModel(
      id: p.id, weekId: p.weekId, userId: p.userId,
      username: p.username, displayName: p.displayName,
      avatarUrl: p.avatarUrl, creatorLabel: p.creatorLabel,
      contentType: p.contentType, contentUrl: p.contentUrl,
      thumbnailUrl: p.thumbnailUrl, caption: p.caption,
      category: p.category, rawViews: p.rawViews,
      rawLikes: p.rawLikes, rawComments: p.rawComments,
      rawShares: p.rawShares, normalizedScore: p.normalizedScore,
      isActive: p.isActive, createdAt: p.createdAt,
      tier: p.tier, level: p.level, weekStatus: p.weekStatus,
      hasVoted: votedCreatorLabel != null && votedCreatorLabel.isNotEmpty && p.creatorLabel == votedCreatorLabel,
      isLiked: likedIds.contains(p.id),
    )).toList();

    final existing = state.valueOrNull ?? [];
    state = AsyncData([...existing, ...withLocalState]);
  }

  Future<void> refresh(String weekId) async {
    _currentWeekId = null;
    state = const AsyncData([]);
    await loadFeed(weekId, category: _currentCategory);
  }

  bool get hasMore => _hasMore;

  void updateVote(String creatorLabel) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData(
      posts.map((p) => p.creatorLabel == creatorLabel ? p.copyWithVote() : p).toList(),
    );
  }

  void updateLike(String postId, bool isLiked, int newLikeCount) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData(
      posts.map((p) => p.id == postId ? p.copyWithLike(isLiked, newLikeCount) : p).toList(),
    );
  }

  void updateCommentCount(String postId, int newCount) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData(
      posts.map((p) => p.id == postId ? p.copyWithComments(newCount) : p).toList(),
    );
  }
  
  void updateViewCount(String postId) {
    final posts = state.valueOrNull;
    if (posts == null) return;
    state = AsyncData(
      posts.map((p) => p.id == postId ? p.copyWithView() : p).toList(),
    );
  }
  
  void setCategory(String weekId, String? category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    _currentWeekId = null; // force reload
    state = const AsyncData([]);
    loadFeed(weekId, category: category);
  }
  
  String? get currentCategory => _currentCategory;
}
