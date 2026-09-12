import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static AccentColorOption selectedAccent = AccentColorOption.teal; // 👈 light mode selection
  static DarkAccentOption selectedDarkAccent = DarkAccentOption.warmGray; // 👈 new — dark mode selection

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
  static const Map<AccentColorOption, Color> _accentLight = {
    AccentColorOption.teal: Color(0xFFA8E6CE),
    AccentColorOption.pink: Color(0xFFF5B5C6),
    AccentColorOption.blue: Color(0xFFA8CFF0),
    AccentColorOption.peach: Color(0xFFF3C299),
    AccentColorOption.purple: Color(0xFFCBB8F0),
    AccentColorOption.gold: Color(0xFFFAE28E),
  };

  static const Map<AccentColorOption, Color> _accentDarkLight = {
    AccentColorOption.teal: Color(0xFF2D7A54),
    AccentColorOption.pink: Color(0xFFB2455F),
    AccentColorOption.blue: Color(0xFF2D5F8A),
    AccentColorOption.peach: Color(0xFF9A5A2E),
    AccentColorOption.purple: Color(0xFF5C3F94),
    AccentColorOption.gold: Color(0xFF8A6A1A),
  };

  static const Map<AccentColorOption, Color> _accentTextLight = {
    AccentColorOption.teal: Color(0xFF0F4A32),
    AccentColorOption.pink: Color(0xFF5C1F2E),
    AccentColorOption.blue: Color(0xFF1A3A5C),
    AccentColorOption.peach: Color(0xFF4A2E14),
    AccentColorOption.purple: Color(0xFF2E1F4A),
    AccentColorOption.gold: Color(0xFF3D2E00),
  };

  // 👇 new — the 3 independent dark-mode neutral options
  static const Map<DarkAccentOption, Color> _accentDarkModeColors = {
    DarkAccentOption.warmGray: Color(0xFFC9BEBE),
    DarkAccentOption.coolGray: Color(0xFFB8C4C0),
    DarkAccentOption.cream: Color(0xFFD4CFC4),
    DarkAccentOption.white: Color(0xFFE8E8E8), // 👈 new — close to white70, slightly off-white for a bit of softness

  };

  static const Map<DarkAccentOption, Color> _accentDarkModeSecondary = {
    DarkAccentOption.warmGray: Color(0xFFA8A296),
    DarkAccentOption.coolGray: Color(0xFF9AA6A2),
    DarkAccentOption.cream: Color(0xFFA8A296),
    DarkAccentOption.white: Color(0xFFE8E8E8), // 👈 new — close to white70, slightly off-white for a bit of softness

  };

  static Color accent(BuildContext context) => _isDark(context)
      ? (_accentDarkModeColors[selectedDarkAccent] ?? _accentDarkModeColors[DarkAccentOption.warmGray]!)
      : (_accentLight[selectedAccent] ?? _accentLight[AccentColorOption.teal]!);

  static Color accentDark(BuildContext context) => _isDark(context)
      ? (_accentDarkModeSecondary[selectedDarkAccent] ?? _accentDarkModeSecondary[DarkAccentOption.warmGray]!)
      : (_accentDarkLight[selectedAccent] ?? _accentDarkLight[AccentColorOption.teal]!);

  static Color accentText(BuildContext context) => _isDark(context)
      ? const Color(0xFF1A1A1A) // all 3 dark-mode neutrals are light enough to always pair with dark text
      : (_accentTextLight[selectedAccent] ?? _accentTextLight[AccentColorOption.teal]!);

  static Color primarySubtle(BuildContext context) =>
      accent(context).withValues(alpha: 0.15);

  // ── Extra pastel accents (light mode variety) ── — unchanged
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

enum AccentColorOption {
  teal('teal'),
  pink('pink'),
  blue('blue'),
  peach('peach'),
  purple('purple'),
  gold('gold');

  final String id;
  const AccentColorOption(this.id);

  static AccentColorOption fromId(String id) =>
      AccentColorOption.values.firstWhere((o) => o.id == id, orElse: () => AccentColorOption.teal);
}

enum DarkAccentOption { // 👈 new
  warmGray('dark_warm_gray'),
  coolGray('dark_cool_gray'),
  cream('dark_cream'),
  white('dark_white'); // 👈 new


  final String id;
  const DarkAccentOption(this.id);

  static DarkAccentOption fromId(String id) =>
      DarkAccentOption.values.firstWhere((o) => o.id == id, orElse: () => DarkAccentOption.warmGray);
}