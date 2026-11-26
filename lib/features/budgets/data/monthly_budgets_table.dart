import 'package:drift/drift.dart';

@DataClassName('MonthlyBudgetRow')
class MonthlyBudgets extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  IntColumn get limitMinorUnits => integer()();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
