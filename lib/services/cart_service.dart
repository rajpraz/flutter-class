import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/models/product.dart';

class CartService {
  static CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance.collection('carts').doc(uid).collection('items');

  static Stream<List<CartItem>> streamCart(String uid) {
    return _items(uid).snapshots().map(
        (snap) => snap.docs.map(CartItem.fromDoc).toList());
  }

  static Future<void> addToCart(String uid, Product product, {int qty = 1}) async {
    final ref = _items(uid).doc(product.id);
    final existing = await ref.get();
    if (existing.exists) {
      final currentQty = (existing.data()?['qty'] as num?)?.toInt() ?? 1;
      await ref.update({'qty': currentQty + qty});
    } else {
      await ref.set(CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        qty: qty,
        image: product.image,
        sellerId: product.sellerId,
      ).toMap());
    }
  }

  static Future<void> updateQty(String uid, String productId, int qty) async {
    if (qty < 1) {
      await removeItem(uid, productId);
      return;
    }
    await _items(uid).doc(productId).update({'qty': qty});
  }

  static Future<void> removeItem(String uid, String productId) async {
    await _items(uid).doc(productId).delete();
  }

  static Future<void> clearCart(String uid) async {
    final snap = await _items(uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
