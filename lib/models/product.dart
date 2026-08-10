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
  final DateTime? createdAt;
  final bool isActive;
  final String festivalTag;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.stock,
    required this.sellerId,
    required this.isActive,
    this.createdAt,
    this.festivalTag = '',
  });

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
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      festivalTag: map['festivalTag'] ?? '',
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
      'isActive': isActive,
      'festivalTag': festivalTag,
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
