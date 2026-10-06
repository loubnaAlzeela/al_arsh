class WalletModel {
  final String id;
  final String userId;
  final int balance;
  final double totalEarned;
  final double totalWithdrawn;
  final DateTime createdAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.createdAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    balance: json['balance'] as int? ?? 0,
    totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
    totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
