import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../core/database/app_database.dart';
import '../providers/groups_provider.dart';

class GroupTree extends ConsumerWidget {
  const GroupTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(allGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.groups,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                tooltip: l10n.newGroup,
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
          title: Text(l10n.allEntries),
          selected: selectedGroupId == null,
          onTap: () {
            ref.read(selectedGroupIdProvider.notifier).state = null;
          },
        ),

        // Group list
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (groups) {
              // Filter out root and show only user groups
              final userGroups = groups.where((g) => g.id != 1).toList();

              if (userGroups.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noGroupsYet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newGroup),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.groupName,
            border: const OutlineInputBorder(),
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(groupsNotifierProvider.notifier).addGroup(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.create),
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
    final l10n = AppLocalizations.of(context);

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
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 8),
                Text(l10n.rename),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 18),
                const SizedBox(width: 8),
                Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: group.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameGroup),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.groupName,
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
              if (controller.text.isNotEmpty) {
                ref
                    .read(groupsNotifierProvider.notifier)
                    .updateGroup(group.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGroup),
        content: Text(l10n.deleteGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
