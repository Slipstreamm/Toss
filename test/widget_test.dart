// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:filesharingapp/main.dart';

void main() {
  testWidgets('App loads and displays title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FileSharingApp());

    // Verify that the app bar title is displayed.
    expect(find.text('LAN File Share'), findsOneWidget);

    // Verify that the initial status text is present (can be improved)
    expect(find.textContaining('Status:'), findsOneWidget);

    // Verify that the IP address text is present (can be improved)
    expect(find.textContaining('Your IP Address:'), findsOneWidget);
  });
}
