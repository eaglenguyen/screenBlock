import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge:   AppTextStyles.displayLarge.copyWith(color: primary),
        displayMedium:  AppTextStyles.displayMedium.copyWith(color: primary),
        headlineLarge:  AppTextStyles.headlineLarge.copyWith(color: primary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
        headlineSmall:  AppTextStyles.headlineSmall.copyWith(color: primary),
        bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: primary),
        bodyMedium:     AppTextStyles.bodyMedium.copyWith(color: secondary),
        bodySmall:      AppTextStyles.bodySmall.copyWith(color: secondary),
        labelLarge:     AppTextStyles.labelLarge.copyWith(color: primary),
        labelMedium:    AppTextStyles.labelMedium.copyWith(color: primary),
        labelSmall:     AppTextStyles.labelSmall.copyWith(color: secondary),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFEDB82A),
        onPrimary: Color(0xFF1A1208),
        secondary: Color(0xFFC49420),
        surface: Color(0xFF252525),
        error: Color(0xFFE74C3C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEDB82A),
          foregroundColor: const Color(0xFF1A1208),
          minimumSize: const Size(double.infinity, 54),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: AppTextStyles.labelLarge.fontSize,
            fontWeight: AppTextStyles.labelLarge.fontWeight,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(double.infinity, 54),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFF333333)),
          textStyle: GoogleFonts.poppins(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: AppTextStyles.bodyLarge.fontWeight,
          ),
          elevation: 0,
        ),
      ),
      textTheme: _buildTextTheme(
        const Color(0xFFFFFFFF),
        const Color(0xFF9A9A9A),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 0.5,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252525),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF333333), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFEDB82A),
        onPrimary: Color(0xFF1A1208),
        secondary: Color(0xFFC49420),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFE74C3C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F0),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEDB82A),
          foregroundColor: const Color(0xFF1A1208),
          minimumSize: const Size(double.infinity, 54),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: AppTextStyles.labelLarge.fontSize,
            fontWeight: AppTextStyles.labelLarge.fontWeight,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          minimumSize: const Size(double.infinity, 54),
          shape: const StadiumBorder(),
          side: const BorderSide(color: Color(0xFFDDDDD8)),
          textStyle: GoogleFonts.poppins(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: AppTextStyles.bodyLarge.fontWeight,
          ),
          elevation: 0,
        ),
      ),
      textTheme: _buildTextTheme(
        const Color(0xFF1A1A1A),
        const Color(0xFF666666),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDDDD8),
        thickness: 0.5,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDDDDD8), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}