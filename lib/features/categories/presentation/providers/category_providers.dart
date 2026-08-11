import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:untitled3/features/categories/data/repositories/category_repository_impl.dart';
import 'package:untitled3/features/categories/domain/entities/category.dart';
import 'package:untitled3/features/categories/domain/repositories/category_repository.dart';
import 'package:untitled3/features/products/presentation/providers/product_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(CategoryRemoteDataSource());
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).streamActiveCategories();
});

/// Admin-only: every category (active and inactive), so deactivated ones
/// can still be found and reactivated.
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).streamAllCategories();
});

/// Product count per category name, derived from whatever product list is
/// already being fetched by `activeProductsProvider` — avoids a second
/// per-category Firestore query (or a denormalized counter field that would
/// need backend maintenance) just to show a count badge.
final productCountByCategoryProvider = Provider<Map<String, int>>((ref) {
  final productsAsync = ref.watch(activeProductsProvider);
  final products = productsAsync.value ?? const [];
  final counts = <String, int>{};
  for (final product in products) {
    counts[product.category] = (counts[product.category] ?? 0) + 1;
  }
  return counts;
});

/// Admin category CRUD actions. Direct Firestore writes are correct here
/// (no Cloud Function) — firestore.rules already gates `categories` writes
/// on `isAdmin()`.
class CategoryController extends AsyncNotifier<void> {
  late final CategoryRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(categoryRepositoryProvider);
  }

  Future<void> create(Category category) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.createCategory(category));
  }

  Future<void> editCategory(String id, Map<String, dynamic> updates) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateCategory(id, updates));
  }

  Future<void> setActive(String id, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.setActive(id, isActive));
  }
}

final categoryControllerProvider = AsyncNotifierProvider<CategoryController, void>(CategoryController.new);
