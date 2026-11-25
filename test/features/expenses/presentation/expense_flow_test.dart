import 'package:drift/native.dart';
import 'package:fisly/app.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/database/database_provider.dart';
import 'package:flutter/foundation.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('creates, edits, and deletes an expense with a category', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-expense-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('merchant-field')), 'Cafe');
    await tester.enterText(find.byKey(const Key('amount-field')), '12,34');
    await tester.tap(find.byKey(const Key('category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yemek').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cafe'), findsOneWidget);
    expect(find.textContaining('Yemek'), findsOneWidget);
    expect(find.text('₺12,34'), findsOneWidget);

    await tester.tap(find.byTooltip('Harcama işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('merchant-field')),
      'Updated Cafe',
    );
    await tester.tap(find.byKey(const Key('save-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('Updated Cafe'), findsOneWidget);
    expect(find.text('Cafe'), findsNothing);

    await tester.tap(find.byTooltip('Harcama işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-button')));
    await tester.pumpAndSettle();

    expect(find.text('Henüz harcama yok'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
