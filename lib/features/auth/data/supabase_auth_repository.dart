import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> watchAuthUser() {
    return _watchAuthState();
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthUser?> _watchAuthState() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map(
      (state) => _mapUser(state.session?.user),
    );
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }
}
