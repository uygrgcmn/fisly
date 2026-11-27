import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/sync/category_sync_data_source.dart';
import 'package:fisly/core/sync/category_sync_service.dart';
import 'package:fisly/core/sync/remote_category.dart';
import 'package:fisly/core/sync/sync_category_mapping_repository.dart';
import 'package:fisly/core/sync/sync_import_consent.dart';
import 'package:fisly/core/sync/sync_import_consent_repository.dart';
import 'package:fisly/core/sync/sync_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = 'user-a';
  late AppDatabase database;
  late _FakeCategorySyncDataSource dataSource;
  late SyncImportConsentRepository consentRepository;
  late SyncCategoryMappingRepository mappingRepository;
  late SyncQueueRepository queueRepository;
  late CategorySyncService service;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    dataSource = _FakeCategorySyncDataSource(userId);
    consentRepository = SyncImportConsentRepository(database);
    mappingRepository = SyncCategoryMappingRepository(database);
    queueRepository = SyncQueueRepository(database);
    service = CategorySyncService(
      database,
      dataSource,
      consentRepository,
      mappingRepository,
      queueRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('requires matching account and explicit import consent', () async {
    await database
        .into(database.categories)
        .insert(CategoriesCompanion.insert(name: 'Food'));

    await expectLater(
      service.syncCategories(userId: 'another-user'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.syncCategories(userId: userId),
      throwsA(isA<StateError>()),
    );

    expect(dataSource.createCalls, 0);
    expect(await queueRepository.getPendingOperations(), hasLength(1));
  });

  test(
    'merges case-insensitive names, uploads missing rows, and maps IDs',
    () async {
      final localDefault = await database
          .into(database.categories)
          .insertReturning(
            CategoriesCompanion.insert(
              name: 'Market',
              isDefault: const Value(true),
            ),
          );
      final localCustom = await database
          .into(database.categories)
          .insertReturning(CategoriesCompanion.insert(name: 'Pets'));
      dataSource.remoteCategories.add(
        _remote(id: 'remote-market', name: 'market', isDefault: true),
      );
      await consentRepository.saveDecision(
        userId,
        SyncImportConsentDecision.allowed,
      );

      final result = await service.syncCategories(userId: userId);

      expect(result.created, 1);
      expect(result.merged, 1);
      expect(result.updated, 0);
      expect(
        await mappingRepository.getRemoteCategoryId(
          userId: userId,
          localCategoryId: localDefault.id,
        ),
        'remote-market',
      );
      final customRemoteId = await mappingRepository.getRemoteCategoryId(
        userId: userId,
        localCategoryId: localCustom.id,
      );
      expect(customRemoteId, isNotNull);
      expect(dataSource.remoteCategories, hasLength(2));
      expect(
        await queueRepository.getPendingOperations(userId: userId),
        isEmpty,
      );
      expect(
        await queueRepository.getPendingOperations(userId: 'another-user'),
        hasLength(2),
      );

      final repeatedResult = await service.syncCategories(userId: userId);
      expect(repeatedResult.created, 0);
      expect(dataSource.remoteCategories, hasLength(2));
    },
  );

  test(
    'renames mapped custom categories and syncs deletion tombstones',
    () async {
      final local = await database
          .into(database.categories)
          .insertReturning(CategoriesCompanion.insert(name: 'Pets'));
      dataSource.remoteCategories.add(_remote(id: 'remote-pets', name: 'Pets'));
      await mappingRepository.saveMapping(
        userId: userId,
        localCategoryId: local.id,
        remoteCategoryId: 'remote-pets',
      );
      await consentRepository.saveDecision(
        userId,
        SyncImportConsentDecision.allowed,
      );
      await (database.update(database.categories)
            ..where((row) => row.id.equals(local.id)))
          .write(const CategoriesCompanion(name: Value('Pet care')));

      final updateResult = await service.syncCategories(userId: userId);
      expect(updateResult.updated, 1);
      expect(dataSource.remoteCategories.single.name, 'Pet care');

      await (database.delete(
        database.categories,
      )..where((row) => row.id.equals(local.id))).go();
      final deleteResult = await service.syncCategories(userId: userId);

      expect(deleteResult.deleted, 1);
      expect(dataSource.remoteCategories, isEmpty);
      expect(
        await mappingRepository.getRemoteCategoryId(
          userId: userId,
          localCategoryId: local.id,
        ),
        isNull,
      );
      expect(
        await queueRepository.getPendingOperations(userId: userId),
        isEmpty,
      );
    },
  );

  test('keeps delete tombstones pending when remote deletion fails', () async {
    final local = await database
        .into(database.categories)
        .insertReturning(CategoriesCompanion.insert(name: 'Pets'));
    dataSource.remoteCategories.add(_remote(id: 'remote-pets', name: 'Pets'));
    await mappingRepository.saveMapping(
      userId: userId,
      localCategoryId: local.id,
      remoteCategoryId: 'remote-pets',
    );
    await consentRepository.saveDecision(
      userId,
      SyncImportConsentDecision.allowed,
    );
    await (database.delete(
      database.categories,
    )..where((row) => row.id.equals(local.id))).go();
    dataSource.failDeletes = true;

    await expectLater(
      service.syncCategories(userId: userId),
      throwsA(isA<StateError>()),
    );

    final pendingOperations = await queueRepository.getPendingOperations(
      userId: userId,
    );
    expect(pendingOperations, hasLength(2));
    expect(pendingOperations.last.operation, 'delete');
    expect(
      await mappingRepository.getRemoteCategoryId(
        userId: userId,
        localCategoryId: local.id,
      ),
      'remote-pets',
    );
  });

  test(
    'does not delete a cloud category while another local mapping uses it',
    () async {
      final canonical = await database
          .into(database.categories)
          .insertReturning(CategoriesCompanion.insert(name: 'Market'));
      final alias = await database
          .into(database.categories)
          .insertReturning(CategoriesCompanion.insert(name: 'market'));
      dataSource.remoteCategories.add(
        _remote(id: 'remote-market', name: 'Market', isDefault: true),
      );
      await mappingRepository.saveMapping(
        userId: userId,
        localCategoryId: canonical.id,
        remoteCategoryId: 'remote-market',
      );
      await mappingRepository.saveMapping(
        userId: userId,
        localCategoryId: alias.id,
        remoteCategoryId: 'remote-market',
      );
      await consentRepository.saveDecision(
        userId,
        SyncImportConsentDecision.allowed,
      );
      await (database.delete(
        database.categories,
      )..where((row) => row.id.equals(alias.id))).go();

      final result = await service.syncCategories(userId: userId);

      expect(result.deleted, 0);
      expect(dataSource.remoteCategories, hasLength(1));
      expect(
        await mappingRepository.getRemoteCategoryId(
          userId: userId,
          localCategoryId: canonical.id,
        ),
        'remote-market',
      );
      expect(
        await mappingRepository.getRemoteCategoryId(
          userId: userId,
          localCategoryId: alias.id,
        ),
        isNull,
      );
      expect(
        await queueRepository.getPendingOperations(userId: userId),
        isEmpty,
      );
    },
  );
}

RemoteCategory _remote({
  required String id,
  required String name,
  bool isDefault = false,
}) {
  final now = DateTime.utc(2026, 11, 27);
  return RemoteCategory(
    id: id,
    name: name,
    isDefault: isDefault,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCategorySyncDataSource implements CategorySyncDataSource {
  _FakeCategorySyncDataSource(this.authenticatedUserId);

  @override
  final String? authenticatedUserId;

  final remoteCategories = <RemoteCategory>[];
  int createCalls = 0;
  int _nextId = 0;
  bool failDeletes = false;

  @override
  Future<List<RemoteCategory>> getCategories(String userId) async {
    return List.of(remoteCategories);
  }

  @override
  Future<RemoteCategory> createCategory({
    required String userId,
    required String name,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    createCalls++;
    final category = RemoteCategory(
      id: 'remote-${++_nextId}',
      name: name,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    remoteCategories.add(category);
    return category;
  }

  @override
  Future<RemoteCategory> updateCategory({
    required String userId,
    required String id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final index = remoteCategories.indexWhere((category) => category.id == id);
    final previous = remoteCategories[index];
    final updated = RemoteCategory(
      id: id,
      name: name,
      isDefault: previous.isDefault,
      createdAt: previous.createdAt,
      updatedAt: updatedAt,
    );
    remoteCategories[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCategory({
    required String userId,
    required String id,
  }) async {
    if (failDeletes) throw StateError('Remote delete failed.');
    remoteCategories.removeWhere((category) => category.id == id);
  }
}
