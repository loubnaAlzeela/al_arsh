/// LiveStreamModel — mirrors public.live_streams table
class LiveStreamModel {
  final String id;
  final String hostUserId;
  final String title;
  final bool isLive;
  final int viewerCount;
  final int peakViewers;
  final DateTime createdAt;
  final DateTime? endedAt;

  // Joined from users table
  final String? hostDisplayName;
  final String? hostAvatarUrl;
  final String? hostLevel;

  const LiveStreamModel({
    required this.id,
    required this.hostUserId,
    required this.title,
    required this.isLive,
    required this.viewerCount,
    required this.peakViewers,
    required this.createdAt,
    this.endedAt,
    this.hostDisplayName,
    this.hostAvatarUrl,
    this.hostLevel,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    final host = json['users'] as Map<String, dynamic>?;
    return LiveStreamModel(
      id:               json['id'] as String,
      hostUserId:       json['host_user_id'] as String,
      title:            json['title'] as String? ?? 'بث مباشر',
      isLive:           json['is_live'] as bool? ?? false,
      viewerCount:      json['viewer_count'] as int? ?? 0,
      peakViewers:      json['peak_viewers'] as int? ?? 0,
      createdAt:        DateTime.parse(json['created_at'] as String),
      endedAt:          json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : null,
      hostDisplayName:  host?['display_name'] as String?,
      hostAvatarUrl:    host?['avatar_url'] as String?,
      hostLevel:        host?['level'] as String?,
    );
  }

  /// Duration this stream has been live
  Duration get liveDuration => DateTime.now().difference(createdAt);
}

/// LiveMessageModel — mirrors public.live_messages table
class LiveMessageModel {
  final String id;
  final String streamId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String content;
  final DateTime createdAt;

  const LiveMessageModel({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory LiveMessageModel.fromJson(Map<String, dynamic> json) =>
      LiveMessageModel(
        id:           json['id'] as String,
        streamId:     json['stream_id'] as String,
        userId:       json['user_id'] as String,
        displayName:  json['display_name'] as String,
        avatarUrl:    json['avatar_url'] as String?,
        content:      json['content'] as String,
        createdAt:    DateTime.parse(json['created_at'] as String),
      );
}
