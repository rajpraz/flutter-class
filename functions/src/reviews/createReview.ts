import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { requireAuth } from "../utils/auth";
import { failedPrecondition, invalidArgument, permissionDenied } from "../utils/errors";

interface CreateReviewInput {
  productId: string;
  orderId: string;
  rating: number;
  text: string;
  images?: string[];
}

/**
 * Only a buyer who actually purchased and received (status "delivered") the
 * product may review it, and only once per product. This can't be
 * expressed safely in Firestore rules alone (checking "does some other
 * order document owned by this user contain this product and have status
 * delivered" is exactly the kind of cross-document check rules are bad at),
 * so review creation happens exclusively through this callable — the
 * `reviews` collection should deny direct client writes entirely in
 * firestore.rules.
 */
export const createReview = onCall<CreateReviewInput>(async (request) => {
  const buyerId = requireAuth(request);
  const { productId, orderId, rating, text, images } = request.data ?? {};

  if (!productId || !orderId) throw invalidArgument("productId and orderId are required.");
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw invalidArgument("rating must be an integer from 1 to 5.");
  }
  if (!text?.trim()) throw invalidArgument("Review text is required.");

  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const productRef = db.collection("products").doc(productId);
  const reviewRef = db.collection("reviews").doc(`${buyerId}_${productId}`);

  await db.runTransaction(async (tx) => {
    const [orderSnap, productSnap, existingReview] = await Promise.all([
      tx.get(orderRef),
      tx.get(productRef),
      tx.get(reviewRef),
    ]);

    if (!orderSnap.exists) throw failedPrecondition("Order not found.");
    const order = orderSnap.data()!;
    if (order.buyerId !== buyerId) throw permissionDenied("This isn't your order.");
    if (order.status !== "delivered") {
      throw failedPrecondition("You can only review products after delivery.");
    }
    const items = (order.items ?? []) as { productId: string }[];
    if (!items.some((item) => item.productId === productId)) {
      throw failedPrecondition("This product wasn't part of that order.");
    }
    if (existingReview.exists) {
      throw failedPrecondition("You've already reviewed this product.");
    }
    if (!productSnap.exists) throw failedPrecondition("Product no longer exists.");

    const now = admin.firestore.FieldValue.serverTimestamp();
    tx.set(reviewRef, {
      productId,
      orderId,
      buyerId,
      rating,
      text: text.trim(),
      images: Array.isArray(images) ? images.slice(0, 6) : [],
      verifiedPurchase: true,
      createdAt: now,
    });

    const currentAvg = Number(productSnap.data()?.ratingAverage ?? 0);
    const currentCount = Number(productSnap.data()?.ratingCount ?? 0);
    const newCount = currentCount + 1;
    const newAvg = (currentAvg * currentCount + rating) / newCount;
    tx.update(productRef, { ratingAverage: newAvg, ratingCount: newCount });
  });

  return { success: true };
});
