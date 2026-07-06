import 'package:flutter/material.dart';

class AppTheme {
  // 1. Color Hierarchy (Modern Premium Dark Palette)
  static const Color primaryBackground = Color(0xFF0B1020);
  static const Color secondaryBackground = Color(0xFF141B2D);
  static const Color cardBackground = Color(0xFF1A2238);
  static const Color elevatedCardBackground = Color(0xFF232C45);

  static Color borderTranslucent = Colors.white.withValues(alpha: 0.08);
  static const Color borderFocused = Color(0xFF6366F1);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // 2. Primary Accent Color (Indigo & Purple)
  static const Color accentColor = Color(0xFF6366F1); // Indigo
  static const Color accentColorLight = Color(0xFF8B5CF6); // Purple

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentColor, accentColorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardBorderGradient = LinearGradient(
    colors: [Colors.white12, Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.2),
      blurRadius: 20,
      spreadRadius: 1,
    ),
  ];

  static double get cardRadius => 18.0;
  static double get pillRadius => 30.0;

  // Custom UI helpers for clean button/input consistency
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: borderTranslucent),
    boxShadow: cardShadow,
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: elevatedCardBackground,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: borderTranslucent),
    boxShadow: cardShadow,
  );
}
