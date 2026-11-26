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

  testWidgets('creates, renames, and deletes a custom category', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-management-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage-categories-menu-item')));
    await tester.pumpAndSettle();
    expect(find.text('Alışveriş'), findsOneWidget);
    expect(find.text('Varsayılan'), findsWidgets);

    await tester.tap(find.byKey(const Key('add-category-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Pets',
    );
    await tester.tap(find.byKey(const Key('save-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pets'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Kategori işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kategori işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Pet care',
    );
    await tester.tap(find.byKey(const Key('save-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pet care'), findsOneWidget);
    expect(find.text('Pets'), findsNothing);

    await tester.ensureVisible(find.byTooltip('Kategori işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kategori işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pet care'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
