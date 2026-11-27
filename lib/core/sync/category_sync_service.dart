import '../database/app_database.dart';
import 'category_sync_data_source.dart';
import 'sync_category_mapping_repository.dart';
import 'sync_import_consent.dart';
import 'sync_import_consent_repository.dart';
import 'sync_queue_repository.dart';

class CategorySyncResult {
  const CategorySyncResult({
    required this.created,
    required this.merged,
    required this.updated,
    required this.deleted,
  });

  final int created;
  final int merged;
  final int updated;
  final int deleted;
}

class CategorySyncService {
  const CategorySyncService(
    this._database,
    this._dataSource,
    this._consentRepository,
    this._mappingRepository,
    this._queueRepository,
  );

  final AppDatabase _database;
  final CategorySyncDataSource _dataSource;
  final SyncImportConsentRepository _consentRepository;
  final SyncCategoryMappingRepository _mappingRepository;
  final SyncQueueRepository _queueRepository;

  Future<CategorySyncResult> syncCategories({required String userId}) async {
    if (_dataSource.authenticatedUserId != userId) {
      throw StateError('The active account does not match the sync account.');
    }

    final consent = await _consentRepository.getDecision(userId);
    if (consent != SyncImportConsentDecision.allowed) {
      throw StateError('Import consent is required before syncing categories.');
    }

    final (localCategories, pendingOperations) = await _database.transaction(
      () async {
        final categories = await _database.select(_database.categories).get();
        final operations = await _queueRepository.getPendingOperationsForEntity(
          entityType: 'categories',
          userId: userId,
        );
        return (categories, operations);
      },
    );
    final pendingOperationsByEntity = <String, List<SyncOperationRow>>{};
    final latestOperationByEntity = <String, SyncOperationRow>{};
    for (final operation in pendingOperations) {
      pendingOperationsByEntity
          .putIfAbsent(operation.entityId, () => [])
          .add(operation);
      latestOperationByEntity[operation.entityId] = operation;
    }

    final remoteCategories = await _dataSource.getCategories(userId);
    final remoteByName = {
      for (final category in remoteCategories)
        _normalizeName(category.name): category,
    };
    final remoteById = {
      for (final category in remoteCategories) category.id: category,
    };

    var created = 0;
    var merged = 0;
    var updated = 0;

    for (final local in localCategories) {
      final normalizedName = _normalizeName(local.name);
      var remote = remoteByName[normalizedName];

      if (remote != null) {
        if (remote.id != local.id) merged++;
      } else {
        final mappedId = await _mappingRepository.getRemoteCategoryId(
          userId: userId,
          localCategoryId: local.id,
        );
        final mappedRemote = mappedId == null ? null : remoteById[mappedId];

        if (mappedRemote != null && !mappedRemote.isDefault) {
          remote = await _dataSource.updateCategory(
            userId: userId,
            id: mappedRemote.id,
            name: local.name,
            updatedAt: local.updatedAt,
          );
          updated++;
        } else {
          remote = await _dataSource.createCategory(
            userId: userId,
            name: local.name,
            isDefault: local.isDefault,
            createdAt: local.createdAt,
            updatedAt: local.updatedAt,
          );
          created++;
        }

        remoteById[remote.id] = remote;
        remoteByName[_normalizeName(remote.name)] = remote;
      }

      await _mappingRepository.saveMapping(
        userId: userId,
        localCategoryId: local.id,
        remoteCategoryId: remote.id,
      );
      await _queueRepository.markOperationsSynced(
        userId: userId,
        operationIds:
            pendingOperationsByEntity[local.id]?.map(
              (operation) => operation.id,
            ) ??
            const <int>[],
      );
    }

    final localIds = localCategories.map((category) => category.id).toSet();
    var deleted = 0;

    for (final entry in latestOperationByEntity.entries) {
      final localId = entry.key;
      if (localIds.contains(localId) || entry.value.operation != 'delete') {
        continue;
      }

      final remoteId = await _mappingRepository.getRemoteCategoryId(
        userId: userId,
        localCategoryId: localId,
      );
      if (remoteId != null) {
        final mappedLocalIds = await _mappingRepository.getLocalCategoryIds(
          userId: userId,
          remoteCategoryId: remoteId,
        );
        final hasOtherLiveMapping = mappedLocalIds.any(
          (mappedLocalId) =>
              mappedLocalId != localId && localIds.contains(mappedLocalId),
        );
        if (!hasOtherLiveMapping) {
          await _dataSource.deleteCategory(userId: userId, id: remoteId);
          deleted++;
        }
        await _mappingRepository.removeMapping(
          userId: userId,
          localCategoryId: localId,
        );
      }
      await _queueRepository.markOperationsSynced(
        userId: userId,
        operationIds: pendingOperationsByEntity[localId]!.map(
          (operation) => operation.id,
        ),
      );
    }

    return CategorySyncResult(
      created: created,
      merged: merged,
      updated: updated,
      deleted: deleted,
    );
  }

  String _normalizeName(String name) => name.trim().toLowerCase();
}
