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
}
