import 'package:timeago/timeago.dart' as timeago;

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  
  // Joins from public.users table in Supabase
  final String username;
  final String displayName;
  final String? avatarUrl;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] ?? {};
    return CommentModel(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      username: user['username'] ?? 'مجهول',
      displayName: user['display_name'] ?? 'مستخدم',
      avatarUrl: user['avatar_url'],
    );
  }

  String get timeAgo => timeago.format(createdAt, locale: 'ar');
}
