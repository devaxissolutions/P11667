import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_quotes/core/widgets/primary_button.dart';
import 'package:dev_quotes/core/widgets/secondary_button.dart';
import 'package:dev_quotes/core/widgets/selectable_chip.dart';
import 'package:dev_quotes/core/widgets/app_text_field.dart';
import 'package:dev_quotes/core/widgets/app_card.dart';

void main() {
  testWidgets('UI Components render correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PrimaryButton(text: 'Primary', onPressed: () {}),
              SecondaryButton(text: 'Secondary', onPressed: () {}),
              SelectableChip(label: 'Chip', isSelected: true, onTap: () {}),
              const AppTextField(hintText: 'Input'),
              const AppCard(child: Text('Card')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
    expect(find.text('Chip'), findsOneWidget);
    expect(find.text('Input'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
  });
}
