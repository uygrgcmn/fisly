import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(appDatabaseProvider));
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchExpenses();
});
