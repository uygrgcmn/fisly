import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart';

class CategoriesRepository {
  const CategoriesRepository(this._database);

  static const _defaultCategoryNames = [
    'Yemek',
    'Market',
    'Ulaşım',
    'Faturalar',
    'Alışveriş',
    'Sağlık',
    'Eğlence',
    'Diğer',
  ];

  final AppDatabase _database;

  Stream<List<Category>> watchCategories() {
    final query = _database.select(_database.categories)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => Category(
              id: row.id,
              name: row.name,
              isDefault: row.isDefault,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> ensureDefaultCategories() async {
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.categories,
      )..where((row) => row.isDefault.equals(true))).get();
      final existingNames = existing.map((row) => row.name).toSet();
      final missingNames = _defaultCategoryNames
          .where((name) => !existingNames.contains(name))
          .toList(growable: false);

      if (missingNames.isEmpty) return;

      await _database.batch((batch) {
        batch.insertAll(
          _database.categories,
          missingNames
              .map(
                (name) => CategoriesCompanion.insert(
                  name: name,
                  isDefault: const Value(true),
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }
}
