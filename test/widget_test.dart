import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayerreminder_app/main.dart';

void main() {
  testWidgets('ArabicText shows its text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ArabicText('تجربة'))),
    );
    expect(find.text('تجربة'), findsOneWidget);
  });
}