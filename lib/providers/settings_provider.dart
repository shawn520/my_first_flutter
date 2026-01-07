import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto-lock duration options
enum AutoLockDuration {
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  thirtyMinutes(Duration(minutes: 30)),
  never(null),
  custom(null);

  final Duration? duration;
  const AutoLockDuration(this.duration);
}

/// App settings state
class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final String? lastDatabasePath;
  final bool isInitialized;
  final AutoLockDuration autoLockDuration;
  final int? customAutoLockMinutes;

  const AppSettings({
    this.locale = const Locale('zh'),
    this.themeMode = ThemeMode.system,
    this.lastDatabasePath,
    this.isInitialized = false,
    this.autoLockDuration = AutoLockDuration.oneMinute,
    this.customAutoLockMinutes,
  });

  /// Get the actual auto-lock duration
  Duration? get effectiveAutoLockDuration {
    if (autoLockDuration == AutoLockDuration.never) {
      return null;
    }
    if (autoLockDuration == AutoLockDuration.custom && customAutoLockMinutes != null) {
      return Duration(minutes: customAutoLockMinutes!);
    }
    return autoLockDuration.duration;
  }

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    String? lastDatabasePath,
    bool clearLastDatabasePath = false,
    bool? isInitialized,
    AutoLockDuration? autoLockDuration,
    int? customAutoLockMinutes,
    bool clearCustomAutoLockMinutes = false,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      lastDatabasePath: clearLastDatabasePath ? null : (lastDatabasePath ?? this.lastDatabasePath),
      isInitialized: isInitialized ?? this.isInitialized,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      customAutoLockMinutes: clearCustomAutoLockMinutes ? null : (customAutoLockMinutes ?? this.customAutoLockMinutes),
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _localeKey = 'locale';
  static const String _themeModeKey = 'themeMode';
  static const String _lastDatabasePathKey = 'lastDatabasePath';
  static const String _autoLockDurationKey = 'autoLockDuration';
  static const String _customAutoLockMinutesKey = 'customAutoLockMinutes';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final localeCode = prefs.getString(_localeKey) ?? 'zh';
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final lastDatabasePath = prefs.getString(_lastDatabasePathKey);
    final autoLockIndex = prefs.getInt(_autoLockDurationKey) ?? AutoLockDuration.oneMinute.index;
    final customAutoLockMinutes = prefs.getInt(_customAutoLockMinutesKey);

    state = AppSettings(
      locale: Locale(localeCode),
      themeMode: ThemeMode.values[themeModeIndex],
      lastDatabasePath: lastDatabasePath,
      isInitialized: true,
      autoLockDuration: AutoLockDuration.values[autoLockIndex],
      customAutoLockMinutes: customAutoLockMinutes,
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

  Future<void> setLastDatabasePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_lastDatabasePathKey, path);
      state = state.copyWith(lastDatabasePath: path);
    } else {
      await prefs.remove(_lastDatabasePathKey);
      state = state.copyWith(clearLastDatabasePath: true);
    }
  }

  Future<void> setAutoLockDuration(AutoLockDuration duration, {int? customMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockDurationKey, duration.index);

    if (duration == AutoLockDuration.custom && customMinutes != null) {
      await prefs.setInt(_customAutoLockMinutesKey, customMinutes);
      state = state.copyWith(autoLockDuration: duration, customAutoLockMinutes: customMinutes);
    } else {
      state = state.copyWith(autoLockDuration: duration, clearCustomAutoLockMinutes: duration != AutoLockDuration.custom);
    }
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

/// Auto-lock duration provider (derived from settings)
final autoLockDurationProvider = Provider<Duration?>((ref) {
  return ref.watch(settingsProvider).effectiveAutoLockDuration;
});
