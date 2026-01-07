import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/entries_provider.dart';
import '../widgets/group_tree.dart';
import '../widgets/entry_list.dart';
import '../widgets/entry_detail.dart';
import '../widgets/export_dialog.dart';
import '../widgets/import_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _lockDatabase() {
    ref.read(databaseNotifierProvider.notifier).lockDatabase();
  }

  void _closeDatabase() {
    ref.read(databaseNotifierProvider.notifier).closeDatabase();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ImportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEntry = ref.watch(selectedEntryProvider);

    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                // Lock button
                IconButton(
                  icon: const Icon(Icons.lock),
                  tooltip: 'Lock Database',
                  onPressed: _lockDatabase,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close Database',
                  onPressed: _closeDatabase,
                ),
                const SizedBox(width: 8),
                const VerticalDivider(width: 1, thickness: 1),
                const SizedBox(width: 8),

                // Import/Export buttons
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: 'Export Groups',
                  onPressed: _showExportDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: 'Import Groups',
                  onPressed: _showImportDialog,
                ),
                const SizedBox(width: 8),
                const VerticalDivider(width: 1, thickness: 1),
                const SizedBox(width: 8),

                // Search field
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search entries...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel - Group tree
                SizedBox(
                  width: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                    child: const GroupTree(),
                  ),
                ),

                // Middle panel - Entry list
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                    child: const EntryList(),
                  ),
                ),

                // Right panel - Entry detail
                if (selectedEntry != null)
                  const Expanded(
                    flex: 3,
                    child: EntryDetail(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
