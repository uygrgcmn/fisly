import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_sync_data_source.dart';
import 'remote_category.dart';

class SupabaseCategorySyncDataSource implements CategorySyncDataSource {
  const SupabaseCategorySyncDataSource(this._client);

  final SupabaseClient _client;

  static const _columns = 'id,name,is_default,created_at,updated_at';

  @override
  String? get authenticatedUserId => _client.auth.currentUser?.id;

  @override
  Future<List<RemoteCategory>> getCategories(String userId) async {
    final rows = await _client
        .from('categories')
        .select(_columns)
        .eq('user_id', userId);

    return rows.map(_fromJson).toList(growable: false);
  }

  @override
  Future<RemoteCategory> createCategory({
    required String userId,
    required String name,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final row = await _client
        .from('categories')
        .insert({
          'user_id': userId,
          'name': name,
          'is_default': isDefault,
          'created_at': createdAt.toUtc().toIso8601String(),
          'updated_at': updatedAt.toUtc().toIso8601String(),
        })
        .select(_columns)
        .single();

    return _fromJson(row);
  }

  @override
  Future<RemoteCategory> updateCategory({
    required String userId,
    required String id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final row = await _client
        .from('categories')
        .update({
          'name': name,
          'updated_at': updatedAt.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select(_columns)
        .single();

    return _fromJson(row);
  }

  @override
  Future<void> deleteCategory({
    required String userId,
    required String id,
  }) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  RemoteCategory _fromJson(Map<String, dynamic> json) {
    return RemoteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
