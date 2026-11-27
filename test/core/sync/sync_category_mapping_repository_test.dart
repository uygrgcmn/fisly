import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/sync/sync_category_mapping_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncCategoryMappingRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = SyncCategoryMappingRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores many-to-one mappings separately for each user', () async {
    await repository.saveMapping(
      userId: 'user-a',
      localCategoryId: 'local-category-a',
      remoteCategoryId: 'remote-category-a',
    );
    await repository.saveMapping(
      userId: 'user-b',
      localCategoryId: 'local-category-a',
      remoteCategoryId: 'remote-category-b',
    );

    expect(
      await repository.getRemoteCategoryId(
        userId: 'user-a',
        localCategoryId: 'local-category-a',
      ),
      'remote-category-a',
    );
    expect(
      await repository.getRemoteCategoryId(
        userId: 'user-b',
        localCategoryId: 'local-category-a',
      ),
      'remote-category-b',
    );

    await repository.saveMapping(
      userId: 'user-a',
      localCategoryId: 'local-category-b',
      remoteCategoryId: 'remote-category-a',
    );
    expect(
      await repository.getLocalCategoryIds(
        userId: 'user-a',
        remoteCategoryId: 'remote-category-a',
      ),
      containsAll(['local-category-a', 'local-category-b']),
    );
  });

  test('removes a mapping only for the selected user and category', () async {
    await repository.saveMapping(
      userId: 'user-a',
      localCategoryId: 'local-category',
      remoteCategoryId: 'remote-category-a',
    );
    await repository.saveMapping(
      userId: 'user-b',
      localCategoryId: 'local-category',
      remoteCategoryId: 'remote-category-b',
    );

    expect(
      await repository.removeMapping(
        userId: 'user-a',
        localCategoryId: 'local-category',
      ),
      isTrue,
    );
    expect(
      await repository.getRemoteCategoryId(
        userId: 'user-a',
        localCategoryId: 'local-category',
      ),
      isNull,
    );
    expect(
      await repository.getRemoteCategoryId(
        userId: 'user-b',
        localCategoryId: 'local-category',
      ),
      'remote-category-b',
    );
  });
}
