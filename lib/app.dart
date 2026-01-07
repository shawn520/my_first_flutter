import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/database_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/home_screen.dart';

class PasswordManagerApp extends ConsumerWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,

      // Localization
      locale: settings.locale,
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settings.themeMode,

      home: const AppRouter(),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(databaseStateProvider);

    return switch (dbState) {
      DatabaseState.none => const WelcomeScreen(),
      DatabaseState.locked => const UnlockScreen(),
      DatabaseState.unlocked => const HomeScreen(),
    };
  }
}
