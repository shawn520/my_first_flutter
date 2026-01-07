import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../core/database/app_database.dart';
import '../providers/entries_provider.dart';
import '../providers/groups_provider.dart';
import 'password_generator.dart';

class EntryEditDialog extends ConsumerStatefulWidget {
  final Entry? entry;
  final int groupId;

  const EntryEditDialog({
    super.key,
    this.entry,
    required this.groupId,
  });

  @override
  ConsumerState<EntryEditDialog> createState() => _EntryEditDialogState();
}

class _EntryEditDialogState extends ConsumerState<EntryEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  late int _selectedGroupId;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;

    if (_isEditing) {
      final entry = widget.entry!;
      final decrypted = ref.read(entriesNotifierProvider.notifier).decryptEntry(entry);
      _titleController = TextEditingController(text: entry.title);
      _usernameController = TextEditingController(text: decrypted.username);
      _passwordController = TextEditingController(text: decrypted.password);
      _urlController = TextEditingController(text: entry.url);
      _notesController = TextEditingController(text: decrypted.notes);
    } else {
      _titleController = TextEditingController();
      _usernameController = TextEditingController();
      _passwordController = TextEditingController();
      _urlController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.titleRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = EntryData(
        title: _titleController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        url: _urlController.text,
        notes: _notesController.text,
        groupId: _selectedGroupId,
      );

      if (_isEditing) {
        await ref
            .read(entriesNotifierProvider.notifier)
            .updateEntry(widget.entry!.id, data);
      } else {
        await ref.read(entriesNotifierProvider.notifier).addEntry(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPasswordGenerator() {
    showDialog(
      context: context,
      builder: (context) => PasswordGenerator(
        onGenerated: (password) {
          _passwordController.text = password;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(allGroupsProvider).value ?? [];

    return AlertDialog(
      title: Text(_isEditing ? l10n.editEntry : l10n.newEntry),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '${l10n.title} *',
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Group selector
              DropdownButtonFormField<int>(
                value: _selectedGroupId,
                decoration: InputDecoration(
                  labelText: l10n.group,
                  prefixIcon: const Icon(Icons.folder),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Root'),
                  ),
                  ...groups
                      .where((g) => g.id != 1)
                      .map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          )),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGroupId = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.key),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      IconButton(
                        icon: const Icon(Icons.casino),
                        tooltip: l10n.passwordGenerator,
                        onPressed: _showPasswordGenerator,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // URL
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.url,
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
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
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? l10n.save : l10n.create),
        ),
      ],
    );
  }
}
