import 'package:flutter/material.dart';

class CreditTransaction {
  final String id;
  final String userId;
  final int amount;
  final String transactionType;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    this.description,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      transactionType: json['transaction_type'] as String? ?? 'earn',
      description: json['description'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'transaction_type': transactionType,
        if (description != null) 'description': description,
        if (referenceType != null) 'reference_type': referenceType,
        if (referenceId != null) 'reference_id': referenceId,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isCredit => amount > 0;

  IconData get icon {
    switch (transactionType) {
      case 'earn':
        return Icons.star_outline;
      case 'spend':
        return Icons.shopping_bag_outlined;
      case 'purchase':
        return Icons.credit_card_outlined;
      case 'refund':
        return Icons.undo_outlined;
      case 'invest':
        return Icons.trending_up_outlined;
      case 'receive_investment':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.swap_horiz_outlined;
    }
  }
}
