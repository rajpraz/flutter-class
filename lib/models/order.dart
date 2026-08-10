import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int qty;
  final String sellerId;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.sellerId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      sellerId: map['sellerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'qty': qty,
      'sellerId': sellerId,
    };
  }
}

const List<String> orderStatuses = [
  'pending',
  'confirmed',
  'shipped',
  'delivered',
  'cancelled',
];

class PoojaOrder {
  final String id;
  final String buyerId;
  final List<String> sellerIds;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final DateTime? createdAt;

  const PoojaOrder({
    required this.id,
    required this.buyerId,
    required this.sellerIds,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
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
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      shippingAddress: map['shippingAddress'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerIds': sellerIds,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}
