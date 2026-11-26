import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../categories/data/categories_table.dart';
import '../../recurring_expenses/data/recurring_expenses_table.dart';

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  TextColumn get merchant => text()();

  IntColumn get amountMinorUnits => integer()();

  TextColumn get currencyCode => text().withDefault(const Constant('TRY'))();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get note => text().nullable()();

  TextColumn get receiptImagePath => text().nullable()();

  TextColumn get recurringExpenseId => text().nullable().references(
    RecurringExpenses,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
