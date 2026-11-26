import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/database/database_provider.dart';
import 'package:fisly/features/recurring_expenses/data/recurring_expenses_repository.dart';
import 'package:fisly/features/reports/presentation/monthly_report_screen.dart';
import 'package:flutter/foundation.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show SizedBox, Text;
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shows current-month totals and recurring/one-time split', (
    tester,
  ) async {
    final now = DateTime.now();
    final paidAt = DateTime(now.year, now.month, 5);
    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            merchant: 'Cafe',
            amountMinorUnits: 2500,
            occurredAt: DateTime(now.year, now.month, 8),
          ),
        );
    final recurringId = await RecurringExpensesRepository(database)
        .addRecurringExpense(merchant: 'Netflix', amountMinorUnits: 1299);
    await RecurringExpensesRepository(database)
        .recordPayment(recurringId, paidAt: paidAt);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: MonthlyReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('report-monthly-total'))).data,
      '₺37,99',
    );
    expect(find.text('Düzenli ödemeler'), findsOneWidget);
    expect(find.text('Tek seferlik'), findsOneWidget);
    expect(find.text('₺12,99'), findsWidgets);
    expect(find.text('₺25,00'), findsWidgets);
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
