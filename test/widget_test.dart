// This is a basic Flutter widget test for CityEase.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cityease/main.dart';

void main() {
  testWidgets('CityEase app loads welcome screen and transitions to onboarding', (WidgetTester tester) async {
    // 1. Load the app
    await tester.pumpWidget(const CityEaseApp());
    
    // We pump once instead of calling pumpAndSettle, because the parallax background
    // animation repeats infinitely and would cause pumpAndSettle to time out.
    await tester.pump();

    // 2. Verify WelcomeScreen is displayed
    expect(find.text('CityEase'), findsOneWidget);
    expect(find.textContaining('Smart Match Your'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // 3. Tap "Get Started" to trigger transition to onboarding
    await tester.tap(find.text('Get Started'));
    
    // Pump the frames for the PageRoute transition and settle into the chat onboarding screen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // 4. Verify that the ChatOnboardingScreen is loaded successfully
    expect(find.text('CityEase AI'), findsOneWidget);
    expect(find.text('Let\'s find your perfect neighborhood'), findsOneWidget);
  });
}
