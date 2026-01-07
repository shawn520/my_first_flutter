import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return AlertDialog(
      title: Text(l10n.settings),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language setting
            Text(
              l10n.language,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('zh'),
                  label: Text(l10n.chinese),
                  icon: const Icon(Icons.language),
                ),
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(l10n.english),
                  icon: const Icon(Icons.language),
                ),
              ],
              selected: {settings.locale},
              onSelectionChanged: (Set<Locale> selected) {
                ref.read(settingsProvider.notifier).setLocale(selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Theme setting
            Text(
              l10n.theme,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.settings_brightness),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> selected) {
                ref.read(settingsProvider.notifier).setThemeMode(selected.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
