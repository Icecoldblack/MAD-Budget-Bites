import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/widgets/purchase_tile.dart';

Widget buildTile(Purchase purchase, String title, {bool showDate = true}) {
  return MaterialApp(
    home: Scaffold(
      body: PurchaseTile(
        purchase: purchase,
        title: title,
        showDate: showDate,
        onTap: () {},
        onDelete: () {},
      ),
    ),
  );
}

void main() {
  final withNote = Purchase(
    id: 1,
    mealId: 1,
    purchasedAt: DateTime(2026, 10, 25),
    actualPriceMinor: 500,
    note: 'Extra egg',
  );
  final noNote = Purchase(
    id: 2,
    mealId: 1,
    purchasedAt: DateTime(2026, 10, 25),
    actualPriceMinor: 500,
    note: '',
  );

  testWidgets('history row: meal name, then date and note', (tester) async {
    await tester.pumpWidget(buildTile(withNote, 'Fried Rice'));

    expect(find.text('Fried Rice'), findsOneWidget);
    expect(find.text('2026-10-25  •  Extra egg'), findsOneWidget);
  });

  testWidgets('detail row: the date shows only once', (tester) async {
    await tester.pumpWidget(
      buildTile(noNote, '2026-10-25', showDate: false),
    );

    expect(find.text('2026-10-25'), findsOneWidget);
  });

  testWidgets('detail row with a note shows just the note under the date',
      (tester) async {
    await tester.pumpWidget(
      buildTile(withNote, '2026-10-25', showDate: false),
    );

    expect(find.text('2026-10-25'), findsOneWidget);
    expect(find.text('Extra egg'), findsOneWidget);
  });
}
