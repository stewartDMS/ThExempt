import 'package:flutter/material.dart';

/// Centralized color palette for ThExempt – LinkedIn/professional aesthetic
class AppColors {
  AppColors._();

  // ─── Brand / Primary (LinkedIn blue) ─────────────────────────────────────
  static const Color primary = Color(0xFF0A66C2);       // LinkedIn blue
  static const Color primaryLight = Color(0xFF378FE9);  // Lighter blue
  static const Color primaryDark = Color(0xFF004182);   // Darker blue
  static const Color primaryContainer = Color(0xFFDEEBFF); // Light blue tint

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFF0073B1);     // LinkedIn secondary
  static const Color secondaryLight = Color(0xFF4A9FD4);
  static const Color secondaryDark = Color(0xFF005582);

  // ─── Gradient ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF3F2EF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF057642);        // LinkedIn green
  static const Color successLight = Color(0xFFD4EDDA);
  static const Color error = Color(0xFFCC1016);          // Professional red
  static const Color errorLight = Color(0xFFFCE8E9);
  static const Color warning = Color(0xFFF5A623);        // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0A66C2);           // Same as primary
  static const Color infoLight = Color(0xFFDEEBFF);

  // ─── Neutral / Greyscale ──────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F2EF);        // LinkedIn off-white
  static const Color grey200 = Color(0xFFE0E0E0);        // LinkedIn border
  static const Color grey300 = Color(0xFFBDBDBD);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey500 = Color(0xFF666666);        // LinkedIn secondary text
  static const Color grey600 = Color(0xFF4D4D4D);
  static const Color grey700 = Color(0xFF333333);
  static const Color grey800 = Color(0xFF1D1D1D);
  static const Color grey900 = Color(0xFF000000);        // Alpha 0.9

  // ─── Backgrounds ─────────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF3F2EF); // LinkedIn off-white
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFFFFFFF);

  // ─── Borders / Dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ─── Expertise category colors ────────────────────────────────────────────
  static const Color expertiseTechnical = Color(0xFF0A66C2);
  static const Color expertiseBusiness = Color(0xFF057642);
  static const Color expertiseMarketing = Color(0xFFF5A623);
  static const Color expertiseOperations = Color(0xFF7B61FF);
  static const Color expertiseCreative = Color(0xFFE91E8C);
  static const Color expertiseLegal = Color(0xFF0A66C2);
  static const Color expertiseDomain = Color(0xFFCC1016);
  static const Color expertiseSoftSkills = Color(0xFF0288D1);
}
