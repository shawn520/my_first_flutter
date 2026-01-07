import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
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
          SnackBar(content: Text('Error: $e')),
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
    final groups = ref.watch(allGroupsProvider).value ?? [];
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
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
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Group selector
              DropdownButtonFormField<int>(
                value: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Group',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
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
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                        tooltip: 'Generate Password',
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
                decoration: const InputDecoration(
                  labelText: 'URL',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
