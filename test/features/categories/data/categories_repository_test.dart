import 'package:drift/native.dart';
import 'package:fisly/core/database/app_database.dart';
import 'package:fisly/features/categories/data/categories_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoriesRepository repository;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    repository = CategoriesRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'seeds default categories once and watches them alphabetically',
    () async {
      await repository.ensureDefaultCategories();
      await repository.ensureDefaultCategories();

      final categories = await repository.watchCategories().first;

      expect(categories, hasLength(8));
      expect(categories.every((category) => category.isDefault), isTrue);
      expect(categories.map((category) => category.name).toList(), [
        'Alışveriş',
        'Diğer',
        'Eğlence',
        'Faturalar',
        'Market',
        'Sağlık',
        'Ulaşım',
        'Yemek',
      ]);
    },
  );
}
