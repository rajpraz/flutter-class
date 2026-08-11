import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: (map['name'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
