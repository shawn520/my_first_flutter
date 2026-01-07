import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/clipboard/clipboard_service.dart';
import '../providers/entries_provider.dart';
import 'entry_edit_dialog.dart';

class EntryDetail extends ConsumerStatefulWidget {
  const EntryDetail({super.key});

  @override
  ConsumerState<EntryDetail> createState() => _EntryDetailState();
}

class _EntryDetailState extends ConsumerState<EntryDetail> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = ref.watch(selectedEntryProvider);
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);

    if (entry == null) {
      return const Center(child: Text('Select an entry'));
    }

    // Decrypt sensitive fields
    final decrypted = entriesNotifier.decryptEntry(entry);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entry.url.isNotEmpty)
                      Text(
                        entry.url,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => _showEditDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => _showDeleteDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Username field
          _DetailField(
            label: 'Username',
            value: decrypted.username,
            icon: Icons.person,
            onCopy: () => _copyToClipboard(context, decrypted.username, 'Username'),
          ),
          const SizedBox(height: 16),

          // Password field
          _DetailField(
            label: 'Password',
            value: _showPassword ? decrypted.password : '••••••••••••',
            icon: Icons.key,
            trailing: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            onCopy: () => _copyToClipboard(context, decrypted.password, 'Password'),
          ),
          const SizedBox(height: 16),

          // URL field
          if (entry.url.isNotEmpty) ...[
            _DetailField(
              label: 'URL',
              value: entry.url,
              icon: Icons.link,
              onCopy: () => _copyToClipboard(context, entry.url, 'URL'),
            ),
            const SizedBox(height: 16),
          ],

          // Notes field
          if (decrypted.notes.isNotEmpty) ...[
            Text(
              'Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(decrypted.notes),
            ),
          ],

          const SizedBox(height: 32),

          // Metadata
          Text(
            'Created: ${_formatDate(entry.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(
            'Modified: ${_formatDate(entry.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    ClipboardService.copy(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied (clears in 30s)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final entry = ref.read(selectedEntryProvider);
    if (entry == null) return;

    showDialog(
      context: context,
      builder: (context) => EntryEditDialog(
        entry: entry,
        groupId: entry.groupId,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final entry = ref.read(selectedEntryProvider);
    if (entry == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(entriesNotifierProvider.notifier).deleteEntry(entry.id);
              ref.read(selectedEntryIdProvider.notifier).state = null;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onCopy;

  const _DetailField({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (trailing != null) trailing!,
              if (onCopy != null && value.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy',
                  onPressed: onCopy,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
