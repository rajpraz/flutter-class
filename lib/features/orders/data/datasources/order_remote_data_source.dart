import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/core/network/functions_client.dart';
import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/orders/domain/entities/order.dart';

/// Order data access has two legitimate shapes, both live here:
///  - direct Firestore reads (`streamBuyerOrders`/`streamSellerOrders`/
///    `streamOrder`), governed entirely by firestore.rules
///    (buyer/seller/admin ownership) and safe to read directly.
///  - trusted Cloud Function calls (`createOrder`/`updateOrderStatus`),
///    which re-validate price/stock/seller and own the order state
///    machine server-side — never a client-run Firestore transaction.
class OrderRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> _orders =
      FirebaseFirestore.instance.collection('orders');

  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PoojaOrder.fromDoc).toList());
  }

  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) {
    return _orders
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PoojaOrder.fromDoc).toList());
  }

  Stream<PoojaOrder?> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map(
        (doc) => doc.exists ? PoojaOrder.fromDoc(doc) : null);
  }

  Stream<List<PoojaOrder>> streamAllOrders({int limit = 200}) {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PoojaOrder.fromDoc).toList());
  }

  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final data = await FunctionsClient.call('createOrder', {
      'items': items.map((e) => {'productId': e.productId, 'qty': e.qty}).toList(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'idempotencyKey': idempotencyKey,
    });
    return CreateOrderResult(
      orderId: data['orderId'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deduplicated: data['deduplicated'] as bool? ?? false,
    );
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    await FunctionsClient.call('updateOrderStatus', {
      'orderId': orderId,
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }
}
