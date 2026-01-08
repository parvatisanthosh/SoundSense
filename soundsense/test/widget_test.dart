// Basic widget test for Dhwani/SoundSense app

import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SoundSenseApp());

    // Verify that the app title is displayed
    expect(find.text('Dhwani'), findsOneWidget);
  });
}