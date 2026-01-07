import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/crypto/crypto_service.dart';
import 'database_provider.dart';
import 'groups_provider.dart';

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// All entries for selected group
final entriesForGroupProvider = StreamProvider<List<Entry>>((ref) {
  final db = ref.watch(databaseProvider);
  final groupId = ref.watch(selectedGroupIdProvider);

  if (db == null) return Stream.value([]);
  if (groupId == null) return db.watchAllEntries();

  return db.watchEntriesByGroup(groupId);
});

/// Filtered entries based on search
final filteredEntriesProvider = Provider<List<Entry>>((ref) {
  final entries = ref.watch(entriesForGroupProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) return entries;

  return entries.where((entry) {
    return entry.title.toLowerCase().contains(query) ||
        entry.username.toLowerCase().contains(query) ||
        entry.url.toLowerCase().contains(query);
  }).toList();
});

/// Selected entry ID
final selectedEntryIdProvider = StateProvider<int?>((ref) => null);

/// Selected entry
final selectedEntryProvider = Provider<Entry?>((ref) {
  final entries = ref.watch(entriesForGroupProvider).value ?? [];
  final selectedId = ref.watch(selectedEntryIdProvider);
  if (selectedId == null) return null;
  try {
    return entries.firstWhere((e) => e.id == selectedId);
  } catch (e) {
    return null;
  }
});

/// Entry data model for create/update
class EntryData {
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
  final int groupId;

  EntryData({
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.groupId,
  });
}

/// Entries operations notifier
class EntriesNotifier extends StateNotifier<AsyncValue<List<Entry>>> {
  final Ref ref;

  EntriesNotifier(this.ref) : super(const AsyncValue.loading());

  Uint8List? get _encryptionKey => ref.read(encryptionKeyProvider);

  String _encryptField(String value) {
    if (value.isEmpty || _encryptionKey == null) return value;
    return CryptoService.encrypt(value, _encryptionKey!);
  }

  String _decryptField(String value) {
    if (value.isEmpty || _encryptionKey == null) return value;
    try {
      return CryptoService.decrypt(value, _encryptionKey!);
    } catch (e) {
      return value;
    }
  }

  /// Decrypts an entry's sensitive fields
  EntryData decryptEntry(Entry entry) {
    return EntryData(
      title: entry.title,
      username: entry.username,
      password: _decryptField(entry.password),
      url: entry.url,
      notes: _decryptField(entry.notes),
      groupId: entry.groupId,
    );
  }

  Future<int> addEntry(EntryData data) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');

    return await db.insertEntry(
      EntriesCompanion.insert(
        groupId: data.groupId,
        title: data.title,
        username: Value(data.username),
        password: Value(_encryptField(data.password)),
        url: Value(data.url),
        notes: Value(_encryptField(data.notes)),
      ),
    );
  }

  Future<void> updateEntry(int id, EntryData data) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');

    final entry = await db.getEntry(id);
    await db.updateEntry(
      EntriesCompanion(
        id: Value(id),
        groupId: Value(data.groupId),
        title: Value(data.title),
        username: Value(data.username),
        password: Value(_encryptField(data.password)),
        url: Value(data.url),
        notes: Value(_encryptField(data.notes)),
        createdAt: Value(entry.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = ref.read(databaseProvider);
    if (db == null) throw Exception('Database not opened');
    await db.deleteEntry(id);
  }
}

/// Entries notifier provider
final entriesNotifierProvider =
    StateNotifierProvider<EntriesNotifier, AsyncValue<List<Entry>>>((ref) {
      return EntriesNotifier(ref);
    });
