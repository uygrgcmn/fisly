import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/categories_repository.dart';
import '../domain/category.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(appDatabaseProvider));
});

final categoriesProvider = StreamProvider<List<Category>>((ref) async* {
  final repository = ref.watch(categoriesRepositoryProvider);
  await repository.ensureDefaultCategories();
  yield* repository.watchCategories();
});
