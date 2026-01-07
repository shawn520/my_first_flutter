import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../providers/groups_provider.dart';

class GroupTree extends ConsumerWidget {
  const GroupTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Groups',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                tooltip: 'New Group',
                onPressed: () => _showAddGroupDialog(context, ref),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // All entries option
        ListTile(
          dense: true,
          leading: const Icon(Icons.folder_special, size: 20),
          title: const Text('All Entries'),
          selected: selectedGroupId == null,
          onTap: () {
            ref.read(selectedGroupIdProvider.notifier).state = null;
          },
        ),

        // Group list
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (groups) {
              // Filter out root and show only user groups
              final userGroups = groups.where((g) => g.id != 1).toList();

              if (userGroups.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No groups yet.\nClick + to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  final group = userGroups[index];
                  return _GroupTile(
                    group: group,
                    isSelected: group.id == selectedGroupId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(groupsNotifierProvider.notifier).addGroup(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(groupsNotifierProvider.notifier).addGroup(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  final Group group;
  final bool isSelected;

  const _GroupTile({
    required this.group,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: Icon(
        IconData(group.iconCode, fontFamily: 'MaterialIcons'),
        size: 20,
      ),
      title: Text(group.name),
      selected: isSelected,
      onTap: () {
        ref.read(selectedGroupIdProvider.notifier).state = group.id;
      },
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'rename':
              _showRenameDialog(context, ref);
              break;
            case 'delete':
              _showDeleteDialog(context, ref);
              break;
          }
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: group.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(groupsNotifierProvider.notifier)
                    .updateGroup(group.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\n'
          'All entries in this group will also be deleted.',
        ),
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
              ref.read(groupsNotifierProvider.notifier).deleteGroup(group.id);
              if (ref.read(selectedGroupIdProvider) == group.id) {
                ref.read(selectedGroupIdProvider.notifier).state = null;
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
