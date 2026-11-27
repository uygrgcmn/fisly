import 'package:drift/drift.dart';

import 'sync_operations_table.dart';

@DataClassName('SyncOperationAcknowledgementRow')
class SyncOperationAcknowledgements extends Table {
  TextColumn get userId => text()();

  IntColumn get operationId =>
      integer().references(SyncOperations, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {userId, operationId};
}
