import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/recurring_expense.dart';

class RecurringExpensesRepository {
  const RecurringExpensesRepository(this._database);

  final AppDatabase _database;

  Stream<List<RecurringExpense>> watchRecurringExpenses() {
    final query = _database.select(_database.recurringExpenses)
      ..orderBy([(row) => OrderingTerm.asc(row.merchant)]);

    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  Future<String> addRecurringExpense({
    required String merchant,
    required int amountMinorUnits,
    String? categoryId,
    String? note,
  }) async {
    return _database
        .into(_database.recurringExpenses)
        .insertReturning(
          RecurringExpensesCompanion.insert(
            merchant: merchant,
            amountMinorUnits: amountMinorUnits,
            categoryId: Value(categoryId),
            note: Value(note),
          ),
        )
        .then((row) => row.id);
  }

  Future<bool> updateRecurringExpense(RecurringExpense expense) async {
    final updatedRows =
        await (_database.update(
          _database.recurringExpenses,
        )..where((row) => row.id.equals(expense.id))).write(
          RecurringExpensesCompanion(
            merchant: Value(expense.merchant),
            amountMinorUnits: Value(expense.amountMinorUnits),
            categoryId: Value(expense.categoryId),
            note: Value(expense.note),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return updatedRows == 1;
  }

  Future<bool> setActive(String id, {required bool isActive}) async {
    final updatedRows =
        await (_database.update(
          _database.recurringExpenses,
        )..where((row) => row.id.equals(id))).write(
          RecurringExpensesCompanion(
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return updatedRows == 1;
  }

  Future<bool> recordPayment(String id, {required DateTime paidAt}) {
    return _database.transaction(() async {
      final recurring = await (_database.select(
        _database.recurringExpenses,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (recurring == null || !recurring.isActive) return false;

      final lastPaidAt = recurring.lastPaidAt;
      if (lastPaidAt != null &&
          lastPaidAt.year == paidAt.year &&
          lastPaidAt.month == paidAt.month) {
        return false;
      }

      await _database
          .into(_database.expenses)
          .insert(
            ExpensesCompanion.insert(
              merchant: recurring.merchant,
              amountMinorUnits: recurring.amountMinorUnits,
              occurredAt: paidAt,
              categoryId: Value(recurring.categoryId),
              note: Value(recurring.note),
              recurringExpenseId: Value(recurring.id),
            ),
          );
      await (_database.update(
        _database.recurringExpenses,
      )..where((row) => row.id.equals(id))).write(
        RecurringExpensesCompanion(
          lastPaidAt: Value(paidAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    });
  }

  RecurringExpense _toDomain(RecurringExpenseRow row) {
    return RecurringExpense(
      id: row.id,
      merchant: row.merchant,
      amountMinorUnits: row.amountMinorUnits,
      categoryId: row.categoryId,
      note: row.note,
      isActive: row.isActive,
      lastPaidAt: row.lastPaidAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
