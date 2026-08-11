import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { OrderStatus } from "../types";
import { currentRole, requireAuth } from "../utils/auth";
import { failedPrecondition, invalidArgument, notFound, permissionDenied } from "../utils/errors";
import { isTransitionAllowedForRole } from "./stateMachine";

interface UpdateOrderStatusInput {
  orderId: string;
  status: OrderStatus;
  note?: string;
}

const RESTOCK_ON: OrderStatus[] = ["cancelled", "returned"];

/**
 * The one and only trusted way an order's status changes. Validates the
 * transition against the same state machine used by firestore.rules
 * (defensive backend enforcement, since rules alone can't re-check stock),
 * checks the caller is actually the buyer/seller/admin authorized to make
 * *this* transition (see `isTransitionAllowedForRole`), appends a
 * `statusHistory` entry, and — for cancellation/return — restores the stock
 * that was reserved at order creation, atomically with the status write.
 */
export const updateOrderStatus = onCall<UpdateOrderStatusInput>(async (request) => {
  const uid = requireAuth(request);
  const role = currentRole(request);
  const { orderId, status, note } = request.data ?? {};

  if (!orderId || typeof orderId !== "string") throw invalidArgument("orderId is required.");
  const validTargets: OrderStatus[] = [
    "pending",
    "confirmed",
    "processing",
    "shipped",
    "delivered",
    "cancelled",
    "returned",
    "refunded",
  ];
  if (!validTargets.includes(status)) throw invalidArgument("Invalid status.");

  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) throw notFound("Order not found.");
    const order = orderSnap.data()!;

    const isBuyer = order.buyerId === uid;
    const isSeller = Array.isArray(order.sellerIds) && order.sellerIds.includes(uid);
    if (!isBuyer && !isSeller && role !== "admin") {
      throw permissionDenied("You are not part of this order.");
    }

    const from = order.status as OrderStatus;
    if (from === status) return; // idempotent no-op

    if (!isTransitionAllowedForRole({ role, isBuyer, isSeller, from, to: status })) {
      throw failedPrecondition(`Order cannot move from "${from}" to "${status}" for your role.`);
    }

    const now = admin.firestore.Timestamp.now();
    tx.update(orderRef, {
      status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      statusHistory: admin.firestore.FieldValue.arrayUnion({
        status,
        timestamp: now,
        changedBy: uid,
        note: (note ?? "").trim(),
      }),
    });

    if (RESTOCK_ON.includes(status)) {
      const items = (order.items ?? []) as { productId: string; qty: number }[];
      const productRefs = items.map((item) => db.collection("products").doc(item.productId));
      const productDocs = await Promise.all(productRefs.map((ref) => tx.get(ref)));
      productDocs.forEach((doc, i) => {
        if (!doc.exists) return;
        const currentStock = Number(doc.data()?.stock ?? 0);
        tx.update(productRefs[i], {
          stock: currentStock + items[i].qty,
          lastOrderId: orderId,
        });
      });
    }
  });

  return { success: true };
});
