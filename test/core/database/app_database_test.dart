import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('inserts and reads an expense with defaults', () async {
    final occurredAt = DateTime(2026, 11, 25);

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            merchant: 'Cafe',
            amountMinorUnits: 1234,
            occurredAt: occurredAt,
          ),
        );

    final expenses = await database.select(database.expenses).get();

    expect(expenses, hasLength(1));
    expect(expenses.single.id, isNotEmpty);
    expect(expenses.single.merchant, 'Cafe');
    expect(expenses.single.amountMinorUnits, 1234);
    expect(expenses.single.currencyCode, 'TRY');
    expect(expenses.single.occurredAt, occurredAt);
  });

  test('tracks inserts for every syncable table', () async {
    final category = await database
        .into(database.categories)
        .insertReturning(CategoriesCompanion.insert(name: 'Bills'));
    final recurringExpense = await database
        .into(database.recurringExpenses)
        .insertReturning(
          RecurringExpensesCompanion.insert(
            merchant: 'Phone bill',
            amountMinorUnits: 5000,
            categoryId: Value(category.id),
          ),
        );
    final expense = await database
        .into(database.expenses)
        .insertReturning(
          ExpensesCompanion.insert(
            merchant: 'Phone bill',
            amountMinorUnits: 5000,
            occurredAt: DateTime(2026, 11, 25),
            categoryId: Value(category.id),
            recurringExpenseId: Value(recurringExpense.id),
          ),
        );
    await database
        .into(database.monthlyBudgets)
        .insert(MonthlyBudgetsCompanion.insert(limitMinorUnits: 150000));

    final query = database.select(database.syncOperations)
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    final operations = await query.get();

    expect(operations.map((row) => row.entityType), [
      'categories',
      'recurring_expenses',
      'expenses',
      'monthly_budgets',
    ]);
    expect(operations.map((row) => row.entityId), [
      category.id,
      recurringExpense.id,
      expense.id,
      '1',
    ]);
    expect(operations.map((row) => row.operation), [
      'upsert',
      'upsert',
      'upsert',
      'upsert',
    ]);
  });

  test('keeps an expense when its category is deleted', () async {
    await database
        .into(database.categories)
        .insert(CategoriesCompanion.insert(name: 'Food'));

    final category = (await database.select(database.categories).get()).single;

    await database
        .into(database.expenses)
        .insert(
          ExpensesCompanion.insert(
            merchant: 'Cafe',
            amountMinorUnits: 1234,
            occurredAt: DateTime(2026, 11, 25),
            categoryId: Value(category.id),
          ),
        );

    await (database.delete(
      database.categories,
    )..where((row) => row.id.equals(category.id))).go();

    final expenses = await database.select(database.expenses).get();

    expect(expenses, hasLength(1));
    expect(expenses.single.categoryId, isNull);
  });

  test('queues inserts and keeps a tombstone after a local delete', () async {
    final expenseId = await database
        .into(database.expenses)
        .insertReturning(
          ExpensesCompanion.insert(
            merchant: 'Cafe',
            amountMinorUnits: 1234,
            occurredAt: DateTime(2026, 11, 25),
          ),
        )
        .then((row) => row.id);

    await (database.update(database.expenses)
          ..where((row) => row.id.equals(expenseId)))
        .write(const ExpensesCompanion(merchant: Value('Updated Cafe')));
    await (database.delete(
      database.expenses,
    )..where((row) => row.id.equals(expenseId))).go();

    final operations = await database.select(database.syncOperations).get();

    expect(operations, hasLength(3));
    expect(operations.map((row) => row.entityType), [
      'expenses',
      'expenses',
      'expenses',
    ]);
    expect(operations.map((row) => row.entityId), [
      expenseId,
      expenseId,
      expenseId,
    ]);
    expect(operations.map((row) => row.operation), [
      'upsert',
      'upsert',
      'delete',
    ]);
    expect(operations.every((row) => row.changedAtEpochMillis > 0), isTrue);
    expect(await database.select(database.expenses).get(), isEmpty);
  });
}
