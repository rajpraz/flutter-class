import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/products/domain/entities/product_filter.dart';

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void update(ProductFilter Function(ProductFilter current) updater) {
    state = updater(state);
  }

  void reset() => state = const ProductFilter();
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(ProductFilterNotifier.new);
