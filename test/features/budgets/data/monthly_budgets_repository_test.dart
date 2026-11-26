import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/features/budgets/data/monthly_budgets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MonthlyBudgetsRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = MonthlyBudgetsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('watches an unset limit and saves updated limits', () async {
    expect(await repository.watchMonthlyBudget().first, isNull);

    await repository.setMonthlyLimit(1500000);
    final budget = await repository.watchMonthlyBudget().first;
    expect(budget?.limitMinorUnits, 1500000);

    await repository.setMonthlyLimit(1750000);
    final updatedBudget = await repository.watchMonthlyBudget().first;
    expect(updatedBudget?.limitMinorUnits, 1750000);

    final rows = await database.select(database.monthlyBudgets).get();
    expect(rows, hasLength(1));
  });

  test('rejects zero and negative monthly limits', () {
    expect(() => repository.setMonthlyLimit(0), throwsArgumentError);
    expect(() => repository.setMonthlyLimit(-1), throwsArgumentError);
  });
}
