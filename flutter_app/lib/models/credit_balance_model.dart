class CreditBalance {
  final String id;
  final String userId;
  final int balance;
  final DateTime updatedAt;

  CreditBalance({
    required this.id,
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory CreditBalance.fromJson(Map<String, dynamic> json) {
    return CreditBalance(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'balance': balance,
        'updated_at': updatedAt.toIso8601String(),
      };
}
