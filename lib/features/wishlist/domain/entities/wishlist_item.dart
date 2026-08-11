import 'package:cloud_firestore/cloud_firestore.dart';

/// A saved wishlist entry — just the product reference, never a copy of the
/// product's name/price/image. Those go stale the moment the product
/// changes; the UI always resolves the live product via
/// `productProvider(productId)`.
class WishlistItem {
  final String productId;
  final DateTime? addedAt;

  const WishlistItem({required this.productId, this.addedAt});

  factory WishlistItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return WishlistItem(
      productId: doc.id,
      addedAt: (doc.data()?['addedAt'] as Timestamp?)?.toDate(),
    );
  }
}
