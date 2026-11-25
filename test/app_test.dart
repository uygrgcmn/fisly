import 'package:drift/native.dart';
import 'package:fisly/app.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/database/database_provider.dart';
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

  testWidgets('shows the empty expenses screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const FislyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fisly'), findsOneWidget);
    expect(find.text('Henüz harcama yok'), findsOneWidget);
    expect(
      find.text('Fişlerini ve harcamalarını tek yerde takip et.'),
      findsOneWidget,
    );
    expect(find.text('Yemek'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
