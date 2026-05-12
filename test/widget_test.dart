import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yojana_mitra_app/main.dart';

void main() {
  testWidgets('BharatMitra finds schemes from the starter profile', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences with setup_complete = true to skip OOBE
    SharedPreferences.setMockInitialValues({
      'setup_complete': true,
      'user_name': 'Test User',
      'user_state': 'Maharashtra',
      'user_occupation': 'Farmer',
      'user_family_size': 4,
      'user_language': 'Simple English',
    });

    await tester.pumpWidget(const BharatMitraApp());

    expect(find.text('BharatMitra'), findsOneWidget);
    expect(find.text('Find schemes'), findsOneWidget);

    await tester.ensureVisible(find.text('Find schemes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find schemes'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('BharatMitra local services'),
      220,
      maxScrolls: 4,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('BharatMitra local services'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Best schemes for you'),
      320,
      maxScrolls: 8,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Best schemes for you'), findsOneWidget);
    expect(find.text('Widow Pension Support'), findsOneWidget);
  });
}
