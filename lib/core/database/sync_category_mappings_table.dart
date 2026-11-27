import 'package:drift/drift.dart';

@DataClassName('SyncCategoryMappingRow')
class SyncCategoryMappings extends Table {
  TextColumn get userId => text()();

  // Retain the mapping after local deletion so a pending tombstone can resolve.
  TextColumn get localCategoryId => text()();

  TextColumn get remoteCategoryId => text()();

  @override
  Set<Column<Object>> get primaryKey => {userId, localCategoryId};
}
