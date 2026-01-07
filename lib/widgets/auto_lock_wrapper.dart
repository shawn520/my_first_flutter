import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/settings_provider.dart';

/// A widget that monitors user activity and auto-locks the database after inactivity
class AutoLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AutoLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends ConsumerState<AutoLockWrapper> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();

    final dbState = ref.read(databaseStateProvider);
    if (dbState != DatabaseState.unlocked) return;

    final autoLockDuration = ref.read(autoLockDurationProvider);
    if (autoLockDuration == null) return; // Never lock

    _inactivityTimer = Timer(autoLockDuration, _lockDatabase);
  }

  void _lockDatabase() {
    final dbState = ref.read(databaseStateProvider);
    if (dbState == DatabaseState.unlocked) {
      ref.read(databaseNotifierProvider.notifier).lockDatabase();
    }
  }

  void _onUserActivity() {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for settings changes to update timer
    final autoLockDuration = ref.watch(autoLockDurationProvider);
    final dbState = ref.watch(databaseStateProvider);

    // Reset timer when settings change or database becomes unlocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dbState == DatabaseState.unlocked && autoLockDuration != null) {
        _resetTimer();
      } else {
        _inactivityTimer?.cancel();
      }
    });

    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerUp: (_) => _onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (_) => _onUserActivity(),
        child: widget.child,
      ),
    );
  }
}
