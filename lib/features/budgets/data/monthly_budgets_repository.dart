import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/monthly_budget.dart';

class MonthlyBudgetsRepository {
  const MonthlyBudgetsRepository(this._database);

  final AppDatabase _database;

  Stream<MonthlyBudget?> watchMonthlyBudget() {
    return (_database.select(
      _database.monthlyBudgets,
    )..where((row) => row.id.equals(1))).watchSingleOrNull().map(
      (row) => row == null
          ? null
          : MonthlyBudget(
              limitMinorUnits: row.limitMinorUnits,
              updatedAt: row.updatedAt,
            ),
    );
  }

  Future<void> setMonthlyLimit(int limitMinorUnits) async {
    if (limitMinorUnits <= 0) {
      throw ArgumentError.value(
        limitMinorUnits,
        'limitMinorUnits',
        'Monthly budget must be positive.',
      );
    }

    await _database
        .into(_database.monthlyBudgets)
        .insertOnConflictUpdate(
          MonthlyBudgetsCompanion.insert(
            id: const Value(1),
            limitMinorUnits: limitMinorUnits,
          ),
        );
  }
}
