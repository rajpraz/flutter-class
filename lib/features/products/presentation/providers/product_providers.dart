import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/products/data/datasources/product_remote_data_source.dart';
import 'package:untitled3/features/products/data/repositories/product_repository_impl.dart';
import 'package:untitled3/features/products/domain/entities/product.dart';
import 'package:untitled3/features/products/domain/entities/product_page.dart';
import 'package:untitled3/features/products/domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ProductRemoteDataSource());
});

final activeProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).streamActiveProducts();
});

final sellerProductsProvider = StreamProvider.family<List<Product>, String>((ref, sellerId) {
  return ref.watch(productRepositoryProvider).streamSellerProducts(sellerId);
});

/// Single-product lookup by ID, used by product detail/edit routes so
/// navigation only has to carry a productId, not a whole `Product`.
final productProvider = FutureProvider.autoDispose.family<Product?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).getProduct(productId);
});

/// A single bounded first page — Home's "featured" teaser section, which
/// only ever shows a handful of products and links out to `/products`
/// (backed by `productListControllerProvider`) for the real paginated
/// browse. Avoids Home paying for the full unbounded `activeProductsProvider`
/// stream just to show 8-12 cards.
final homeFeaturedProductsProvider = FutureProvider.autoDispose<ProductPage>((ref) {
  return ref.watch(productRepositoryProvider).fetchActiveProductsPage(limit: 10);
});

/// Admin-only: every product (active/inactive), for the admin product
/// moderation list.
final adminAllProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).streamAllProductsForAdmin();
});
