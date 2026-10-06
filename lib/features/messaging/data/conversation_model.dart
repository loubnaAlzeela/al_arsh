/// ConversationModel — mirrors public.conversations table
/// with other participant's info joined
class ConversationModel {
  final String id;
  final String participant1;
  final String participant2;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Other participant's data (joined)
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String? otherAvatarUrl;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.participant1,
    required this.participant2,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherDisplayName,
    this.otherAvatarUrl,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    required String myId,
    int unread = 0,
  }) {
    final p1 = json['participant_1'] as String;
    final p2 = json['participant_2'] as String;
    final isP1 = myId == p1;

    // The join returns user data under 'other_user' alias
    final otherData = json['other_user'] as Map<String, dynamic>? ?? {};

    return ConversationModel(
      id:            json['id'] as String,
      participant1:  p1,
      participant2:  p2,
      lastMessage:   json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt:     DateTime.parse(json['created_at'] as String),
      otherUserId:      isP1 ? p2 : p1,
      otherUsername:    otherData['username'] as String? ?? '',
      otherDisplayName: otherData['display_name'] as String? ?? '',
      otherAvatarUrl:   otherData['avatar_url'] as String?,
      unreadCount:      unread,
    );
  }
}
