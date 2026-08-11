import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final int qty;
  final String image;
  final String sellerId;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.qty,
    required this.image,
    required this.sellerId,
  });

  double get subtotal => price * qty;

  factory CartItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return CartItem(
      productId: doc.id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      image: map['image'] ?? '',
      sellerId: map['sellerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'qty': qty,
      'image': image,
      'sellerId': sellerId,
    };
  }
}
