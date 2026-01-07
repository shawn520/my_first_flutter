import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import '../core/database/app_database.dart';
import '../core/export/import_service.dart';
import '../core/export/export_service.dart';
import '../core/crypto/crypto_service.dart';
import '../providers/database_provider.dart';

class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  final _passwordController = TextEditingController();
  String? _selectedFilePath;
  bool _obscurePassword = true;
  bool _isImporting = false;
  bool _isValidating = false;
  String? _errorMessage;
  ImportResponse? _validationResult;
  List<GroupExportData>? _previewGroups;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pwexp'],
      dialogTitle: 'Select Export File',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _errorMessage = null;
        _validationResult = null;
        _previewGroups = null;
      });
    }
  }

  Future<void> _validateAndPreview() async {
    if (_selectedFilePath == null) {
      setState(() => _errorMessage = 'Please select a file');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter the export password');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final result = await ImportService.importGroups(
        filePath: _selectedFilePath!,
        password: _passwordController.text,
      );

      setState(() {
        _validationResult = result;
        if (result.isSuccess) {
          _previewGroups = result.groups;
        } else {
          _errorMessage = result.errorMessage ?? result.result.message;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Validation failed: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _import() async {
    if (_previewGroups == null || _previewGroups!.isEmpty) {
      setState(() => _errorMessage = 'No data to import');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final encryptionKey = ref.read(encryptionKeyProvider);

      if (db == null) {
        setState(() => _errorMessage = 'Database not available');
        return;
      }

      // Get existing group names for conflict resolution
      final existingGroups = await db.getAllGroups();
      final existingNames = existingGroups.map((g) => g.name).toSet();

      int importedGroups = 0;
      int importedEntries = 0;

      for (final groupData in _previewGroups!) {
        // Generate unique name if needed
        final uniqueName =
            ImportService.generateUniqueName(groupData.name, existingNames);
        existingNames.add(uniqueName);

        // Create group
        final groupId = await db.insertGroup(GroupsCompanion.insert(
          name: uniqueName,
          iconCode: Value(groupData.iconCode),
        ));
        importedGroups++;

        // Create entries
        for (final entryData in groupData.entries) {
          // Encrypt sensitive fields with database key
          String encryptedPassword = entryData.password;
          String encryptedNotes = entryData.notes;

          if (encryptionKey != null) {
            if (entryData.password.isNotEmpty) {
              encryptedPassword =
                  CryptoService.encrypt(entryData.password, encryptionKey);
            }
            if (entryData.notes.isNotEmpty) {
              encryptedNotes =
                  CryptoService.encrypt(entryData.notes, encryptionKey);
            }
          }

          await db.insertEntry(EntriesCompanion.insert(
            groupId: groupId,
            title: entryData.title,
            username: Value(entryData.username),
            password: Value(encryptedPassword),
            url: Value(entryData.url),
            notes: Value(encryptedNotes),
          ));
          importedEntries++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(importedGroups, importedEntries);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Import failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showSuccessDialog(int groups, int entries) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Import Successful'),
          ],
        ),
        content: Text('Imported $groups groups with $entries entries.'),
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

    return AlertDialog(
      title: const Text('Import Groups'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File selection
              Text(
                'Select Export File',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedFilePath ?? 'No file selected',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedFilePath == null
                              ? theme.colorScheme.outline
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password
              Text(
                'Export Password',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter the export password',
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
              const SizedBox(height: 16),

              // Validate button
              if (_previewGroups == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isValidating ? null : _validateAndPreview,
                    icon: _isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isValidating ? 'Validating...' : 'Validate & Preview'),
                  ),
                ),

              // Preview
              if (_previewGroups != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'File validated successfully',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preview (${_previewGroups!.length} groups)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _previewGroups!.length,
                    itemBuilder: (context, index) {
                      final group = _previewGroups![index];
                      return ExpansionTile(
                        leading: Icon(
                          IconData(group.iconCode, fontFamily: 'MaterialIcons'),
                          size: 20,
                        ),
                        title: Text(group.name),
                        subtitle: Text('${group.entries.length} entries'),
                        children: group.entries
                            .map((entry) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.key, size: 16),
                                  title: Text(entry.title),
                                  subtitle: Text(entry.username),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Duplicate group names will be automatically renamed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],

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
          onPressed:
              _previewGroups == null || _isImporting ? null : _import,
          child: _isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}
