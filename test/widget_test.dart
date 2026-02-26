// Basic smoke test for the Daraz Clone app.
// The full app requires async setup (SharedPreferences) so we just verify
// the widget tree can be pumped without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daraz_clone/main.dart';
import 'package:daraz_clone/shared/providers/shared_preferences_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Provide a fake SharedPreferences so the auth provider doesn't error.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DarazApp(),
      ),
    );

    // The app should start on the login screen.
    await tester.pump();
    expect(find.text('Daraz Clone'), findsAny);
  });
}
