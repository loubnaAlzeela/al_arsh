/// MessageModel — mirrors public.messages table
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id:             json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId:       json['sender_id'] as String,
        content:        json['content'] as String,
        isRead:         json['is_read'] as bool? ?? false,
        createdAt:      DateTime.parse(json['created_at'] as String),
      );
}
