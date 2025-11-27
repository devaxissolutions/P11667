import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/features/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('DevQuote'), findsOneWidget);
    // We can't easily test the navigation in a unit test without mocking GoRouter,
    // but we can verify the initial state.
  });
}
