import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/sync/sync_import_consent.dart';
import 'package:fisly/core/sync/sync_import_consent_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncImportConsentRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = SyncImportConsentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores and updates consent separately for each user', () async {
    expect(await repository.getDecision('user-a'), isNull);

    await repository.saveDecision('user-a', SyncImportConsentDecision.allowed);
    await repository.saveDecision('user-b', SyncImportConsentDecision.declined);

    expect(
      await repository.getDecision('user-a'),
      SyncImportConsentDecision.allowed,
    );
    expect(
      await repository.getDecision('user-b'),
      SyncImportConsentDecision.declined,
    );

    await repository.saveDecision('user-a', SyncImportConsentDecision.declined);
    expect(
      await repository.getDecision('user-a'),
      SyncImportConsentDecision.declined,
    );
  });
}
