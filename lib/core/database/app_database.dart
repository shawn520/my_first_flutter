import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Groups table for organizing passwords
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get parentId => integer().nullable().references(Groups, #id)();
  IntColumn get iconCode => integer().withDefault(const Constant(0xe318))(); // folder icon
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Password entries table
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(Groups, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get username => text().withDefault(const Constant(''))();
  TextColumn get password => text().withDefault(const Constant(''))(); // Encrypted
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))(); // Encrypted
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Database metadata table
class Metadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Groups, Entries, Metadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create default root group
        await into(groups).insert(GroupsCompanion.insert(
          name: 'Root',
          iconCode: const Value(0xe318),
        ));
      },
    );
  }

  // ============ Metadata operations ============

  Future<String?> getMetadata(String key) async {
    final query = select(metadata)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  Future<void> setMetadata(String key, String value) async {
    await into(metadata).insertOnConflictUpdate(
      MetadataCompanion.insert(key: key, value: value),
    );
  }

  // ============ Group operations ============

  Future<List<Group>> getAllGroups() => select(groups).get();

  Stream<List<Group>> watchAllGroups() => select(groups).watch();

  Future<Group> getGroup(int id) =>
      (select(groups)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertGroup(GroupsCompanion group) => into(groups).insert(group);

  Future<bool> updateGroup(GroupsCompanion group) =>
      update(groups).replace(group);

  Future<int> deleteGroup(int id) =>
      (delete(groups)..where((t) => t.id.equals(id))).go();

  // ============ Entry operations ============

  Future<List<Entry>> getAllEntries() => select(entries).get();

  Stream<List<Entry>> watchAllEntries() => select(entries).watch();

  Future<List<Entry>> getEntriesByGroup(int groupId) =>
      (select(entries)..where((t) => t.groupId.equals(groupId))).get();

  Stream<List<Entry>> watchEntriesByGroup(int groupId) =>
      (select(entries)..where((t) => t.groupId.equals(groupId))).watch();

  Future<Entry> getEntry(int id) =>
      (select(entries)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertEntry(EntriesCompanion entry) => into(entries).insert(entry);

  Future<bool> updateEntry(EntriesCompanion entry) =>
      update(entries).replace(entry);

  Future<int> deleteEntry(int id) =>
      (delete(entries)..where((t) => t.id.equals(id))).go();

  Future<List<Entry>> searchEntries(String query) {
    final pattern = '%$query%';
    return (select(entries)
          ..where((t) =>
              t.title.like(pattern) |
              t.username.like(pattern) |
              t.url.like(pattern)))
        .get();
  }

  Stream<List<Entry>> watchSearchEntries(String query) {
    final pattern = '%$query%';
    return (select(entries)
          ..where((t) =>
              t.title.like(pattern) |
              t.username.like(pattern) |
              t.url.like(pattern)))
        .watch();
  }
}

/// Opens database from a file path
LazyDatabase openDatabase(String path) {
  return LazyDatabase(() async {
    final file = File(path);
    return NativeDatabase.createInBackground(file);
  });
}
