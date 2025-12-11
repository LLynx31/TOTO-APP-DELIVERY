import 'package:flutter_test/flutter_test.dart';
import 'package:toto_client/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TotoApp());

    // Verify that the login screen loads
    expect(find.text('Bienvenue !'), findsOneWidget);
  });
}
