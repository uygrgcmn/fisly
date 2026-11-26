import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/config/supabase_config.dart';
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
