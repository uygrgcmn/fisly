import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  TextColumn get name => text()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
