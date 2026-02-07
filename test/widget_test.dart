// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';

import 'package:neocentral/main.dart';
import 'package:neocentral/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeoCentralApp());

    // Verify splash screen is displayed
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('NEOCENTRAL'), findsOneWidget);
  });
}
