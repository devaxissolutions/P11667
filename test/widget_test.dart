import 'package:flutter_test/flutter_test.dart';
import 'package:dev_quotes/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DevQuoteApp()));
    await tester.pumpAndSettle();
    expect(find.text('DevQuote Home Placeholder'), findsOneWidget);
  });
}
