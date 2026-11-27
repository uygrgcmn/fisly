import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SyncCategoryMappingRepository {
  const SyncCategoryMappingRepository(this._database);

  final AppDatabase _database;

  Future<String?> getRemoteCategoryId({
    required String userId,
    required String localCategoryId,
  }) async {
    final mapping =
        await (_database.select(_database.syncCategoryMappings)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.localCategoryId.equals(localCategoryId),
            ))
            .getSingleOrNull();

    return mapping?.remoteCategoryId;
  }

  Future<List<String>> getLocalCategoryIds({
    required String userId,
    required String remoteCategoryId,
  }) async {
    final mappings =
        await (_database.select(_database.syncCategoryMappings)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.remoteCategoryId.equals(remoteCategoryId),
            ))
            .get();

    return mappings
        .map((mapping) => mapping.localCategoryId)
        .toList(growable: false);
  }

  Future<void> saveMapping({
    required String userId,
    required String localCategoryId,
    required String remoteCategoryId,
  }) async {
    await _database
        .into(_database.syncCategoryMappings)
        .insertOnConflictUpdate(
          SyncCategoryMappingsCompanion.insert(
            userId: userId,
            localCategoryId: localCategoryId,
            remoteCategoryId: remoteCategoryId,
          ),
        );
  }

  Future<bool> removeMapping({
    required String userId,
    required String localCategoryId,
  }) async {
    final deletedRows =
        await (_database.delete(_database.syncCategoryMappings)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.localCategoryId.equals(localCategoryId),
            ))
            .go();

    return deletedRows == 1;
  }
}
