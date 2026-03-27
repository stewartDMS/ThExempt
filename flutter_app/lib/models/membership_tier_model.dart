import 'package:flutter/material.dart';

class MembershipTier {
  final String id;
  final String name;
  final String slug;
  final double priceMonthly;
  final double priceAnnual;
  final String? description;
  final List<String> features;
  final String badgeColor;
  final bool isActive;
  final int sortOrder;

  MembershipTier({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceMonthly,
    required this.priceAnnual,
    this.description,
    required this.features,
    required this.badgeColor,
    required this.isActive,
    required this.sortOrder,
  });

  factory MembershipTier.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final featureList = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : <String>[];
    return MembershipTier(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0.0,
      priceAnnual: (json['price_annual'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      features: featureList,
      badgeColor: json['badge_color'] as String? ?? '#0A66C2',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'price_monthly': priceMonthly,
        'price_annual': priceAnnual,
        if (description != null) 'description': description,
        'features': features,
        'badge_color': badgeColor,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  /// Parses badgeColor hex string (e.g. '#0A66C2') into a Flutter [Color].
  Color get color {
    try {
      final hex = badgeColor.replaceAll('#', '');
      if (hex.length != 6 && hex.length != 8) {
        return const Color(0xFF0A66C2);
      }
      final value = int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      return Color(value);
    } catch (_) {
      return const Color(0xFF0A66C2);
    }
  }
}
