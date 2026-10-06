class WithdrawalRequestModel {
  final String id;
  final String userId;
  final String? username;
  final String? displayName;
  final int crownsAmount;
  final double usdAmount;
  final String paymentMethod; // 'paypal', 'bank', 'vodafone_cash', 'instapay'
  final String paymentDetails; // account/number
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WithdrawalRequestModel({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    required this.crownsAmount,
    required this.usdAmount,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return WithdrawalRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: user?['username'] as String?,
      displayName: user?['display_name'] as String?,
      crownsAmount: json['crowns_amount'] as int? ?? 0,
      usdAmount: (json['amount_usd'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentDetails: json['payment_details'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
    );
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'paypal':
        return 'PayPal';
      case 'bank':
        return 'تحويل بنكي';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'إنستاباي';
      default:
        return paymentMethod;
    }
  }
}
