import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hivebox_names.dart';

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
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final box = Hive.box(HiveBoxNames.settings);
    box.put('themeMode', state == ThemeMode.light ? 'light' : 'dark');
  }

  void setDark() {
    state = ThemeMode.dark;
    Hive.box(HiveBoxNames.settings).put('themeMode', 'dark');
  }

  void setLight() {
    state = ThemeMode.light;
    Hive.box(HiveBoxNames.settings).put('themeMode', 'light');
  }

  bool get isDark => state == ThemeMode.dark;
}