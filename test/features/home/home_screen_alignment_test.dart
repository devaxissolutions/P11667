import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_quotes/data/models/quote_model.dart';
import 'package:dev_quotes/features/home/presentation/screens/home_screen.dart';
import 'package:dev_quotes/features/quotes/presentation/providers/quote_provider.dart';

class MockQuotesNotifier extends QuotesNotifier {
  MockQuotesNotifier(this.quotes);

  final List<Quote> quotes;

  @override
  AsyncValue<List<Quote>> build() {
    return AsyncValue.data(quotes);
  }
}

class MockCurrentQuoteIndexNotifier extends CurrentQuoteIndexNotifier {
  MockCurrentQuoteIndexNotifier(int initial) {
    state = initial;
  }
}

void main() {
  testWidgets('HomeScreen quote and author are centered', (
    WidgetTester tester,
  ) async {
    final userQuote = Quote(
      id: '1',
      text: '  This is quotes !',
      author: '  Sam Martin  ',
      category: 'UX',
      userId: 'test',
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quotesProvider.overrideWith(() => MockQuotesNotifier([userQuote])),
          currentQuoteIndexProvider.overrideWith(
            () => MockCurrentQuoteIndexNotifier(0),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final quoteFinder = find.text('"This is quotes !"');
    final authorFinder = find.text('- Sam Martin');

    expect(quoteFinder, findsOneWidget);
    expect(authorFinder, findsOneWidget);

    final quoteContainer = tester.widget<Container>(
      find.ancestor(of: quoteFinder, matching: find.byType(Container)).first,
    );
    final authorContainer = tester.widget<Container>(
      find.ancestor(of: authorFinder, matching: find.byType(Container)).first,
    );

    expect(quoteContainer.alignment, Alignment.center);
    expect(authorContainer.alignment, Alignment.center);

    final quoteText = tester.widget<Text>(quoteFinder);
    final authorText = tester.widget<Text>(authorFinder);

    expect(quoteText.textAlign, TextAlign.center);
    expect(authorText.textAlign, TextAlign.center);
  });
}
