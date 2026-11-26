import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/categories/data/categories_table.dart';
import '../../features/budgets/data/monthly_budgets_table.dart';
import '../../features/expenses/data/expenses_table.dart';
import '../../features/recurring_expenses/data/recurring_expenses_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Expenses, MonthlyBudgets, RecurringExpenses],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(monthlyBudgets);
      }
      if (from < 3) {
        await migrator.createTable(recurringExpenses);
      }
      if (from < 4) {
        await migrator.addColumn(expenses, expenses.recurringExpenseId);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'fisly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
