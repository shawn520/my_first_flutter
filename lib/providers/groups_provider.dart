import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import 'database_provider.dart';

/// All groups stream provider
final allGroupsProvider = StreamProvider<List<Group>>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return Stream.value([]);
  return db.watchAllGroups();
});

/// Selected group ID provider
final selectedGroupIdProvider = StateProvider<int?>((ref) => null);

/// Selected group provider
final selectedGroupProvider = Provider<Group?>((ref) {
  final groups = ref.watch(allGroupsProvider).value ?? [];
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) return null;
  try {
    return groups.firstWhere((g) => g.id == selectedId);
  } catch (e) {
    return null;
  }
});

/// Group operations notifier
class GroupsNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  final Ref ref;

  GroupsNotifier(this.ref) : super(const AsyncValue.loading());

  Future<int> addGroup(String name, {int? parentId, int? iconCode}) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');

    return await db.insertGroup(
      GroupsCompanion.insert(
        name: name,
        parentId: Value(parentId),
        iconCode: Value(iconCode ?? 0xe318),
      ),
    );
  }

  Future<void> updateGroup(int id, String name, {int? iconCode}) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');

    final group = await db.getGroup(id);
    await db.updateGroup(
      GroupsCompanion(
        id: Value(id),
        name: Value(name),
        parentId: Value(group.parentId),
        iconCode: Value(iconCode ?? group.iconCode),
        createdAt: Value(group.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteGroup(int id) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');

    // Also delete all entries in this group
    final entries = await db.getEntriesByGroup(id);
    for (final entry in entries) {
      await db.deleteEntry(entry.id);
    }

    await db.deleteGroup(id);
  }
}

/// Groups notifier provider
final groupsNotifierProvider =
    StateNotifierProvider<GroupsNotifier, AsyncValue<List<Group>>>((ref) {
      return GroupsNotifier(ref);
    });
