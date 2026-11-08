import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _languageKey = 'quran_translation_language';
  static const String _themeKey = 'app_theme_mode';

  static final ValueNotifier<QuranLanguage> language =
      ValueNotifier<QuranLanguage>(QuranLanguage.english);
  static bool get isDark => themeMode.value == ThemeMode.dark;\n\n  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageName = prefs.getString(_languageKey) ?? 'english';
    language.value = QuranLanguage.values.firstWhere(
      (item) => item.name == languageName,
      orElse: () => QuranLanguage.english,
    );

    final themeName = prefs.getString(_themeKey) ?? 'light';
    themeMode.value = ThemeMode.values.firstWhere(
      (item) => item.name == themeName,
      orElse: () => ThemeMode.light,
    );
  }

  static Future<void> setLanguage(QuranLanguage value) async {
    language.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value.name);
  }

  static Future<void> setThemeMode(ThemeMode value) async {
    themeMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value.name);
  }
}
