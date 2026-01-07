import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../widgets/settings_dialog.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCreating = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _selectedPath;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createNewDatabase() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
      _selectedPath = null;
    });
  }

  Future<void> _openExistingDatabase() async {
    setState(() {
      _isCreating = false;
      _errorMessage = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'pwdb'],
      dialogTitle: 'Open Password Database',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPath = result.files.single.path;
      });
    }
  }

  Future<void> _selectSavePath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Create Password Database',
      fileName: 'passwords.pwdb',
      allowedExtensions: ['pwdb'],
      type: FileType.custom,
    );

    if (result != null) {
      setState(() {
        _selectedPath = result;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    if (_isCreating) {
      if (password != _confirmPasswordController.text) {
        setState(() => _errorMessage = l10n.passwordsDoNotMatch);
        return;
      }

      if (password.length < 8) {
        setState(() => _errorMessage = l10n.passwordTooShort);
        return;
      }

      if (_selectedPath == null) {
        setState(() => _errorMessage = l10n.pleaseSelectLocation);
        return;
      }

      setState(() => _isLoading = true);

      final success = await ref
          .read(databaseNotifierProvider.notifier)
          .createDatabase(_selectedPath!, password);

      setState(() => _isLoading = false);

      if (!success) {
        setState(() => _errorMessage = l10n.failedToCreateDatabase);
      }
    } else {
      if (_selectedPath == null) {
        setState(() => _errorMessage = l10n.pleaseSelectFile);
        return;
      }

      setState(() => _isLoading = true);

      final success = await ref
          .read(databaseNotifierProvider.notifier)
          .openExistingDatabase(_selectedPath!, password);

      setState(() => _isLoading = false);

      if (!success) {
        setState(() => _errorMessage = l10n.invalidPasswordOrCorrupted);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // Action buttons or form
                if (!_isCreating && _selectedPath == null) ...[
                  FilledButton.icon(
                    onPressed: _createNewDatabase,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createNewDatabase),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openExistingDatabase,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.openExistingDatabase),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ] else ...[
                  // Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isCreating ? l10n.createNewDatabase : l10n.openExistingDatabase,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),

                          // File path
                          if (_isCreating) ...[
                            OutlinedButton.icon(
                              onPressed: _selectSavePath,
                              icon: const Icon(Icons.save),
                              label: Text(_selectedPath ?? l10n.selectSaveLocation),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedPath ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Master password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.masterPassword,
                              prefixIcon: const Icon(Icons.key),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),

                          // Confirm password (only for create)
                          if (_isCreating) ...[
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: l10n.confirmPassword,
                                prefixIcon: const Icon(Icons.key),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                          color: theme.colorScheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit button
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isCreating ? l10n.create : l10n.unlock),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _isCreating = false;
                              _selectedPath = null;
                              _errorMessage = null;
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            }),
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
