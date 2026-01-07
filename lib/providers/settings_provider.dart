import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings state
class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;

  const AppSettings({
    this.locale = const Locale('zh'),
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _localeKey = 'locale';
  static const String _themeModeKey = 'themeMode';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final localeCode = prefs.getString(_localeKey) ?? 'zh';
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;

    state = AppSettings(
      locale: Locale(localeCode),
      themeMode: ThemeMode.values[themeModeIndex],
    );
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, themeMode.index);
    state = state.copyWith(themeMode: themeMode);
  }
}

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Locale provider (derived from settings)
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(settingsProvider).locale;
});

/// Theme mode provider (derived from settings)
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
