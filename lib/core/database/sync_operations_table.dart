import 'package:drift/drift.dart';

@DataClassName('SyncOperationRow')
class SyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get operation => text()();

  IntColumn get changedAtEpochMillis => integer()();
}
