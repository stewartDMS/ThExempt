import 'package:flutter/material.dart';

/// Centralized color palette for ThExempt – movement-first changemaker platform.
///
/// Primary brand palette is sourced from the public landing page design system
/// (landing_page/tailwind.config.ts).  The in-app palette maps semantic roles
/// to the brand colors while keeping sufficient contrast for readability.
class AppColors {
  AppColors._();

  // ─── ThExempt Brand Palette ───────────────────────────────────────────────
  /// Urgent action, passion – used on hero gradients and accent moments.
  static const Color deepRed = Color(0xFFD32F2F);

  /// Strength, seriousness – primary background for dark sections.
  static const Color charcoal = Color(0xFF212121);

  /// Innovation, intelligence – primary interactive color.
  static const Color electricBlue = Color(0xFF1976D2);

  /// Energy, disruption – high-visibility accent on light backgrounds.
  static const Color rebellionOrange = Color(0xFFFF6F00);

  /// Growth, sustainability – positive / success states.
  static const Color forestGreen = Color(0xFF2E7D32);

  /// Industrial, serious – secondary dark surfaces.
  static const Color steelGray = Color(0xFF455A64);

  /// Progress, technology – highlight / info accent.
  static const Color brightCyan = Color(0xFF00BCD4);

  /// Optimism, warning – caution / warm accent.
  static const Color warmAmber = Color(0xFFFFA000);

  // ─── Brand / Primary ──────────────────────────────────────────────────────
  static const Color primary = electricBlue;                 // #1976D2
  static const Color primaryLight = brightCyan;              // #00BCD4
  static const Color primaryDark = charcoal;                 // #212121
  static const Color primaryContainer = Color(0xFFE3F2FD);   // Material blue-50

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  static const Color secondary = deepRed;                    // #D32F2F
  static const Color secondaryLight = Color(0xFFEF9A9A);     // Red-200
  static const Color secondaryDark = Color(0xFFB71C1C);      // Red-900

  // ─── Gradients ────────────────────────────────────────────────────────────
  /// Used on hero + CTA sections throughout the app.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [charcoal, steelGray, deepRed],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, brightCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF3F2EF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = forestGreen;              // #2E7D32
  static const Color successLight = Color(0xFFC8E6C9);   // Green-100
  static const Color error = deepRed;                    // #D32F2F
  static const Color errorLight = Color(0xFFFFCDD2);     // Red-100
  static const Color warning = warmAmber;                // #FFA000
  static const Color warningLight = Color(0xFFFFF8E1);   // Amber-50
  static const Color info = electricBlue;                // #1976D2
  static const Color infoLight = Color(0xFFE3F2FD);      // Blue-50

  // ─── Neutral / Greyscale ──────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F2EF);
  static const Color grey200 = Color(0xFFE0E0E0);
  static const Color grey300 = Color(0xFFBDBDBD);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey500 = Color(0xFF666666);
  static const Color grey600 = Color(0xFF4D4D4D);
  static const Color grey700 = Color(0xFF333333);
  static const Color grey800 = Color(0xFF1D1D1D);
  static const Color grey900 = Color(0xFF0A0A0A);

  // ─── Backgrounds ──────────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF3F2EF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFFFFFFF);

  // ─── Dark surface backgrounds (used in landing page sections) ─────────────
  static const Color darkSurface = charcoal;             // #212121
  static const Color darkSurface2 = steelGray;           // #455A64

  // ─── Borders / Dividers ──────────────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ─── Expertise category colors ────────────────────────────────────────────
  static const Color expertiseTechnical = electricBlue;
  static const Color expertiseBusiness = forestGreen;
  static const Color expertiseMarketing = rebellionOrange;
  static const Color expertiseOperations = Color(0xFF7B61FF);
  static const Color expertiseCreative = Color(0xFFE91E8C);
  static const Color expertiseLegal = electricBlue;
  static const Color expertiseDomain = deepRed;
  static const Color expertiseSoftSkills = brightCyan;
}
