import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/products/domain/entities/product.dart';
import 'package:untitled3/features/products/domain/entities/product_page.dart';
import 'package:untitled3/features/products/domain/entities/product_sort.dart';

class ProductRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> _products =
      FirebaseFirestore.instance.collection('products');

  /// Unbounded, reactive — only for surfaces that genuinely need the whole
  /// active catalog reactively (category/festival filtering, which need to
  /// scan every active product for a category/tag match and have no
  /// natural page size of their own). Everything else should use
  /// [fetchActiveProductsPage] instead of this.
  Stream<List<Product>> streamActiveProducts() {
    return _products
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  /// One page of active products, sorted server-side by [sort]. Each sort
  /// option is a distinct Firestore `orderBy` and therefore needs its own
  /// composite index alongside `isActive == true` — see
  /// firestore.indexes.json.
  Future<ProductPage> fetchActiveProductsPage({
    Object? startAfter,
    int limit = 20,
    ProductSort sort = ProductSort.newest,
  }) async {
    Query<Map<String, dynamic>> query = _products.where('isActive', isEqualTo: true);
    query = switch (sort) {
      ProductSort.newest => query.orderBy('createdAt', descending: true),
      ProductSort.priceLowToHigh => query.orderBy('price'),
      ProductSort.priceHighToLow => query.orderBy('price', descending: true),
      ProductSort.popularity => query.orderBy('ratingCount', descending: true),
    };
    query = query.limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter as DocumentSnapshot<Map<String, dynamic>>);
    }

    final snap = await query.get();
    final items = snap.docs.map(Product.fromDoc).toList();
    return ProductPage(
      items: items,
      cursor: snap.docs.isEmpty ? startAfter : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  Stream<List<Product>> streamSellerProducts(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0))));
  }

  /// Admin-only unfiltered view — see [ProductRepository.streamAllProductsForAdmin].
  Stream<List<Product>> streamAllProductsForAdmin({int limit = 200}) {
    return _products
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  Future<Product?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  Future<String> addProduct(Product product) async {
    final doc = await _products.add(product.toMap());
    return doc.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    await _products.doc(productId).update(updates);
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }
}
