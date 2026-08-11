import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final int stock;
  final String sellerId;
  final String sellerName;
  final DateTime? createdAt;
  final bool isActive;
  final String festivalTag;
  final double ratingAverage;
  final int ratingCount;
  final int lowStockThreshold;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.stock,
    required this.sellerId,
    this.sellerName = '',
    required this.isActive,
    this.createdAt,
    this.festivalTag = '',
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.lowStockThreshold = 5,
  });

  /// Matches functions/src/notifications/lowStock.ts's own threshold
  /// check, so the seller-facing badge agrees with when the backend
  /// actually sends a low-stock notification.
  bool get isLowStock => stock > 0 && stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  String get image => images.isNotEmpty ? images.first : '';

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Pooja Kits',
      images: List<String>.from(map['images'] ?? const []),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sellerId: map['sellerId'] ?? '',
      // Denormalized at write time (AddProductPage) from the seller's own
      // profile — the alternative (reading users/{sellerId} from a
      // buyer's session to show "Sold by") is blocked by firestore.rules,
      // which only lets a user read their own profile doc (or an admin
      // read any) precisely to keep other users' PII private.
      sellerName: map['sellerName'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      festivalTag: map['festivalTag'] ?? '',
      // Written server-side by functions/src/reviews/createReview.ts as
      // reviews come in; absent (defaults to 0) on products with no
      // reviews yet.
      ratingAverage: (map['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'stock': stock,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'isActive': isActive,
      'festivalTag': festivalTag,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  /// Widget-friendly map shape used by the existing ProductCard/DetailPage widgets.
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'image': image,
      'images': images,
      'name': name,
      'price': price,
      'oldPrice': null,
      'description': description,
      'category': category,
      'stock': stock,
      'sellerId': sellerId,
      'festivalTag': festivalTag,
    };
  }
}
