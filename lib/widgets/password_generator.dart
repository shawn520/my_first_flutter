import 'dart:math';
import 'package:flutter/material.dart';

class PasswordGenerator extends StatefulWidget {
  final Function(String) onGenerated;

  const PasswordGenerator({super.key, required this.onGenerated});

  @override
  State<PasswordGenerator> createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  double _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _digits = true;
  bool _symbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    String chars = '';
    if (_uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_digits) chars += '0123456789';
    if (_symbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    if (chars.isEmpty) {
      setState(() => _generatedPassword = '');
      return;
    }

    final random = Random.secure();
    final password = List.generate(
      _length.round(),
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    setState(() => _generatedPassword = password);
  }

  double _calculateStrength() {
    if (_generatedPassword.isEmpty) return 0;

    double strength = 0;
    final length = _generatedPassword.length;

    // Length contribution
    strength += (length / 32).clamp(0, 0.4);

    // Character variety contribution
    if (_uppercase) strength += 0.15;
    if (_lowercase) strength += 0.15;
    if (_digits) strength += 0.15;
    if (_symbols) strength += 0.15;

    return strength.clamp(0, 1);
  }

  Color _getStrengthColor() {
    final strength = _calculateStrength();
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStrengthText() {
    final strength = _calculateStrength();
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Password Generator'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generated password display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _generatedPassword.isEmpty ? 'Select options' : _generatedPassword,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Strength indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _calculateStrength(),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: _getStrengthColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getStrengthText(),
                  style: TextStyle(
                    color: _getStrengthColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Length slider
            Row(
              children: [
                const Text('Length: '),
                Expanded(
                  child: Slider(
                    value: _length,
                    min: 4,
                    max: 64,
                    divisions: 60,
                    label: _length.round().toString(),
                    onChanged: (value) {
                      setState(() => _length = value);
                      _generatePassword();
                    },
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    _length.round().toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Character options
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('A-Z'),
                  selected: _uppercase,
                  onSelected: (value) {
                    setState(() => _uppercase = value);
                    _generatePassword();
                  },
                ),
                FilterChip(
                  label: const Text('a-z'),
                  selected: _lowercase,
                  onSelected: (value) {
                    setState(() => _lowercase = value);
                    _generatePassword();
                  },
                ),
                FilterChip(
                  label: const Text('0-9'),
                  selected: _digits,
                  onSelected: (value) {
                    setState(() => _digits = value);
                    _generatePassword();
                  },
                ),
                FilterChip(
                  label: const Text('!@#\$'),
                  selected: _symbols,
                  onSelected: (value) {
                    setState(() => _symbols = value);
                    _generatePassword();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Regenerate button
            OutlinedButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _generatedPassword.isEmpty
              ? null
              : () {
                  widget.onGenerated(_generatedPassword);
                  Navigator.pop(context);
                },
          child: const Text('Use Password'),
        ),
      ],
    );
  }
}
