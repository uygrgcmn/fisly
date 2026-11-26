import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/monthly_budgets_repository.dart';
import '../domain/monthly_budget.dart';

final monthlyBudgetsRepositoryProvider = Provider<MonthlyBudgetsRepository>((
  ref,
) {
  return MonthlyBudgetsRepository(ref.watch(appDatabaseProvider));
});

final monthlyBudgetProvider = StreamProvider<MonthlyBudget?>((ref) {
  return ref.watch(monthlyBudgetsRepositoryProvider).watchMonthlyBudget();
});
