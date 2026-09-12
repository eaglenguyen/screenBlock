import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/accent_color_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme.notifier.dart';

class AccentColorSheet extends ConsumerWidget {
  const AccentColorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const AccentColorSheet(),
    );
  }

  static const _lightSwatches = {
    AccentColorOption.teal: Color(0xFFA8E6CE),
    AccentColorOption.pink: Color(0xFFF5B5C6),
    AccentColorOption.blue: Color(0xFFA8CFF0),
    AccentColorOption.peach: Color(0xFFF3C299),
    AccentColorOption.purple: Color(0xFFCBB8F0),
    AccentColorOption.gold: Color(0xFFFAE28E),
  };

  static const _lightLabels = {
    AccentColorOption.teal: 'Teal',
    AccentColorOption.pink: 'Pink',
    AccentColorOption.blue: 'Blue',
    AccentColorOption.peach: 'Peach',
    AccentColorOption.purple: 'Purple',
    AccentColorOption.gold: 'Gold',
  };

  static const _darkSwatches = { // 👈 new
    DarkAccentOption.warmGray: Color(0xFFC9BEBE),
    DarkAccentOption.coolGray: Color(0xFFB8C4C0),
    DarkAccentOption.cream: Color(0xFFD4CFC4),
    DarkAccentOption.white: Color(0xFFE8E8E8), // 👈 new

  };

  static const _darkLabels = { // 👈 new
    DarkAccentOption.warmGray: 'Warm Gray',
    DarkAccentOption.coolGray: 'Cool Gray',
    DarkAccentOption.cream: 'Cream',
    DarkAccentOption.white: 'White', // 👈 new

  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose an accent color',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isDark ? _buildDarkGrid(context, ref) : _buildLightGrid(context, ref), // 👈 new — branches per theme
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildLightGrid(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(accentColorProvider);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _lightSwatches.length,
      itemBuilder: (context, index) {
        final option = _lightSwatches.keys.elementAt(index);
        final color = _lightSwatches[option]!;
        final isSelected = selected == option;
        return _swatchTile(context, color, _lightLabels[option]!, isSelected, () {
          ref.read(accentColorProvider.notifier).setAccent(option);
        });
      },
    );
  }

  Widget _buildDarkGrid(BuildContext context, WidgetRef ref) { // 👈 new
    final selected = ref.watch(darkAccentColorProvider);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _darkSwatches.length,
      itemBuilder: (context, index) {
        final option = _darkSwatches.keys.elementAt(index);
        final color = _darkSwatches[option]!;
        final isSelected = selected == option;
        return _swatchTile(context, color, _darkLabels[option]!, isSelected, () {
          ref.read(darkAccentColorProvider.notifier).setAccent(option);
        });
      },
    );
  }

  Widget _swatchTile(BuildContext context, Color color, String label, bool isSelected, VoidCallback onTap) { // 👈 new — shared tile builder
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary(context) : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check_rounded, color: AppColors.accentText(context), size: 26)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}