import 'package:drift/drift.dart';

@DataClassName('SyncImportConsentRow')
class SyncImportConsents extends Table {
  TextColumn get userId => text()();

  TextColumn get decision => text()();

  IntColumn get decidedAtEpochMillis => integer()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}
