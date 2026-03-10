import 'package:flutter/material.dart';

/// Centralized color palette for ThExempt
class AppColors {
  AppColors._();

  // ─── Brand / Primary ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);       // Indigo-500
  static const Color primaryLight = Color(0xFF818CF8);  // Indigo-400
  static const Color primaryDark = Color(0xFF4F46E5);   // Indigo-600
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo-100

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFF8B5CF6);     // Violet-500
  static const Color secondaryLight = Color(0xFFA78BFA); // Violet-400
  static const Color secondaryDark = Color(0xFF7C3AED); // Violet-600

  // ─── Gradient ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF0F0FF), Color(0xFFF5F3FF), Color(0xFFF0F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);        // Emerald-500
  static const Color successLight = Color(0xFFD1FAE5);   // Emerald-100
  static const Color error = Color(0xFFEF4444);          // Red-500
  static const Color errorLight = Color(0xFFFEE2E2);     // Red-100
  static const Color warning = Color(0xFFF59E0B);        // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7);   // Amber-100
  static const Color info = Color(0xFF3B82F6);           // Blue-500
  static const Color infoLight = Color(0xFFDBEAFE);      // Blue-100

  // ─── Neutral / Greyscale ──────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ─── Backgrounds ─────────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFF9FAFB);

  // ─── Expertise category colors ────────────────────────────────────────────
  static const Color expertiseTechnical = Color(0xFF3B82F6);
  static const Color expertiseBusiness = Color(0xFF10B981);
  static const Color expertiseMarketing = Color(0xFFF59E0B);
  static const Color expertiseOperations = Color(0xFF8B5CF6);
  static const Color expertiseCreative = Color(0xFFEC4899);
  static const Color expertiseLegal = Color(0xFF6366F1);
  static const Color expertiseDomain = Color(0xFFEF4444);
  static const Color expertiseSoftSkills = Color(0xFF06B6D4);
}
