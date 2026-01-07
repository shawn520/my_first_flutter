import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'change_password_dialog.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  String _getAutoLockLabel(AutoLockDuration duration, AppLocalizations l10n, int? customMinutes) {
    switch (duration) {
      case AutoLockDuration.oneMinute:
        return l10n.autoLockOneMinute;
      case AutoLockDuration.fiveMinutes:
        return l10n.autoLockFiveMinutes;
      case AutoLockDuration.thirtyMinutes:
        return l10n.autoLockThirtyMinutes;
      case AutoLockDuration.never:
        return l10n.autoLockNever;
      case AutoLockDuration.custom:
        return customMinutes != null
            ? l10n.autoLockCustomMinutes(customMinutes)
            : l10n.autoLockCustom;
    }
  }

  Future<void> _showCustomTimeDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final settings = ref.read(settingsProvider);

    if (settings.customAutoLockMinutes != null) {
      controller.text = settings.customAutoLockMinutes.toString();
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.autoLockCustom),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.enterMinutes,
            suffixText: l10n.minutes,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(settingsProvider.notifier).setAutoLockDuration(
        AutoLockDuration.custom,
        customMinutes: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return AlertDialog(
      title: Text(l10n.settings),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),

              // Auto-lock setting
              Text(
                l10n.autoLock,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.autoLockDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...AutoLockDuration.values.where((d) => d != AutoLockDuration.custom).map((duration) {
                    return ChoiceChip(
                      label: Text(_getAutoLockLabel(duration, l10n, null)),
                      selected: settings.autoLockDuration == duration,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(settingsProvider.notifier).setAutoLockDuration(duration);
                        }
                      },
                    );
                  }),
                  // Custom option
                  ChoiceChip(
                    label: Text(_getAutoLockLabel(
                      AutoLockDuration.custom,
                      l10n,
                      settings.autoLockDuration == AutoLockDuration.custom
                          ? settings.customAutoLockMinutes
                          : null,
                    )),
                    selected: settings.autoLockDuration == AutoLockDuration.custom,
                    onSelected: (selected) {
                      if (selected) {
                        _showCustomTimeDialog(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Change password
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const ChangePasswordDialog(),
                    );
                  },
                  icon: const Icon(Icons.key),
                  label: Text(l10n.changePassword),
                ),
              ),
            ],
          ),
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
