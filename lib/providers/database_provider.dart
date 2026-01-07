import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/crypto/crypto_service.dart';

/// Database state enum
enum DatabaseState { none, locked, unlocked }

/// Current database state provider
final databaseStateProvider = StateProvider<DatabaseState>(
  (ref) => DatabaseState.none,
);

/// Current database file path
final databasePathProvider = StateProvider<String?>((ref) => null);

/// Encryption key (derived from master password)
final encryptionKeyProvider = StateProvider<Uint8List?>((ref) => null);

/// Database instance provider
final databaseProvider = StateProvider<AppDatabase?>((ref) => null);

/// Database notifier for managing database operations
class DatabaseNotifier extends StateNotifier<DatabaseState> {
  final Ref ref;

  DatabaseNotifier(this.ref) : super(DatabaseState.none);

  /// Creates a new database with master password
  Future<bool> createDatabase(String filePath, String masterPassword) async {
    try {
      // Generate salt and hash password
      final salt = CryptoService.generateSalt();
      final passwordHash = CryptoService.hashPassword(masterPassword, salt);
      final encryptionKey = CryptoService.deriveKey(masterPassword, salt);

      // Create database
      final db = AppDatabase(openDatabase(filePath));

      // Store metadata
      await db.setMetadata('salt', salt);
      await db.setMetadata('password_hash', passwordHash);
      await db.setMetadata('version', '1');

      // Update providers
      ref.read(databasePathProvider.notifier).state = filePath;
      ref.read(databaseProvider.notifier).state = db;
      ref.read(encryptionKeyProvider.notifier).state = encryptionKey;
      ref.read(databaseStateProvider.notifier).state = DatabaseState.unlocked;

      state = DatabaseState.unlocked;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Opens an existing database and validates password
  Future<bool> openExistingDatabase(String filePath, String masterPassword) async {
    try {
      // Open database
      final db = AppDatabase(openDatabase(filePath));

      // Get stored salt and hash
      final salt = await db.getMetadata('salt');
      final storedHash = await db.getMetadata('password_hash');

      if (salt == null || storedHash == null) {
        await db.close();
        return false;
      }

      // Verify password
      if (!CryptoService.verifyPassword(masterPassword, salt, storedHash)) {
        await db.close();
        return false;
      }

      // Derive encryption key
      final encryptionKey = CryptoService.deriveKey(masterPassword, salt);

      // Update providers
      ref.read(databasePathProvider.notifier).state = filePath;
      ref.read(databaseProvider.notifier).state = db;
      ref.read(encryptionKeyProvider.notifier).state = encryptionKey;
      ref.read(databaseStateProvider.notifier).state = DatabaseState.unlocked;

      state = DatabaseState.unlocked;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Locks the database
  Future<void> lockDatabase() async {
    ref.read(encryptionKeyProvider.notifier).state = null;
    ref.read(databaseStateProvider.notifier).state = DatabaseState.locked;
    state = DatabaseState.locked;
  }

  /// Unlocks with password
  Future<bool> unlockDatabase(String masterPassword) async {
    final db = ref.read(databaseProvider);
    if (db == null) return false;

    try {
      final salt = await db.getMetadata('salt');
      final storedHash = await db.getMetadata('password_hash');

      if (salt == null || storedHash == null) return false;

      if (!CryptoService.verifyPassword(masterPassword, salt, storedHash)) {
        return false;
      }

      final encryptionKey = CryptoService.deriveKey(masterPassword, salt);
      ref.read(encryptionKeyProvider.notifier).state = encryptionKey;
      ref.read(databaseStateProvider.notifier).state = DatabaseState.unlocked;
      state = DatabaseState.unlocked;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Closes the database completely
  Future<void> closeDatabase() async {
    final db = ref.read(databaseProvider);
    if (db != null) {
      await db.close();
    }
    ref.read(databaseProvider.notifier).state = null;
    ref.read(databasePathProvider.notifier).state = null;
    ref.read(encryptionKeyProvider.notifier).state = null;
    ref.read(databaseStateProvider.notifier).state = DatabaseState.none;
    state = DatabaseState.none;
  }

  /// Changes the master password
  /// Returns true if successful, false if old password is wrong
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final db = ref.read(databaseProvider);
    if (db == null) return false;

    try {
      // Verify old password
      final oldSalt = await db.getMetadata('salt');
      final storedHash = await db.getMetadata('password_hash');

      if (oldSalt == null || storedHash == null) return false;

      if (!CryptoService.verifyPassword(oldPassword, oldSalt, storedHash)) {
        return false;
      }

      // Get old encryption key
      final oldEncryptionKey = CryptoService.deriveKey(oldPassword, oldSalt);

      // Generate new salt and hash
      final newSalt = CryptoService.generateSalt();
      final newPasswordHash = CryptoService.hashPassword(newPassword, newSalt);
      final newEncryptionKey = CryptoService.deriveKey(newPassword, newSalt);

      // Re-encrypt all entries
      final entries = await db.getAllEntries();
      for (final entry in entries) {
        String newPassword = entry.password;
        String newNotes = entry.notes;

        // Decrypt with old key, encrypt with new key
        if (entry.password.isNotEmpty) {
          try {
            final decrypted = CryptoService.decrypt(entry.password, oldEncryptionKey);
            newPassword = CryptoService.encrypt(decrypted, newEncryptionKey);
          } catch (e) {
            // Keep original if decryption fails
          }
        }

        if (entry.notes.isNotEmpty) {
          try {
            final decrypted = CryptoService.decrypt(entry.notes, oldEncryptionKey);
            newNotes = CryptoService.encrypt(decrypted, newEncryptionKey);
          } catch (e) {
            // Keep original if decryption fails
          }
        }

        // Update entry
        await db.updateEntry(EntriesCompanion(
          id: Value(entry.id),
          groupId: Value(entry.groupId),
          title: Value(entry.title),
          username: Value(entry.username),
          password: Value(newPassword),
          url: Value(entry.url),
          notes: Value(newNotes),
          createdAt: Value(entry.createdAt),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // Update metadata
      await db.setMetadata('salt', newSalt);
      await db.setMetadata('password_hash', newPasswordHash);

      // Update encryption key provider
      ref.read(encryptionKeyProvider.notifier).state = newEncryptionKey;

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Database notifier provider
final databaseNotifierProvider =
    StateNotifierProvider<DatabaseNotifier, DatabaseState>((ref) {
  return DatabaseNotifier(ref);
});
