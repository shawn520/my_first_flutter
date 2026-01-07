import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_flutter/app.dart';

void main() {
  testWidgets('App shows welcome screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PasswordManagerApp(),
      ),
    );

    expect(find.text('Password Manager'), findsOneWidget);
    expect(find.text('Create New Database'), findsOneWidget);
    expect(find.text('Open Existing Database'), findsOneWidget);
  });
}
