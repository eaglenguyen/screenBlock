import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/hivebox_names.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = Hive.box(HiveBoxNames.settings);
    final saved = box.get('themeMode', defaultValue: 'dark') as String;
    state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    _syncThemeToNative(); // 👈 new — sync the loaded value on startup
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final box = Hive.box(HiveBoxNames.settings);
    box.put('themeMode', state == ThemeMode.light ? 'light' : 'dark');
    _syncThemeToNative(); // 👈 new
  }

  void setDark() {
    state = ThemeMode.dark;
    Hive.box(HiveBoxNames.settings).put('themeMode', 'dark');
    _syncThemeToNative(); // 👈 new
  }

  void setLight() {
    state = ThemeMode.light;
    Hive.box(HiveBoxNames.settings).put('themeMode', 'light');
    _syncThemeToNative(); // 👈 new
  }

  bool get isDark => state == ThemeMode.dark;

  // 👇 new — pushes the current theme to native shared storage (iOS only)
  Future<void> _syncThemeToNative() async {
    if (!Platform.isIOS) return;
    try {
      await const MethodChannel('com.eagle.pausenow/ios_blocking')
          .invokeMethod('saveThemePreference', {'isDark': isDark});
    } catch (e) {
      debugPrint('❌ saveThemePreference error: $e');
    }
  }
}