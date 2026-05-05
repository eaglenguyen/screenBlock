import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.goldText,
      secondary: AppColors.goldDark,
      surface: AppColors.backgroundCard,
      error: AppColors.error,
    ),

    // ── AppBar ───────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: AppTextStyles.headlineSmall,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // ── ElevatedButton ───────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldText,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
        textStyle: AppTextStyles.labelLarge,
        elevation: 0,
      ),
    ),

    // ── OutlinedButton ───────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.border),
        textStyle: AppTextStyles.bodyLarge,
        elevation: 0,
      ),
    ),

    // ── Text ─────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge:   AppTextStyles.displayLarge,
      displayMedium:  AppTextStyles.displayMedium,
      headlineLarge:  AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall:  AppTextStyles.headlineSmall,
      bodyLarge:      AppTextStyles.bodyLarge,
      bodyMedium:     AppTextStyles.bodyMedium,
      bodySmall:      AppTextStyles.bodySmall,
      labelLarge:     AppTextStyles.labelLarge,
      labelMedium:    AppTextStyles.labelMedium,
      labelSmall:     AppTextStyles.labelSmall,
    ),

    // ── Divider ──────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
      space: 0,
    ),

    // ── Card ─────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.backgroundCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
  );
}