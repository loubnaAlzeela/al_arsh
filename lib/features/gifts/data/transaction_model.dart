class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'purchase', 'gift_sent', 'gift_received', 'withdrawal'
  final int amount; // in crowns
  final double? usdValue;
  final String? referenceId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.usdValue,
    this.referenceId,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    type: json['type'] as String,
    amount: json['amount'] as int? ?? 0,
    usdValue: (json['usd_value'] as num?)?.toDouble(),
    referenceId: json['reference_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
