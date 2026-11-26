import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/expense.dart';

class ExpensesRepository {
  const ExpensesRepository(this._database);

  final AppDatabase _database;

  Stream<List<Expense>> watchExpenses() {
    final query = _database.select(_database.expenses)
      ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]);

    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  Future<void> addExpense({
    required String merchant,
    required int amountMinorUnits,
    required DateTime occurredAt,
    String currencyCode = 'TRY',
    String? categoryId,
    String? note,
    String? receiptImagePath,
    String? recurringExpenseId,
  }) async {
    await _database
        .into(_database.expenses)
        .insert(
          ExpensesCompanion.insert(
            merchant: merchant,
            amountMinorUnits: amountMinorUnits,
            currencyCode: Value(currencyCode),
            occurredAt: occurredAt,
            categoryId: Value(categoryId),
            note: Value(note),
            receiptImagePath: Value(receiptImagePath),
            recurringExpenseId: Value(recurringExpenseId),
          ),
        );
  }

  Future<bool> updateExpense(Expense expense) async {
    final updatedRows =
        await (_database.update(
          _database.expenses,
        )..where((row) => row.id.equals(expense.id))).write(
          ExpensesCompanion(
            merchant: Value(expense.merchant),
            amountMinorUnits: Value(expense.amountMinorUnits),
            currencyCode: Value(expense.currencyCode),
            occurredAt: Value(expense.occurredAt),
            categoryId: Value(expense.categoryId),
            note: Value(expense.note),
            receiptImagePath: Value(expense.receiptImagePath),
            recurringExpenseId: Value(expense.recurringExpenseId),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows == 1;
  }

  Future<bool> deleteExpense(String id) async {
    final deletedRows = await (_database.delete(
      _database.expenses,
    )..where((row) => row.id.equals(id))).go();

    return deletedRows == 1;
  }

  Expense _toDomain(ExpenseRow row) {
    return Expense(
      id: row.id,
      merchant: row.merchant,
      amountMinorUnits: row.amountMinorUnits,
      currencyCode: row.currencyCode,
      occurredAt: row.occurredAt,
      categoryId: row.categoryId,
      note: row.note,
      receiptImagePath: row.receiptImagePath,
      recurringExpenseId: row.recurringExpenseId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
