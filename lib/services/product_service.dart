import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/product.dart';

class ProductService {
  static final _products = FirebaseFirestore.instance.collection('products');

  static Stream<List<Product>> streamActiveProducts() {
    return _products
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  static Stream<List<Product>> streamSellerProducts(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0))));
  }

  static Future<Product?> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  static Future<String> addProduct(Product product) async {
    final doc = await _products.add(product.toMap());
    return doc.id;
  }

  static Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    await _products.doc(productId).update(updates);
  }

  static Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }
}
