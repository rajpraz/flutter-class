import 'package:untitled3/features/reviews/domain/entities/review.dart';

/// Only a buyer who actually purchased and received (status "delivered")
/// the product may review it, and only once per product — verified
/// entirely server-side (functions/src/reviews/createReview.ts), since
/// that check needs to read a different, buyer-owned order document and
/// can't be expressed safely as a Firestore rule.
abstract class ReviewRepository {
  Future<void> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String text,
    List<String> images = const [],
  });

  Stream<List<Review>> streamReviewsForProduct(String productId);

  /// Bounded (not the whole collection) recent-reviews fetch for admin
  /// moderation — the `reviews` collection rule (`allow read: if
  /// isSignedIn();`) already permits this read, no Cloud Function needed.
  Future<List<Review>> fetchRecentReviews({int limit = 100});

  /// Admin-only. Deletes a review and correctly reverses the product's
  /// `ratingAverage`/`ratingCount` — the `reviews` collection denies all
  /// direct client writes, so this can only go through the
  /// `deleteReview` Cloud Function (functions/src/reviews/moderateReview.ts).
  Future<void> deleteReview(String reviewId);
}
