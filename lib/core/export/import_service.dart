import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'export_service.dart';

/// Import result
enum ImportResult {
  success,
  fileNotFound,
  invalidFormat,
  expired,
  wrongPassword,
  checksumMismatch,
  error,
}

extension ImportResultExtension on ImportResult {
  String get message {
    switch (this) {
      case ImportResult.success:
        return 'Import successful';
      case ImportResult.fileNotFound:
        return 'File not found';
      case ImportResult.invalidFormat:
        return 'Invalid file format';
      case ImportResult.expired:
        return 'Export file has expired';
      case ImportResult.wrongPassword:
        return 'Wrong password';
      case ImportResult.checksumMismatch:
        return 'File corrupted or tampered';
      case ImportResult.error:
        return 'Unknown error occurred';
    }
  }
}

/// Import result with data
class ImportResponse {
  final ImportResult result;
  final List<GroupExportData>? groups;
  final String? errorMessage;

  ImportResponse({
    required this.result,
    this.groups,
    this.errorMessage,
  });

  bool get isSuccess => result == ImportResult.success;
}

class ImportService {
  static const int _keyLength = 32;
  static const int _ivLength = 16;

  /// Derives encryption key from password
  static Uint8List _deriveKey(String password) {
    List<int> hash = utf8.encode(password);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    return Uint8List.fromList(hash.sublist(0, _keyLength));
  }

  /// Decrypts data with password
  static String? _decrypt(String encryptedText, String password) {
    try {
      final combined = base64.decode(encryptedText);
      final ivBytes = combined.sublist(0, _ivLength);
      final encryptedBytes = combined.sublist(_ivLength);

      final keyBytes = _deriveKey(password);
      final key = Key(keyBytes);
      final iv = IV(Uint8List.fromList(ivBytes));
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      return encrypter.decrypt(
        Encrypted(Uint8List.fromList(encryptedBytes)),
        iv: iv,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculates checksum for verification
  static String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Imports groups from encrypted file
  static Future<ImportResponse> importGroups({
    required String filePath,
    required String password,
  }) async {
    try {
      // Check file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResponse(result: ImportResult.fileNotFound);
      }

      // Read file
      final content = await file.readAsString();

      // Parse JSON
      Map<String, dynamic> json;
      try {
        json = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        return ImportResponse(result: ImportResult.invalidFormat);
      }

      // Parse export data
      ExportData exportData;
      try {
        exportData = ExportData.fromJson(json);
      } catch (e) {
        return ImportResponse(result: ImportResult.invalidFormat);
      }

      // Check expiry
      if (exportData.expiresAt != null &&
          DateTime.now().isAfter(exportData.expiresAt!)) {
        return ImportResponse(
          result: ImportResult.expired,
          errorMessage:
              'File expired on ${_formatDate(exportData.expiresAt!)}',
        );
      }

      // Decrypt data
      final decryptedData = _decrypt(exportData.encryptedData, password);
      if (decryptedData == null) {
        return ImportResponse(result: ImportResult.wrongPassword);
      }

      // Verify checksum
      final calculatedChecksum = _calculateChecksum(decryptedData);
      if (calculatedChecksum != exportData.checksum) {
        return ImportResponse(result: ImportResult.checksumMismatch);
      }

      // Parse groups data
      List<GroupExportData> groups;
      try {
        final groupsList = jsonDecode(decryptedData) as List;
        groups = groupsList
            .map((g) => GroupExportData.fromJson(g as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return ImportResponse(result: ImportResult.invalidFormat);
      }

      return ImportResponse(
        result: ImportResult.success,
        groups: groups,
      );
    } catch (e) {
      return ImportResponse(
        result: ImportResult.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Generates unique name if conflict exists
  static String generateUniqueName(String baseName, Set<String> existingNames) {
    if (!existingNames.contains(baseName)) {
      return baseName;
    }

    int counter = 1;
    String newName;
    do {
      newName = '$baseName ($counter)';
      counter++;
    } while (existingNames.contains(newName));

    return newName;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
