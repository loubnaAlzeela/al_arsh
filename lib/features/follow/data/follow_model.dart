/// FollowModel — mirrors public.follows table
class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  const FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) => FollowModel(
        id:          json['id'] as String,
        followerId:  json['follower_id'] as String,
        followingId: json['following_id'] as String,
        createdAt:   DateTime.parse(json['created_at'] as String),
      );
}
