import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/core/sync/sync_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SyncQueueRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = SyncQueueRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('tracks acknowledgements separately for each user', () async {
    for (final merchant in ['Cafe', 'Market']) {
      await database
          .into(database.expenses)
          .insert(
            ExpensesCompanion.insert(
              merchant: merchant,
              amountMinorUnits: 1000,
              occurredAt: DateTime(2026, 11, 25),
            ),
          );
    }

    final firstBatch = await repository.getPendingOperations(
      limit: 1,
      userId: 'user-a',
    );
    expect(firstBatch, hasLength(1));
    expect(firstBatch.single.entityType, 'expenses');
    expect(firstBatch.single.operation, 'upsert');

    await repository.markOperationsSynced(
      userId: 'user-a',
      operationIds: firstBatch.map((operation) => operation.id),
    );

    final remaining = await repository.getPendingOperations(userId: 'user-a');
    expect(remaining, hasLength(1));
    expect(remaining.single.id, greaterThan(firstBatch.single.id));
    expect(
      await repository.getPendingOperations(userId: 'user-b'),
      hasLength(2),
    );
    expect(await repository.getPendingOperations(), hasLength(2));
  });

  test(
    'does not acknowledge mutations created after a sync snapshot',
    () async {
      final expenseId = await database
          .into(database.expenses)
          .insertReturning(
            ExpensesCompanion.insert(
              merchant: 'Cafe',
              amountMinorUnits: 1000,
              occurredAt: DateTime(2026, 11, 25),
            ),
          )
          .then((row) => row.id);
      final snapshot = await repository.getPendingOperations(userId: 'user-a');

      await (database.update(database.expenses)
            ..where((row) => row.id.equals(expenseId)))
          .write(const ExpensesCompanion(merchant: Value('Updated Cafe')));
      await repository.markOperationsSynced(
        userId: 'user-a',
        operationIds: snapshot.map((operation) => operation.id),
      );

      final pending = await repository.getPendingOperations(userId: 'user-a');
      expect(pending, hasLength(1));
      expect(pending.single.operation, 'upsert');
    },
  );

  test('rejects a non-positive batch size', () {
    expect(
      () => repository.getPendingOperations(limit: 0),
      throwsArgumentError,
    );
  });
}
