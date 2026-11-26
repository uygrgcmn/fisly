import 'dart:async';

import 'package:fisly/features/auth/domain/auth_repository.dart';
import 'package:fisly/features/auth/domain/auth_user.dart';
import 'package:fisly/features/auth/presentation/account_screen.dart';
import 'package:fisly/features/auth/presentation/auth_providers.dart';
import 'package:flutter/foundation.dart' show Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Widget;
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  testWidgets('keeps the account optional when Supabase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(null)],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hesap açmadan'), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsNothing);
  });

  testWidgets('signs in and signs out through the auth repository', (
    tester,
  ) async {
    await tester.pumpWidget(_accountApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byKey(const Key('auth-sign-out-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-sign-out-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });

  testWidgets('explains that sign-up may require email confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(_accountApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-mode-toggle-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth-email-field')),
      'new-user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('E-posta doğrulaması istenirse'),
      findsOneWidget,
    );
  });
}

Widget _accountApp(_FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: AccountScreen()),
  );
}

class _FakeAuthRepository implements AuthRepository {
  final _authChanges = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> watchAuthUser() async* {
    yield _currentUser;
    yield* _authChanges.stream;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(id: 'user-id', email: email);
    _authChanges.add(_currentUser);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authChanges.add(null);
  }

  Future<void> dispose() => _authChanges.close();
}
