import 'remote_category.dart';

abstract interface class CategorySyncDataSource {
  String? get authenticatedUserId;

  Future<List<RemoteCategory>> getCategories(String userId);

  Future<RemoteCategory> createCategory({
    required String userId,
    required String name,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<RemoteCategory> updateCategory({
    required String userId,
    required String id,
    required String name,
    required DateTime updatedAt,
  });

  Future<void> deleteCategory({required String userId, required String id});
}
