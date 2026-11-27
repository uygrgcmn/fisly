import '../database/app_database.dart';
import 'sync_import_consent.dart';

class SyncImportConsentRepository {
  const SyncImportConsentRepository(this._database);

  final AppDatabase _database;

  Future<SyncImportConsentDecision?> getDecision(String userId) async {
    final row = await (_database.select(
      _database.syncImportConsents,
    )..where((consent) => consent.userId.equals(userId))).getSingleOrNull();

    return row == null
        ? null
        : SyncImportConsentDecision.values.byName(row.decision);
  }

  Future<void> saveDecision(
    String userId,
    SyncImportConsentDecision decision,
  ) async {
    await _database
        .into(_database.syncImportConsents)
        .insertOnConflictUpdate(
          SyncImportConsentsCompanion.insert(
            userId: userId,
            decision: decision.name,
            decidedAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }
}
