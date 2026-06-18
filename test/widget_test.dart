import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardrobe_ai/main.dart';

void main() {
  testWidgets('Onboarding Smoke Test', (WidgetTester tester) async {
    // Mock shared preferences initial state
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WardrobeAIApp());

    // Allow asynchronous operations (loading prefs) to complete and rebuild
    await tester.pumpAndSettle();

    // Verify that the onboarding screen has rendered
    expect(find.text('Wardrobe AI'), findsOneWidget);
    expect(find.text('Stil Profilimi Kaydet'), findsOneWidget);
  });
}
