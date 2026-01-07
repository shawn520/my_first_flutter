import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../database/app_database.dart';

/// Export file structure
class ExportData {
  final int version;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String checksum;
  final String encryptedData;

  ExportData({
    required this.version,
    required this.createdAt,
    this.expiresAt,
    required this.checksum,
    required this.encryptedData,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'checksum': checksum,
        'data': encryptedData,
      };

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
        version: json['version'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        checksum: json['checksum'] as String,
        encryptedData: json['data'] as String,
      );
}

/// Group export data
class GroupExportData {
  final String name;
  final int iconCode;
  final List<EntryExportData> entries;

  GroupExportData({
    required this.name,
    required this.iconCode,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconCode': iconCode,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory GroupExportData.fromJson(Map<String, dynamic> json) => GroupExportData(
        name: json['name'] as String,
        iconCode: json['iconCode'] as int,
        entries: (json['entries'] as List)
            .map((e) => EntryExportData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Entry export data
class EntryExportData {
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;

  EntryExportData({
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'username': username,
        'password': password,
        'url': url,
        'notes': notes,
      };

  factory EntryExportData.fromJson(Map<String, dynamic> json) => EntryExportData(
        title: json['title'] as String,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        url: json['url'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

/// Expiry duration options
enum ExpiryOption {
  oneHour,
  twentyFourHours,
  sevenDays,
  thirtyDays,
  never,
  custom,
}

extension ExpiryOptionExtension on ExpiryOption {
  String get label {
    switch (this) {
      case ExpiryOption.oneHour:
        return '1 Hour';
      case ExpiryOption.twentyFourHours:
        return '24 Hours';
      case ExpiryOption.sevenDays:
        return '7 Days';
      case ExpiryOption.thirtyDays:
        return '30 Days';
      case ExpiryOption.never:
        return 'Never';
      case ExpiryOption.custom:
        return 'Custom';
    }
  }

  Duration? get duration {
    switch (this) {
      case ExpiryOption.oneHour:
        return const Duration(hours: 1);
      case ExpiryOption.twentyFourHours:
        return const Duration(hours: 24);
      case ExpiryOption.sevenDays:
        return const Duration(days: 7);
      case ExpiryOption.thirtyDays:
        return const Duration(days: 30);
      case ExpiryOption.never:
        return null;
      case ExpiryOption.custom:
        return null;
    }
  }
}

class ExportService {
  static const int _keyLength = 32;
  static const int _ivLength = 16;
  static const int _currentVersion = 1;

  /// Generates a random password
  static String generateRandomPassword({int length = 16}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Derives encryption key from password
  static Uint8List _deriveKey(String password) {
    List<int> hash = utf8.encode(password);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    return Uint8List.fromList(hash.sublist(0, _keyLength));
  }

  /// Encrypts data with password
  static String _encrypt(String plainText, String password) {
    final keyBytes = _deriveKey(password);
    final key = Key(keyBytes);
    final iv = IV.fromSecureRandom(_ivLength);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  /// Calculates checksum for data integrity
  static String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Exports groups to encrypted file
  static Future<void> exportGroups({
    required List<Group> groups,
    required Map<int, List<Entry>> entriesByGroup,
    required String filePath,
    required String password,
    required DateTime? expiresAt,
    required Uint8List? dbEncryptionKey,
    required String Function(String, Uint8List) decryptField,
  }) async {
    // Prepare export data
    final groupsData = <GroupExportData>[];

    for (final group in groups) {
      final entries = entriesByGroup[group.id] ?? [];
      final entriesData = entries.map((entry) {
        // Decrypt sensitive fields before export
        String decryptedPassword = entry.password;
        String decryptedNotes = entry.notes;

        if (dbEncryptionKey != null) {
          if (entry.password.isNotEmpty) {
            try {
              decryptedPassword = decryptField(entry.password, dbEncryptionKey);
            } catch (_) {}
          }
          if (entry.notes.isNotEmpty) {
            try {
              decryptedNotes = decryptField(entry.notes, dbEncryptionKey);
            } catch (_) {}
          }
        }

        return EntryExportData(
          title: entry.title,
          username: entry.username,
          password: decryptedPassword,
          url: entry.url,
          notes: decryptedNotes,
        );
      }).toList();

      groupsData.add(GroupExportData(
        name: group.name,
        iconCode: group.iconCode,
        entries: entriesData,
      ));
    }

    // Convert to JSON
    final jsonData = jsonEncode(groupsData.map((g) => g.toJson()).toList());

    // Calculate checksum before encryption
    final checksum = _calculateChecksum(jsonData);

    // Encrypt with export password
    final encryptedData = _encrypt(jsonData, password);

    // Create export file structure
    final exportData = ExportData(
      version: _currentVersion,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      checksum: checksum,
      encryptedData: encryptedData,
    );

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonEncode(exportData.toJson()));
  }
}
