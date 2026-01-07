import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/database/app_database.dart';
import 'providers/database_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/auto_lock_wrapper.dart';

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

      home: const AutoLockWrapper(
        child: AppRouter(),
      ),
    );
  }
}

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  bool _hasCheckedLastDatabase = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final dbState = ref.watch(databaseStateProvider);

    // Wait for settings to be initialized
    if (!settings.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if we need to auto-load the last database
    if (!_hasCheckedLastDatabase && dbState == DatabaseState.none) {
      _hasCheckedLastDatabase = true;

      final lastPath = settings.lastDatabasePath;
      if (lastPath != null && File(lastPath).existsSync()) {
        // Auto-load last database in locked state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadLastDatabase(lastPath);
        });
      }
    }

    return switch (dbState) {
      DatabaseState.none => const WelcomeScreen(),
      DatabaseState.locked => const UnlockScreen(),
      DatabaseState.unlocked => const HomeScreen(),
    };
  }

  Future<void> _loadLastDatabase(String path) async {
    // Set the database path and state to locked (needs password to unlock)
    ref.read(databasePathProvider.notifier).state = path;
    ref.read(databaseStateProvider.notifier).state = DatabaseState.locked;

    // Open database connection (but don't unlock yet)
    final db = AppDatabase(openDatabase(path));
    ref.read(databaseProvider.notifier).state = db;
  }
}
