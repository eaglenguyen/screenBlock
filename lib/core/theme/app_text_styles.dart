import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    height: 1,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1,
  );

  // ── Headlines ──────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── Body ───────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Labels ─────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.01,
  );

  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
  );

  // ── Tag ────────────────────────────────────────
  static TextStyle get tag => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
  );
}