import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SyncQueueRepository {
  const SyncQueueRepository(this._database);

  final AppDatabase _database;

  Future<List<SyncOperationRow>> getPendingOperations({
    int limit = 100,
    String? userId,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Limit must be positive.');
    }

    final query = _database.select(_database.syncOperations)
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    final operations = await query.get();
    if (userId == null) return operations.take(limit).toList(growable: false);

    final acknowledgedQuery = _database.select(
      _database.syncOperationAcknowledgements,
    )..where((row) => row.userId.equals(userId));
    final acknowledgements = await acknowledgedQuery.get();
    final acknowledgedIds = acknowledgements
        .map((row) => row.operationId)
        .toSet();

    return operations
        .where((operation) => !acknowledgedIds.contains(operation.id))
        .take(limit)
        .toList(growable: false);
  }

  Future<List<SyncOperationRow>> getPendingOperationsForEntity({
    required String entityType,
    required String userId,
  }) async {
    final query = _database.select(_database.syncOperations)
      ..where((row) => row.entityType.equals(entityType))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
    final operations = await query.get();
    final acknowledgedQuery = _database.select(
      _database.syncOperationAcknowledgements,
    )..where((row) => row.userId.equals(userId));
    final acknowledgements = await acknowledgedQuery.get();
    final acknowledgedIds = acknowledgements
        .map((row) => row.operationId)
        .toSet();
    return operations
        .where((operation) => !acknowledgedIds.contains(operation.id))
        .toList(growable: false);
  }

  Future<void> markOperationsSynced({
    required String userId,
    required Iterable<int> operationIds,
  }) async {
    await _database.transaction(() async {
      for (final operationId in operationIds) {
        await _database
            .into(_database.syncOperationAcknowledgements)
            .insertOnConflictUpdate(
              SyncOperationAcknowledgementsCompanion.insert(
                userId: userId,
                operationId: operationId,
              ),
            );
      }
    });
  }
}
