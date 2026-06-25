import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────
  static Color background(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F0);

  static Color backgroundCard(BuildContext context) =>
      _isDark(context) ? const Color(0xFF252525) : const Color(0xFFFFFFFF);

  static Color backgroundSubtle(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2E2E2E) : const Color(0xFFEEEDE8);

  static Color backgroundOverlay(BuildContext context) =>
      _isDark(context) ? const Color(0xFF333333) : const Color(0xFFE5E4DF);

  // ── Gold / Primary ─────────────────────────────
  static Color gold(BuildContext context) => const Color(0xFFEDB82A);

  static Color goldDark(BuildContext context) => const Color(0xFFC49420);

  static Color goldText(BuildContext context) => const Color(0xFF1A1208);

  static Color primarySubtle(BuildContext context) =>
      const Color(0xFFEDB82A).withValues(alpha: 0.15);

  // ── Text ───────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9A9A9A) : const Color(0xFF666666);

  static Color textHint(BuildContext context) =>
      _isDark(context) ? const Color(0xFF444466) : const Color(0xFFAAAAAA);

  // ── Borders / Dividers ─────────────────────────
  static Color border(BuildContext context) =>
      _isDark(context) ? const Color(0xFF333333) : const Color(0xFFDDDDD8);

  static Color borderSubtle(BuildContext context) =>
      _isDark(context) ? const Color(0xFF23233D) : const Color(0xFFE8E8E3);

  // ── Semantic ───────────────────────────────────
  static Color success(BuildContext context) => const Color(0xFF2ECC71);
  static Color error(BuildContext context) => const Color(0xFFE74C3C);
  static Color warning(BuildContext context) => const Color(0xFFEDB82A);
  static Color pause(BuildContext context) => Colors.orange;

  static const Color faint = Color(0xFF2A2A48);

  // ── Helper ─────────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}