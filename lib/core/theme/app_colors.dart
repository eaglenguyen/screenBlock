import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────
  static Color background(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFFFF7ED);

  static Color backgroundCard(BuildContext context) =>
      _isDark(context) ? const Color(0xFF252525) : const Color(0xFFFFFFFF);

  static Color backgroundSubtle(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2E2E2E) : const Color(0xFFFFF0DA);

  static Color backgroundOverlay(BuildContext context) =>
      _isDark(context) ? const Color(0xFF333333) : const Color(0xFFFFE8B8);

  // ──  Primary ─────────────────────────────
  static Color accent(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD4CFC4) : const Color(0xFF7DD3B0);

  static Color accentDark(BuildContext context) =>
      _isDark(context) ? const Color(0xFFA8A296) : const Color(0xFF2D7A54);

  static Color accentText(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFF0F4A32);

  static Color primarySubtle(BuildContext context) =>
      accent(context).withValues(alpha: 0.15);

// ── Extra pastel accents (light mode variety) ──
  static Color accentPink(BuildContext context) =>
      _isDark(context) ? const Color(0xFFE1306C) : const Color(0xFFFFE1EC);
  static Color accentPinkText(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFFC2478B);

  static Color accentBlue(BuildContext context) =>
      _isDark(context) ? const Color(0xFF3D6FBF) : const Color(0xFFDCEBFF);
  static Color accentBlueText(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF3D6FBF);

  static Color accentPeach(BuildContext context) =>
      _isDark(context) ? const Color(0xFFEDB8A0) : const Color(0xFFFFE8B8);
  static Color accentPeachText(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFFB07A1E);

// in AppColors
  static Color cardLip(BuildContext context) =>
      _isDark(context) ? const Color(0xFF141414) : const Color(0xFFE8DFD0);
  // ── Text ───────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFFFFFFF) : const Color(0xFF4A3728);

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9A9A9A) : const Color(0xFFB08A5A);

  static Color textHint(BuildContext context) =>
      _isDark(context) ? const Color(0xFF444466) : const Color(0xFFD9C7B0);

  // ── Borders / Dividers ─────────────────────────
  static Color border(BuildContext context) =>
      _isDark(context) ? const Color(0xFF333333) : const Color(0xFFF0E6D8);

  static Color borderSubtle(BuildContext context) =>
      _isDark(context) ? const Color(0xFF23233D) : const Color(0xFFF5EEE2);

  // ── Semantic ───────────────────────────────────
  static Color success(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2ECC71) : const Color(0xFF7DD3B0);

  static Color error(BuildContext context) =>
      _isDark(context) ? const Color(0xFFE74C3C) : const Color(0xFFE8899E);

  static Color warning(BuildContext context) =>
      _isDark(context) ? const Color(0xFFD4CFC4) : const Color(0xFFEDB8A0);

  static Color warningDark(BuildContext context) =>
      _isDark(context) ? const Color(0xFFA8A296) : const Color(0xFFD98F6E);

  static Color warningLight(BuildContext context) =>
      _isDark(context) ? const Color(0xFFEAE6DE) : const Color(0xFFFFE0D0);

  static Color pause(BuildContext context) => Colors.orange;

  static const Color faint = Color(0xFF2A2A48);

  // ── Helper ─────────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}