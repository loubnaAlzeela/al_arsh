import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark theme
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state == ThemeMode.dark) {
      prefs.setBool(_themeKey, false);
      state = ThemeMode.light;
    } else {
      prefs.setBool(_themeKey, true);
      state = ThemeMode.dark;
    }
  }
}
