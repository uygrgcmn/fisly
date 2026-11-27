import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/categories/data/categories_table.dart';
import '../../features/budgets/data/monthly_budgets_table.dart';
import '../../features/expenses/data/expenses_table.dart';
import '../../features/recurring_expenses/data/recurring_expenses_table.dart';
import 'sync_category_mappings_table.dart';
import 'sync_import_consents_table.dart';
import 'sync_operation_acknowledgements_table.dart';
import 'sync_operations_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Expenses,
    MonthlyBudgets,
    RecurringExpenses,
    SyncCategoryMappings,
    SyncImportConsents,
    SyncOperations,
    SyncOperationAcknowledgements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

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
      if (from < 5) {
        await migrator.createTable(syncOperations);
      }
      if (from < 6) {
        await migrator.createTable(syncImportConsents);
      }
      if (from < 7) {
        await migrator.createTable(syncCategoryMappings);
      }
      if (from < 8) {
        await migrator.createTable(syncOperationAcknowledgements);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createSyncOperationTriggers();
    },
  );

  Future<void> _createSyncOperationTriggers() async {
    const trackedTables = {
      'categories': 'id',
      'expenses': 'id',
      'recurring_expenses': 'id',
      'monthly_budgets': 'id',
    };
    const events = ['INSERT', 'UPDATE', 'DELETE'];

    for (final entry in trackedTables.entries) {
      for (final event in events) {
        final triggerName = '${entry.key}_sync_${event.toLowerCase()}';
        final rowName = event == 'DELETE' ? 'OLD' : 'NEW';
        final entityId = entry.key == 'monthly_budgets'
            ? 'CAST($rowName.${entry.value} AS TEXT)'
            : '$rowName.${entry.value}';
        final operation = event == 'DELETE' ? 'delete' : 'upsert';

        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS $triggerName
          AFTER $event ON ${entry.key}
          BEGIN
            INSERT INTO sync_operations (
              entity_type,
              entity_id,
              operation,
              changed_at_epoch_millis
            )
            VALUES (
              '${entry.key}',
              $entityId,
              '$operation',
              CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)
            );
          END
        ''');
      }
    }
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'fisly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
