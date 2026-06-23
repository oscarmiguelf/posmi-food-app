import 'package:flutter/material.dart';

/// Semantic color palette — each color has a fixed meaning across the system.
/// No decorative use. All combos meet WCAG AA contrast (4.5:1 text, 3:1 large).
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B4F72);
  static const Color primaryContent = Color(0xFFFFFFFF);

  // Semantic states
  static const Color success = Color(0xFF1E8449);
  static const Color successContent = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFB7770D);
  static const Color warningContent = Color(0xFF000000);
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerContent = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF1A5276);
  static const Color infoContent = Color(0xFFFFFFFF);

  // Surfaces
  static const Color background = Color(0xFFF4F6F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8EAEC);

  // Text
  static const Color textPrimary = Color(0xFF1C2833);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color textDisabled = Color(0xFFABB2B9);

  // Table status colors
  static const Color tableFree = Color(0xFF1E8449);
  static const Color tableOccupied = Color(0xFFC0392B);
  static const Color tableBillRequested = Color(0xFFB7770D);

  // Borders
  static const Color border = Color(0xFFD5D8DC);
}
