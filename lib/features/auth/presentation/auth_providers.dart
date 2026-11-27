import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/config/supabase_config.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/sync/category_sync_service.dart';
import '../../../core/sync/supabase_category_sync_data_source.dart';
import '../../../core/sync/sync_category_mapping_repository.dart';
import '../../../core/sync/sync_import_consent.dart';
import '../../../core/sync/sync_import_consent_repository.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authUserProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  if (repository == null) return Stream.value(null);
  return repository.watchAuthUser();
});

final syncImportConsentRepositoryProvider =
    Provider<SyncImportConsentRepository>((ref) {
      return SyncImportConsentRepository(ref.watch(appDatabaseProvider));
    });

final syncImportConsentProvider =
    FutureProvider.family<SyncImportConsentDecision?, String>((ref, userId) {
      return ref.watch(syncImportConsentRepositoryProvider).getDecision(userId);
    });

final categorySyncServiceProvider = Provider<CategorySyncService?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;

  final database = ref.watch(appDatabaseProvider);
  return CategorySyncService(
    database,
    SupabaseCategorySyncDataSource(Supabase.instance.client),
    ref.watch(syncImportConsentRepositoryProvider),
    SyncCategoryMappingRepository(database),
    SyncQueueRepository(database),
  );
});
