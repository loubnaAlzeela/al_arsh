class GiftModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String postId;
  final String giftType;
  final int crownsSpent;
  final int votesAdded;
  final int weekNumber;
  final DateTime createdAt;
  
  // Joined fields for display
  final String? senderName;
  final String? senderAvatar;

  const GiftModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.postId,
    required this.giftType,
    required this.crownsSpent,
    required this.votesAdded,
    required this.weekNumber,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    // Handle joins (e.g. users!sender_id(display_name, avatar_url))
    String? sName;
    String? sAvatar;
    
    if (json['users'] != null) {
      final userJson = json['users'];
      sName = userJson['display_name'] ?? userJson['username'];
      sAvatar = userJson['avatar_url'];
    }

    return GiftModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      postId: json['post_id'] as String,
      giftType: json['gift_type'] as String,
      crownsSpent: json['crowns_spent'] as int,
      votesAdded: json['votes_added'] as int,
      weekNumber: json['week_number'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: sName,
      senderAvatar: sAvatar,
    );
  }
}
