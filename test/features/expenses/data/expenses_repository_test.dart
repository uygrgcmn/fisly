import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/features/expenses/data/expenses_repository.dart';
import 'package:fisly/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ExpensesRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = ExpensesRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('supports adding, watching, updating, and deleting expenses', () async {
    final earlierDate = DateTime(2026, 11, 24);
    final laterDate = DateTime(2026, 11, 25);

    await repository.addExpense(
      merchant: 'Cafe',
      amountMinorUnits: 1234,
      occurredAt: earlierDate,
    );
    await repository.addExpense(
      merchant: 'Market',
      amountMinorUnits: 2400,
      occurredAt: laterDate,
    );

    final expenses = await repository.watchExpenses().first;

    expect(expenses.map((expense) => expense.merchant), ['Market', 'Cafe']);
    expect(expenses.first.currencyCode, 'TRY');

    final original = expenses.first;
    final updated = Expense(
      id: original.id,
      merchant: 'Updated Market',
      amountMinorUnits: 2500,
      currencyCode: original.currencyCode,
      occurredAt: original.occurredAt,
      categoryId: original.categoryId,
      note: 'Groceries',
      receiptImagePath: original.receiptImagePath,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
    );

    expect(await repository.updateExpense(updated), isTrue);

    final afterUpdate = await repository.watchExpenses().first;
    expect(afterUpdate.first.merchant, 'Updated Market');
    expect(afterUpdate.first.amountMinorUnits, 2500);
    expect(afterUpdate.first.note, 'Groceries');

    expect(await repository.deleteExpense(original.id), isTrue);

    final afterDelete = await repository.watchExpenses().first;
    expect(afterDelete, hasLength(1));
    expect(afterDelete.single.merchant, 'Cafe');
  });
}
