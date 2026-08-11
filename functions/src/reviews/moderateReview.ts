import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { requireRole } from "../utils/auth";
import { invalidArgument, notFound } from "../utils/errors";

interface DeleteReviewInput {
  reviewId: string;
}

/**
 * Admin-only moderation: removes a review and correctly reverses the
 * rating-aggregate math `createReview.ts` applied when it was added —
 * never just deletes the doc and leaves `ratingAverage`/`ratingCount`
 * stale. Delete-only (no edit-review-content action): editing someone
 * else's review text is a different, murkier feature not requested here.
 */
export const deleteReview = onCall<DeleteReviewInput>(async (request) => {
  requireRole(request, ["admin"]);
  const { reviewId } = request.data ?? {};
  if (!reviewId) throw invalidArgument("reviewId is required.");

  const db = admin.firestore();
  const reviewRef = db.collection("reviews").doc(reviewId);

  await db.runTransaction(async (tx) => {
    const reviewSnap = await tx.get(reviewRef);
    if (!reviewSnap.exists) throw notFound("Review not found.");
    const review = reviewSnap.data()!;

    const productRef = db.collection("products").doc(String(review.productId));
    const productSnap = await tx.get(productRef);

    tx.delete(reviewRef);

    if (productSnap.exists) {
      const currentAvg = Number(productSnap.data()?.ratingAverage ?? 0);
      const currentCount = Number(productSnap.data()?.ratingCount ?? 0);
      const newCount = currentCount - 1;
      const newAvg = newCount <= 0 ? 0 : (currentAvg * currentCount - Number(review.rating ?? 0)) / newCount;
      tx.update(productRef, {
        ratingAverage: newCount <= 0 ? 0 : newAvg,
        ratingCount: newCount <= 0 ? 0 : newCount,
      });
    }
  });

  return { success: true };
});
