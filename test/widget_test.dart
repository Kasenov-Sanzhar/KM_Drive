import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:km_drive/main.dart';

// ============================================================
// KM DRIVE — Widget Tests
// ✅ Исправлено: KmDriveApp вместо MyApp
// ============================================================

void main() {
  testWidgets('KM Drive app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const KmDriveApp());
    // Splash screen появляется при запуске
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}