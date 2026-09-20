// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:plantapulse/main.dart';

void main() {
  testWidgets('App inicia y muestra la pantalla de splash', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlantaPulseApp());

    // Verify that the splash screen is shown on startup.
    expect(find.text('Gestión de planta en tiempo real'), findsOneWidget);
  });
}
