import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_beach_guard/main.dart';

void main() {
  testWidgets('Smart Beach Guard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartBeachGuardApp());

    // Verify that our app starts successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}