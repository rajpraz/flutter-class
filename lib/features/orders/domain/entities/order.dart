import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int qty;
  final String sellerId;
  final String sellerName;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.sellerId,
    this.sellerName = '',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      sellerId: map['sellerId'] ?? '',
      // Empty for orders placed before this field existed — display
      // fallback text, don't crash.
      sellerName: map['sellerName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'qty': qty,
      'sellerId': sellerId,
      'sellerName': sellerName,
    };
  }
}

/// Fulfillment status of the order itself. Kept strictly separate from
/// [paymentStatuses] — an order can be `confirmed` while still
/// `paymentStatus: pending` (e.g. Cash on Delivery), and payment can be
/// `paid` while the order is still `processing`.
const List<String> orderStatuses = [
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'returned',
  'refunded',
];

/// Payment lifecycle, independent of [orderStatuses]. Mirrors
/// functions/src/types.ts `PaymentStatus` — keep both in sync.
const List<String> paymentStatuses = [
  'pending',
  'processing',
  'paid',
  'failed',
  'refunded',
  'partially_refunded',
];

class StatusHistoryEntry {
  final String status;
  final DateTime? timestamp;
  final String changedBy;
  final String note;

  const StatusHistoryEntry({
    required this.status,
    required this.changedBy,
    this.timestamp,
    this.note = '',
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: map['status'] ?? '',
      changedBy: map['changedBy'] ?? '',
      note: map['note'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'changedBy': changedBy,
      'note': note,
      'timestamp': timestamp == null ? Timestamp.now() : Timestamp.fromDate(timestamp!),
    };
  }
}

class PoojaOrder {
  final String id;
  final String buyerId;
  final List<String> sellerIds;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? paymentRef;
  final String shippingAddress;
  final List<StatusHistoryEntry> statusHistory;
  final DateTime? createdAt;

  const PoojaOrder({
    required this.id,
    required this.buyerId,
    required this.sellerIds,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discount = 0,
    this.tax = 0,
    this.paymentStatus = 'pending',
    this.paymentMethod = 'cod',
    this.paymentRef,
    this.statusHistory = const [],
    this.createdAt,
  });

  factory PoojaOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return PoojaOrder(
      id: doc.id,
      buyerId: map['buyerId'] ?? '',
      sellerIds: List<String>.from(map['sellerIds'] ?? const []),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentRef: map['paymentRef'],
      shippingAddress: map['shippingAddress'] ?? '',
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerIds': sellerIds,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentRef': paymentRef,
      'shippingAddress': shippingAddress,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}

/// Result of the trusted `createOrder` Cloud Function call — carries the
/// server-computed authoritative total back to the client (e.g. so
/// checkout can pass the exact amount to the Khalti SDK).
class CreateOrderResult {
  final String orderId;
  final double totalAmount;
  final bool deduplicated;

  const CreateOrderResult({
    required this.orderId,
    required this.totalAmount,
    required this.deduplicated,
  });
}
