/// PostModel — mirrors posts / posts_anonymous view
class PostModel {
  final String id;
  final String weekId;
  final String? userId;         // null during voting phase
  final String? username;       // null during voting phase
  final String? displayName;    // null during voting phase
  final String? avatarUrl;      // null during voting phase
  final String creatorLabel;    // 'منشئ #XXXX' always present
  final String contentType;     // video | image | text
  final String? contentUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String category;
  final int rawViews;
  final int rawLikes;
  final int rawComments;
  final int rawShares;
  final double normalizedScore;
  final bool isActive;
  final DateTime createdAt;
  final String tier;
  final String level;
  final String weekStatus;      // active | voting_closed | announced
  final int paidVotes;
  bool hasVoted;                // local state
  bool isLiked;                 // local state

  PostModel({
    required this.id,
    required this.weekId,
    this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.creatorLabel,
    required this.contentType,
    this.contentUrl,
    this.thumbnailUrl,
    this.caption,
    required this.category,
    required this.rawViews,
    required this.rawLikes,
    required this.rawComments,
    required this.rawShares,
    required this.normalizedScore,
    required this.isActive,
    required this.createdAt,
    required this.tier,
    required this.level,
    required this.weekStatus,
    this.paidVotes = 0,
    this.hasVoted = false,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id:             json['id'] as String,
    weekId:         json['week_id'] as String,
    userId:         json['user_id'] as String?,
    username:       json['username'] as String?,
    displayName:    json['display_name'] as String?,
    avatarUrl:      json['avatar_url'] as String?,
    creatorLabel:   json['creator_label'] as String? ?? 'منشئ #???',
    contentType:    json['content_type'] as String,
    contentUrl:     json['content_url'] as String?,
    thumbnailUrl:   json['thumbnail_url'] as String?,
    caption:        json['caption'] as String?,
    category:       json['category'] as String,
    rawViews:       json['raw_views'] as int? ?? 0,
    rawLikes:       json['raw_likes'] as int? ?? 0,
    rawComments:    json['raw_comments'] as int? ?? 0,
    rawShares:      json['raw_shares'] as int? ?? 0,
    normalizedScore:(json['normalized_score'] as num?)?.toDouble() ?? 0.0,
    isActive:       json['is_active'] as bool? ?? true,
    createdAt:      DateTime.parse(json['created_at'] as String),
    tier:           json['tier'] as String? ?? 'blue',
    level:          json['level'] as String? ?? 'مجهول',
    weekStatus:     json['week_status'] as String? ?? 'active',
    paidVotes:      json['paid_votes'] as int? ?? 0,
    isLiked:        json['is_liked'] as bool? ?? false,
  );

  bool get isRevealed => weekStatus == 'announced';

  PostModel copyWithVote() => PostModel(
    id: id, weekId: weekId, userId: userId, username: username,
    displayName: displayName, avatarUrl: avatarUrl,
    creatorLabel: creatorLabel, contentType: contentType,
    contentUrl: contentUrl, thumbnailUrl: thumbnailUrl,
    caption: caption, category: category,
    rawViews: rawViews, rawLikes: rawLikes,
    rawComments: rawComments, rawShares: rawShares,
    normalizedScore: normalizedScore, isActive: isActive,
    createdAt: createdAt, tier: tier, level: level,
    weekStatus: weekStatus, paidVotes: paidVotes, hasVoted: true, isLiked: isLiked,
  );

  PostModel copyWithLike(bool liked, int newLikeCount) => PostModel(
    id: id, weekId: weekId, userId: userId, username: username,
    displayName: displayName, avatarUrl: avatarUrl,
    creatorLabel: creatorLabel, contentType: contentType,
    contentUrl: contentUrl, thumbnailUrl: thumbnailUrl,
    caption: caption, category: category,
    rawViews: rawViews, rawLikes: newLikeCount,
    rawComments: rawComments, rawShares: rawShares,
    normalizedScore: normalizedScore, isActive: isActive,
    createdAt: createdAt, tier: tier, level: level,
    weekStatus: weekStatus, paidVotes: paidVotes, hasVoted: hasVoted, isLiked: liked,
  );

  PostModel copyWithComments(int newCommentCount) => PostModel(
    id: id, weekId: weekId, userId: userId, username: username,
    displayName: displayName, avatarUrl: avatarUrl,
    creatorLabel: creatorLabel, contentType: contentType,
    contentUrl: contentUrl, thumbnailUrl: thumbnailUrl,
    caption: caption, category: category,
    rawViews: rawViews, rawLikes: rawLikes,
    rawComments: newCommentCount, rawShares: rawShares,
    normalizedScore: normalizedScore, isActive: isActive,
    createdAt: createdAt, tier: tier, level: level,
    weekStatus: weekStatus, paidVotes: paidVotes, hasVoted: hasVoted, isLiked: isLiked,
  );

  PostModel copyWithView() => PostModel(
    id: id, weekId: weekId, userId: userId, username: username,
    displayName: displayName, avatarUrl: avatarUrl,
    creatorLabel: creatorLabel, contentType: contentType,
    contentUrl: contentUrl, thumbnailUrl: thumbnailUrl,
    caption: caption, category: category,
    rawViews: rawViews + 1, rawLikes: rawLikes,
    rawComments: rawComments, rawShares: rawShares,
    normalizedScore: normalizedScore, isActive: isActive,
    createdAt: createdAt, tier: tier, level: level,
    weekStatus: weekStatus, paidVotes: paidVotes, hasVoted: hasVoted, isLiked: isLiked,
  );
}
