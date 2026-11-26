import 'auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> watchAuthUser();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();
}
