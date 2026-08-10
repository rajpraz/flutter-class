import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/models/order.dart';

class OrderService {
  static final _orders = FirebaseFirestore.instance.collection('orders');

  static Future<String> createOrder({
    required String buyerId,
    required List<CartItem> items,
    required String shippingAddress,
  }) async {
    final sellerIds = items.map((e) => e.sellerId).toSet().toList();
    final totalAmount = items.fold<double>(0, (sum, item) => sum + item.subtotal);

    final order = PoojaOrder(
      id: '',
      buyerId: buyerId,
      sellerIds: sellerIds,
      items: items
          .map((e) => OrderItem(
                productId: e.productId,
                name: e.name,
                price: e.price,
                qty: e.qty,
                sellerId: e.sellerId,
              ))
          .toList(),
      totalAmount: totalAmount,
      status: 'pending',
      shippingAddress: shippingAddress,
      createdAt: DateTime.now(),
    );

    final doc = await _orders.add(order.toMap());
    return doc.id;
  }

  static Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PoojaOrder.fromDoc).toList());
  }

  static Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PoojaOrder.fromDoc).toList());
  }

  static Stream<PoojaOrder?> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map(
        (doc) => doc.exists ? PoojaOrder.fromDoc(doc) : null);
  }

  static Future<void> updateStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({'status': status});
  }
}
