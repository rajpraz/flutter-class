import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/categories/domain/entities/category.dart';

class CategoryRemoteDataSource {
  static final _categories = FirebaseFirestore.instance.collection('categories');

  /// `isActive == true` + `orderBy sortOrder` — an equality filter combined
  /// with an orderBy on a different field is served by Firestore's
  /// automatic single-field indexes, so no composite index entry is needed
  /// (same reasoning as the existing `products` isActive+createdAt query).
  Stream<List<Category>> streamActiveCategories() {
    return _categories
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(Category.fromDoc).toList());
  }

  /// Admin-only view (enforced by firestore.rules — `allow read: if
  /// isSignedIn() && (resource.data.isActive == true || isAdmin());` — a
  /// non-admin querying this unfiltered would simply have inactive docs
  /// excluded from the result, not an error, but the UI route this feeds is
  /// itself admin-gated).
  Stream<List<Category>> streamAllCategories() {
    return _categories
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(Category.fromDoc).toList());
  }

  Future<void> createCategory(Category category) async {
    await _categories.add({
      'name': category.name,
      'imageUrl': category.imageUrl,
      'isActive': category.isActive,
      'sortOrder': category.sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    await _categories.doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String id, bool isActive) async {
    await updateCategory(id, {'isActive': isActive});
  }
}
