import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../providers/entries_provider.dart';
import '../providers/groups_provider.dart';
import 'entry_edit_dialog.dart';

class EntryList extends ConsumerWidget {
  const EntryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(filteredEntriesProvider);
    final selectedEntryId = ref.watch(selectedEntryIdProvider);
    final selectedGroup = ref.watch(selectedGroupProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedGroup?.name ?? 'All Entries',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${entries.length} items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'New Entry',
                onPressed: () => _showAddEntryDialog(context, ref),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Entry list
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.key_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No entries yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddEntryDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Entry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _EntryTile(
                      entry: entry,
                      isSelected: entry.id == selectedEntryId,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    final selectedGroupId = ref.read(selectedGroupIdProvider) ?? 1;

    showDialog(
      context: context,
      builder: (context) => EntryEditDialog(
        groupId: selectedGroupId,
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  final Entry entry;
  final bool isSelected;

  const _EntryTile({
    required this.entry,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entry.username.isNotEmpty ? entry.username : entry.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.colorScheme.outline),
      ),
      onTap: () {
        ref.read(selectedEntryIdProvider.notifier).state = entry.id;
      },
    );
  }
}
