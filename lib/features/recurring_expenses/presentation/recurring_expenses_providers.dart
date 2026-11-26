import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/recurring_expenses_repository.dart';
import '../domain/recurring_expense.dart';

final recurringExpensesRepositoryProvider =
    Provider<RecurringExpensesRepository>((ref) {
      return RecurringExpensesRepository(ref.watch(appDatabaseProvider));
    });

final recurringExpensesProvider = StreamProvider<List<RecurringExpense>>((ref) {
  return ref
      .watch(recurringExpensesRepositoryProvider)
      .watchRecurringExpenses();
});
