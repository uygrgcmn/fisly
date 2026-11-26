import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/features/recurring_expenses/data/recurring_expenses_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late RecurringExpensesRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = RecurringExpensesRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'records a monthly payment once and allows it again next month',
    () async {
      final recurringId = await repository.addRecurringExpense(
        merchant: 'Netflix',
        amountMinorUnits: 19999,
        note: 'Monthly subscription',
      );
      final novemberPayment = DateTime(2026, 11, 25);

      expect(
        await repository.recordPayment(recurringId, paidAt: novemberPayment),
        isTrue,
      );
      expect(
        await repository.recordPayment(
          recurringId,
          paidAt: DateTime(2026, 11, 28),
        ),
        isFalse,
      );

      final novemberExpenses = await database.select(database.expenses).get();
      expect(novemberExpenses, hasLength(1));
      expect(novemberExpenses.single.merchant, 'Netflix');
      expect(novemberExpenses.single.amountMinorUnits, 19999);
      expect(novemberExpenses.single.note, 'Monthly subscription');
      expect(novemberExpenses.single.recurringExpenseId, recurringId);

      expect(
        await repository.recordPayment(
          recurringId,
          paidAt: DateTime(2026, 12, 1),
        ),
        isTrue,
      );
      expect(await database.select(database.expenses).get(), hasLength(2));
    },
  );

  test('does not record payments for inactive or missing templates', () async {
    final recurringId = await repository.addRecurringExpense(
      merchant: 'Phone bill',
      amountMinorUnits: 50000,
    );
    await repository.setActive(recurringId, isActive: false);

    expect(
      await repository.recordPayment(
        recurringId,
        paidAt: DateTime(2026, 11, 25),
      ),
      isFalse,
    );
    expect(
      await repository.recordPayment('missing', paidAt: DateTime(2026, 11, 25)),
      isFalse,
    );
    expect(await database.select(database.expenses).get(), isEmpty);
  });
}
