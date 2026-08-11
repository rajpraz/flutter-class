import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * Notifies a seller when one of their products crosses below its
 * lowStockThreshold (defaults to 5 if unset) — fires once per crossing, not
 * on every write, by comparing before/after stock against the threshold.
 */
export const onLowStock = onDocumentWritten("products/{productId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after) return; // deleted

  const threshold = Number(after.lowStockThreshold ?? 5);
  const stockAfter = Number(after.stock ?? 0);
  const stockBefore = before ? Number(before.stock ?? 0) : Number.MAX_SAFE_INTEGER;

  const crossedIntoLowStock = stockBefore > threshold && stockAfter <= threshold && stockAfter > 0;
  const justSoldOut = stockBefore > 0 && stockAfter === 0;
  if (!crossedIntoLowStock && !justSoldOut) return;

  const db = admin.firestore();
  await db
    .collection("notifications")
    .doc(String(after.sellerId))
    .collection("items")
    .add({
      title: justSoldOut ? "Product out of stock" : "Low stock warning",
      body: justSoldOut
        ? `"${after.name}" is now out of stock.`
        : `"${after.name}" has only ${stockAfter} left in stock.`,
      type: justSoldOut ? "out_of_stock" : "low_stock",
      orderId: null,
      productId: event.params.productId,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
