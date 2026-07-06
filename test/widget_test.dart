import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cityease/main.dart';
import 'package:cityease/utils/app_theme.dart';

void main() {
  testWidgets('CityEase app uses the premium dark palette', (WidgetTester tester) async {
    await tester.pumpWidget(const CityEaseApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);

    expect(theme.scaffoldBackgroundColor, AppTheme.primaryBackground);
    expect(theme.colorScheme.primary, const Color(0xFF7C5CFF));
    expect(theme.colorScheme.secondary, const Color(0xFF38BDF8));
  });

  testWidgets('CityEase app loads welcome screen and transitions to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const CityEaseApp());

    // We pump once instead of calling pumpAndSettle, because the parallax background
    // animation repeats infinitely and would cause pumpAndSettle to time out.
    await tester.pump();

    expect(find.text('CityEase'), findsOneWidget);
    expect(find.textContaining('Smart Match Your'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('CityEase AI'), findsOneWidget);
    expect(find.text('Let\'s find your perfect neighborhood'), findsOneWidget);
  });
}
