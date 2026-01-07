import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _export() async {
    // Validate
    if (_selectedGroupIds.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one group');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter or generate a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (_selectedExpiry == ExpiryOption.custom && _customExpiryDate == null) {
      setState(() => _errorMessage = 'Please select a custom expiry date');
      return;
    }

    // Select save path
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Password Data',
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
        setState(() => _errorMessage = 'Database not available');
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
      setState(() => _errorMessage = 'Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File saved to:'),
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
            const Text(
              'Important: Remember your export password!\nYou will need it to import this file.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Password: '),
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
                      const SnackBar(content: Text('Password copied')),
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
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(allGroupsProvider);

    return AlertDialog(
      title: const Text('Export Groups'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group selection
              Text(
                'Select Groups to Export',
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
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (groups) {
                    final userGroups = groups.where((g) => g.id != 1).toList();
                    if (userGroups.isEmpty) {
                      return const Center(child: Text('No groups available'));
                    }
                    return ListView(
                      children: [
                        // Select all option
                        CheckboxListTile(
                          title: const Text('Select All'),
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
                'Expiry',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpiryOption.values.map((option) {
                  return ChoiceChip(
                    label: Text(option.label),
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
                  'Expires: ${_formatDate(_customExpiryDate!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),

              // Password
              Text(
                'Export Password',
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
                        hintText: 'Enter or generate password',
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
                    label: const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This password will be required to import the file',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _export,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
