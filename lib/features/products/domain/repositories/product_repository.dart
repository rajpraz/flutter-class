import 'package:untitled3/features/products/domain/entities/product.dart';
import 'package:untitled3/features/products/domain/entities/product_page.dart';
import 'package:untitled3/features/products/domain/entities/product_sort.dart';

abstract class ProductRepository {
  Stream<List<Product>> streamActiveProducts();

  Future<ProductPage> fetchActiveProductsPage({
    Object? startAfter,
    int limit = 20,
    ProductSort sort = ProductSort.newest,
  });

  Stream<List<Product>> streamSellerProducts(String sellerId);

  /// Admin-only: every product regardless of `isActive`/seller, most
  /// recent first, bounded (not the whole collection) — authorized by
  /// firestore.rules' `isAdmin()` branch on the `products` read rule.
  Stream<List<Product>> streamAllProductsForAdmin({int limit});

  Future<Product?> getProduct(String productId);

  Future<String> addProduct(Product product);

  Future<void> updateProduct(String productId, Map<String, dynamic> updates);

  Future<void> deleteProduct(String productId);
}
