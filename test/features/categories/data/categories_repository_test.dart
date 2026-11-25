import 'package:drift/drift.dart' hide isNull;
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

  test(
    'supports custom category CRUD and unassigns its expenses on delete',
    () async {
      await repository.ensureDefaultCategories();
      await repository.addCustomCategory('Pets');

      final categories = await repository.watchCategories().first;
      final customCategory = categories.singleWhere(
        (category) => !category.isDefault,
      );
      await database
          .into(database.expenses)
          .insert(
            ExpensesCompanion.insert(
              merchant: 'Pet shop',
              amountMinorUnits: 1200,
              occurredAt: DateTime(2026, 11, 25),
              categoryId: Value(customCategory.id),
            ),
          );

      expect(
        await repository.renameCustomCategory(customCategory.id, 'Pet care'),
        isTrue,
      );
      final renamed = await repository.watchCategories().first;
      expect(
        renamed.singleWhere((category) => !category.isDefault).name,
        'Pet care',
      );

      expect(await repository.deleteCustomCategory(customCategory.id), isTrue);
      final expenses = await database.select(database.expenses).get();
      expect(expenses, hasLength(1));
      expect(expenses.single.categoryId, isNull);
    },
  );

  test(
    'rejects empty or duplicate names and protects default categories',
    () async {
      await repository.ensureDefaultCategories();

      await expectLater(
        repository.addCustomCategory('  '),
        throwsArgumentError,
      );
      await expectLater(
        repository.addCustomCategory('market'),
        throwsA(isA<StateError>()),
      );

      final defaultCategory = (await repository.watchCategories().first)
          .firstWhere((category) => category.isDefault);
      await expectLater(
        repository.renameCustomCategory(defaultCategory.id, 'Food'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        repository.deleteCustomCategory(defaultCategory.id),
        throwsA(isA<StateError>()),
      );
    },
  );
}
