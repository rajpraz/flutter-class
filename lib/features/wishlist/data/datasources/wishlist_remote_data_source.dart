import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/wishlist/domain/entities/wishlist_item.dart';

/// `users/{uid}/wishlist/{productId}` — owner-only read/write per
/// firestore.rules. Doc id IS the product id, so toggling is just a
/// set-or-delete on a known path (no query needed to find "the" saved
/// entry for a product).
class WishlistRemoteDataSource {
  static CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('wishlist');

  Stream<List<WishlistItem>> streamWishlist(String uid) {
    return _items(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WishlistItem.fromDoc).toList());
  }

  Future<bool> toggle(String uid, String productId) async {
    final ref = _items(uid).doc(productId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
      return false;
    }
    await ref.set({'addedAt': FieldValue.serverTimestamp()});
    return true;
  }

  Future<void> remove(String uid, String productId) => _items(uid).doc(productId).delete();
}
