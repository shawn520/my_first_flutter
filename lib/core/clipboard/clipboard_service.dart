import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static Timer? _clearTimer;
  static const Duration defaultClearDuration = Duration(seconds: 30);

  /// Copies text to clipboard and optionally clears after duration
  static Future<void> copy(
    String text, {
    Duration? clearAfter = defaultClearDuration,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (clearAfter != null) {
      _scheduleClear(clearAfter);
    }
  }

  /// Schedules clipboard clear
  static void _scheduleClear(Duration duration) {
    _clearTimer?.cancel();
    _clearTimer = Timer(duration, () {
      clear();
    });
  }

  /// Clears the clipboard
  static Future<void> clear() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  /// Cancels any pending clear operation
  static void cancelClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
