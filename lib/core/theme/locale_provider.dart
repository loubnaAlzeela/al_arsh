import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart'; // reuse sharedPreferencesProvider

// ── Locale Provider ──────────────────────────────────────────────────────────

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final langCode = prefs.getString('app_locale') ?? 'ar';
  return LocaleNotifier(
    prefs: ref.read(sharedPreferencesProvider),
    initial: Locale(langCode),
  );
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _localeKey = 'app_locale';
  final dynamic _prefs;

  LocaleNotifier({required dynamic prefs, required Locale initial})
      : _prefs = prefs,
        super(initial);

  bool get isArabic => state.languageCode == 'ar';

  void setArabic() {
    _prefs.setString(_localeKey, 'ar');
    state = const Locale('ar');
  }

  void setEnglish() {
    _prefs.setString(_localeKey, 'en');
    state = const Locale('en');
  }

  void toggle() {
    if (isArabic) {
      setEnglish();
    } else {
      setArabic();
    }
  }
}
