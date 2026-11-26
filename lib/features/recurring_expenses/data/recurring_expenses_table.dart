import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../categories/data/categories_table.dart';

@DataClassName('RecurringExpenseRow')
class RecurringExpenses extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  TextColumn get merchant => text()();

  IntColumn get amountMinorUnits => integer()();

  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get note => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get lastPaidAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
