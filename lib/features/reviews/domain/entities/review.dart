import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String orderId;
  final String buyerId;
  final int rating;
  final String text;
  final List<String> images;
  final bool verifiedPurchase;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.buyerId,
    required this.rating,
    required this.text,
    this.images = const [],
    this.verifiedPurchase = false,
    this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Review(
      id: doc.id,
      productId: map['productId'] ?? '',
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: map['text'] ?? '',
      images: List<String>.from(map['images'] ?? const []),
      verifiedPurchase: map['verifiedPurchase'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
