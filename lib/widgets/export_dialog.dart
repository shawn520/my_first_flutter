import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../core/database/app_database.dart';
import '../core/export/export_service.dart';
import '../core/crypto/crypto_service.dart';
import '../providers/database_provider.dart';
import '../providers/groups_provider.dart';

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  final _passwordController = TextEditingController();
  final Set<int> _selectedGroupIds = {};
  ExpiryOption _selectedExpiry = ExpiryOption.twentyFourHours;
  DateTime? _customExpiryDate;
  bool _obscurePassword = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final password = ExportService.generateRandomPassword();
    _passwordController.text = password;
    setState(() {});
  }

  Future<void> _selectCustomExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _customExpiryDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  DateTime? _getExpiryDate() {
    if (_selectedExpiry == ExpiryOption.never) {
      return null;
    }
    if (_selectedExpiry == ExpiryOption.custom) {
      return _customExpiryDate;
    }
    final duration = _selectedExpiry.duration;
    if (duration == null) return null;
    return DateTime.now().add(duration);
  }

  String _getExpiryLabel(ExpiryOption option, AppLocalizations l10n) {
    switch (option) {
      case ExpiryOption.oneHour:
        return l10n.oneHour;
      case ExpiryOption.twentyFourHours:
        return l10n.twentyFourHours;
      case ExpiryOption.sevenDays:
        return l10n.sevenDays;
      case ExpiryOption.thirtyDays:
        return l10n.thirtyDays;
      case ExpiryOption.never:
        return l10n.never;
      case ExpiryOption.custom:
        return l10n.custom;
    }
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);

    // Validate
    if (_selectedGroupIds.isEmpty) {
      setState(() => _errorMessage = l10n.selectAtLeastOneGroup);
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = l10n.passwordMinLength);
      return;
    }

    if (_selectedExpiry == ExpiryOption.custom && _customExpiryDate == null) {
      setState(() => _errorMessage = l10n.selectCustomExpiry);
      return;
    }

    // Select save path
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.exportGroups,
      fileName: 'passwords_export.pwexp',
      allowedExtensions: ['pwexp'],
      type: FileType.custom,
    );

    if (savePath == null) return;

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final encryptionKey = ref.read(encryptionKeyProvider);

      if (db == null) {
        setState(() => _errorMessage = l10n.databaseNotAvailable);
        return;
      }

      // Get selected groups
      final allGroups = await db.getAllGroups();
      final selectedGroups =
          allGroups.where((g) => _selectedGroupIds.contains(g.id)).toList();

      // Get entries for each group
      final entriesByGroup = <int, List<Entry>>{};
      for (final group in selectedGroups) {
        final entries = await db.getEntriesByGroup(group.id);
        entriesByGroup[group.id] = entries;
      }

      // Export
      await ExportService.exportGroups(
        groups: selectedGroups,
        entriesByGroup: entriesByGroup,
        filePath: savePath,
        password: _passwordController.text,
        expiresAt: _getExpiryDate(),
        dbEncryptionKey: encryptionKey,
        decryptField: CryptoService.decrypt,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(savePath);
      }
    } catch (e) {
      setState(() => _errorMessage = '${l10n.exportFailed}: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSuccessDialog(String path) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(l10n.exportSuccessful),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.fileSavedTo),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                path,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.rememberPassword,
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${l10n.password}: '),
                Expanded(
                  child: SelectableText(
                    _passwordController.text,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _passwordController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.passwordCopied)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(allGroupsProvider);

    return AlertDialog(
      title: Text(l10n.exportGroups),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group selection
              Text(
                l10n.selectGroupsToExport,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: groupsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                  data: (groups) {
                    final userGroups = groups.where((g) => g.id != 1).toList();
                    if (userGroups.isEmpty) {
                      return Center(child: Text(l10n.noGroupsAvailable));
                    }
                    return ListView(
                      children: [
                        // Select all option
                        CheckboxListTile(
                          title: Text(l10n.selectAll),
                          value: _selectedGroupIds.length == userGroups.length,
                          tristate: true,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedGroupIds
                                    .addAll(userGroups.map((g) => g.id));
                              } else {
                                _selectedGroupIds.clear();
                              }
                            });
                          },
                        ),
                        const Divider(height: 1),
                        ...userGroups.map((group) => CheckboxListTile(
                              title: Text(group.name),
                              secondary: Icon(
                                IconData(group.iconCode,
                                    fontFamily: 'MaterialIcons'),
                                size: 20,
                              ),
                              value: _selectedGroupIds.contains(group.id),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedGroupIds.add(group.id);
                                  } else {
                                    _selectedGroupIds.remove(group.id);
                                  }
                                });
                              },
                            )),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Expiry selection
              Text(
                l10n.expiry,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpiryOption.values.map((option) {
                  return ChoiceChip(
                    label: Text(_getExpiryLabel(option, l10n)),
                    selected: _selectedExpiry == option,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedExpiry = option;
                          if (option == ExpiryOption.custom) {
                            _selectCustomExpiry();
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              if (_selectedExpiry == ExpiryOption.custom &&
                  _customExpiryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.expiresAt(_formatDate(_customExpiryDate!)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),

              // Password
              Text(
                l10n.exportPassword,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: l10n.enterOrGeneratePassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _generatePassword,
                    icon: const Icon(Icons.casino),
                    label: Text(l10n.generate),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.passwordRequiredForImport,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _export,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.export),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
