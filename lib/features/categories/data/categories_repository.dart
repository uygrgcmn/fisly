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

  Future<void> addCustomCategory(String name) async {
    final normalizedName = _normalizeName(name);

    await _database.transaction(() async {
      await _ensureNameIsAvailable(normalizedName);
      await _database
          .into(_database.categories)
          .insert(CategoriesCompanion.insert(name: normalizedName));
    });
  }

  Future<bool> renameCustomCategory(String id, String name) async {
    final normalizedName = _normalizeName(name);

    return _database.transaction(() async {
      final category = await (_database.select(
        _database.categories,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (category == null) return false;
      if (category.isDefault) {
        throw StateError('Default categories cannot be renamed.');
      }

      await _ensureNameIsAvailable(normalizedName, exceptId: id);
      final updatedRows =
          await (_database.update(
            _database.categories,
          )..where((row) => row.id.equals(id))).write(
            CategoriesCompanion(
              name: Value(normalizedName),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return updatedRows == 1;
    });
  }

  Future<bool> deleteCustomCategory(String id) async {
    return _database.transaction(() async {
      final category = await (_database.select(
        _database.categories,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (category == null) return false;
      if (category.isDefault) {
        throw StateError('Default categories cannot be deleted.');
      }

      final deletedRows = await (_database.delete(
        _database.categories,
      )..where((row) => row.id.equals(id))).go();
      return deletedRows == 1;
    });
  }

  Future<void> _ensureNameIsAvailable(String name, {String? exceptId}) async {
    final categories = await _database.select(_database.categories).get();
    final hasConflict = categories.any(
      (category) =>
          category.id != exceptId &&
          category.name.toLowerCase() == name.toLowerCase(),
    );
    if (hasConflict) {
      throw StateError('A category named "$name" already exists.');
    }
  }

  String _normalizeName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Category name cannot be empty.');
    }
    return normalizedName;
  }
}
