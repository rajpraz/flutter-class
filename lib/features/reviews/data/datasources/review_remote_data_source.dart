import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/core/network/functions_client.dart';
import 'package:untitled3/features/reviews/domain/entities/review.dart';

class ReviewRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> _reviews =
      FirebaseFirestore.instance.collection('reviews');

  /// Review creation is exclusively via the `createReview` Cloud Function
  /// (see functions/src/reviews/createReview.ts) — it verifies the caller
  /// actually bought and received the product, which needs a cross-document
  /// read only trusted backend code can safely do. Reading reviews back,
  /// below, is a plain direct Firestore query — the `reviews` collection
  /// rule (`allow read: if isSignedIn();`) already allows it, and there's
  /// no equivalent trust problem for reads.
  Future<void> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
    List<String> images = const [],
  }) async {
    await FunctionsClient.call('createReview', {
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'text': text,
      'images': images,
    });
  }

  Stream<List<Review>> streamReviewsForProduct(String productId) {
    return _reviews
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Review.fromDoc).toList());
  }

  Future<List<Review>> fetchRecentReviews({int limit = 100}) async {
    final snap = await _reviews.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Review.fromDoc).toList();
  }

  /// Deletion (and the rating-aggregate reversal it requires) is
  /// exclusively via the `deleteReview` Cloud Function — the `reviews`
  /// collection rule denies all direct client writes.
  Future<void> deleteReview(String reviewId) async {
    await FunctionsClient.call('deleteReview', {'reviewId': reviewId});
  }
}
