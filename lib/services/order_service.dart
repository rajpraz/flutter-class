import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/models/order.dart';
import 'package:untitled3/services/pricing_service.dart';

/// Thrown when a cart item fails validation during order creation (e.g. the
/// product went out of stock or was deactivated between adding to cart and
/// checkout), or when an order can't be cancelled. The message is safe to
/// show directly to the user.
class OrderValidationException implements Exception {
  final String message;
  OrderValidationException(this.message);
  @override
  String toString() => message;
}

class OrderService {
  static final _orders = FirebaseFirestore.instance.collection('orders');
  static final _products = FirebaseFirestore.instance.collection('products');

  /// Creates an order inside a single Firestore transaction. Every product
  /// referenced by [items] is re-read from Firestore (never trusting the
  /// client-submitted [CartItem] price/name or the stale stock count it was
  /// added to cart with), validated for availability and stock, priced
  /// from those freshly-read documents, and stock is decremented — all
  /// atomically with the order write. The stock write also stamps a
  /// `lastOrderId` pointer back to this order, which the Firestore rules
  /// use to verify the decrement matches a real line item on a real order
  /// owned by the caller (see firestore.rules `isReservedByOrder`), rather
  /// than trusting any signed-in user's stock write. Throws
  /// [OrderValidationException] with a user-facing message if any item
  /// fails validation.
  static Future<String> createOrder({
    required String buyerId,
    required List<CartItem> items,
    required String shippingAddress,
  }) async {
    if (items.isEmpty) {
      throw OrderValidationException('Your cart is empty.');
    }

    final orderRef = _orders.doc();
    final productIds = items.map((e) => e.productId).toSet();

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      // Firestore transactions require all reads before any writes.
      final productDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final id in productIds) {
        productDocs[id] = await transaction.get(_products.doc(id));
      }

      final verifiedItems = <OrderItem>[];
      for (final cartItem in items) {
        final doc = productDocs[cartItem.productId]!;
        if (!doc.exists) {
          throw OrderValidationException('${cartItem.name} is no longer available.');
        }
        final data = doc.data()!;
        final isActive = data['isActive'] ?? true;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final name = (data['name'] as String?) ?? cartItem.name;
        final sellerId = data['sellerId'] ?? cartItem.sellerId;

        if (!isActive) {
          throw OrderValidationException('${cartItem.name} is no longer available.');
        }
        if (stock < cartItem.qty) {
          throw OrderValidationException(stock == 0
              ? '${cartItem.name} is out of stock.'
              : 'Only $stock left of ${cartItem.name}.');
        }

        verifiedItems.add(OrderItem(
          productId: cartItem.productId,
          name: name,
          price: price,
          qty: cartItem.qty,
          sellerId: sellerId,
        ));
      }

      final subtotal =
          verifiedItems.fold<double>(0, (total, item) => total + (item.price * item.qty));
      final totalAmount = subtotal + PricingService.deliveryFee;
      final sellerIds = verifiedItems.map((e) => e.sellerId).toSet().toList();

      final order = PoojaOrder(
        id: orderRef.id,
        buyerId: buyerId,
        sellerIds: sellerIds,
        items: verifiedItems,
        totalAmount: totalAmount,
        status: 'pending',
        shippingAddress: shippingAddress,
        createdAt: DateTime.now(),
      );
      transaction.set(orderRef, order.toMap());

      for (final id in productIds) {
        final qtyOrdered =
            items.where((e) => e.productId == id).fold<int>(0, (total, e) => total + e.qty);
        final currentStock = (productDocs[id]!.data()!['stock'] as num?)?.toInt() ?? 0;
        transaction.update(_products.doc(id), {
          'stock': currentStock - qtyOrdered,
          'lastOrderId': orderRef.id,
        });
      }

      return orderRef.id;
    });
  }

  /// Cancels an order the caller placed themselves and restores the stock
  /// it had reserved, atomically. Only the buyer who placed the order may
  /// cancel it, and only while it's still 'pending' — matching the
  /// Firestore rules, which independently verify both the order-status
  /// change and every product's stock-restore against the caller's own
  /// buyer id (see `isRestoredByCancel`). This is what keeps cancellation
  /// correct for orders spanning multiple sellers: the buyer owns the
  /// whole order, so they (not any individual seller) are the one
  /// authorized to touch every product's stock in it.
  ///
  /// Throws [OrderValidationException] if the order can't be cancelled.
  /// Safe to call more than once — an already-cancelled order is a no-op.
  static Future<void> cancelOrder(String orderId, {required String requestingUid}) async {
    final orderRef = _orders.doc(orderId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw OrderValidationException('Order not found.');
      }
      final order = PoojaOrder.fromDoc(orderSnap);
      if (order.status == 'cancelled') return;

      if (order.buyerId != requestingUid) {
        throw OrderValidationException('Only the buyer can cancel this order.');
      }
      if (order.status != 'pending') {
        throw OrderValidationException('This order can no longer be cancelled.');
      }

      final productRefs = {
        for (final item in order.items) item.productId: _products.doc(item.productId),
      };
      final productDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in productRefs.entries) {
        productDocs[entry.key] = await transaction.get(entry.value);
      }

      transaction.update(orderRef, {'status': 'cancelled'});

      for (final item in order.items) {
        final doc = productDocs[item.productId]!;
        if (!doc.exists) continue;
        final currentStock = (doc.data()?['stock'] as num?)?.toInt() ?? 0;
        transaction.update(productRefs[item.productId]!, {
          'stock': currentStock + item.qty,
          'lastOrderId': orderId,
        });
      }
    });
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

  /// Updates order status. A seller involved in the order may advance it
  /// through the normal fulfillment pipeline (confirmed/shipped/
  /// delivered). Cancellation is buyer-only — see [cancelOrder] — so
  /// 'cancelled' is routed there and requires [requestingUid] to be the
  /// order's buyer.
  static Future<void> updateStatus(String orderId, String status,
      {required String requestingUid}) async {
    if (status == 'cancelled') {
      await cancelOrder(orderId, requestingUid: requestingUid);
      return;
    }
    await _orders.doc(orderId).update({'status': status});
  }
}
