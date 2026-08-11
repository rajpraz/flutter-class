import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { currentRole, requireAuth, requireRole } from "../utils/auth";
import { failedPrecondition, invalidArgument, notFound, permissionDenied } from "../utils/errors";

interface ConfirmCodPaymentInput {
  orderId: string;
}

/**
 * Cash-on-Delivery orders are created with paymentStatus "pending" and stay
 * that way until cash is actually collected. Only a seller on the order (or
 * an admin) can mark it paid, and only once the order has actually been
 * delivered — this is the trusted alternative to a gateway verification
 * call for the one payment method that has no gateway to verify against.
 */
export const confirmCodPayment = onCall<ConfirmCodPaymentInput>(async (request) => {
  const uid = requireAuth(request);
  const role = currentRole(request);
  const { orderId } = request.data ?? {};
  if (!orderId) throw invalidArgument("orderId is required.");

  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw notFound("Order not found.");
  const order = orderSnap.data()!;

  const isSeller = Array.isArray(order.sellerIds) && order.sellerIds.includes(uid);
  if (!isSeller && role !== "admin") {
    throw permissionDenied("Only a seller on this order (or an admin) can confirm COD payment.");
  }
  if (order.paymentMethod !== "cod") throw failedPrecondition("This order isn't Cash on Delivery.");
  if (order.status !== "delivered") throw failedPrecondition("Order must be delivered before confirming payment.");
  if (order.paymentStatus === "paid") return { success: true, alreadyConfirmed: true };

  await orderRef.update({
    paymentStatus: "paid",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, alreadyConfirmed: false };
});

interface MarkRefundedInput {
  orderId: string;
  partial?: boolean;
}

/**
 * Admin-only. Gateway-initiated refunds for Khalti/eSewa still have to be
 * triggered from their merchant dashboards today (neither exposes a
 * reliable public refund API for this integration tier) — this just
 * records the outcome in Firestore once that's done manually, so
 * paymentStatus stays accurate instead of stuck on "paid".
 */
export const markRefunded = onCall<MarkRefundedInput>(async (request) => {
  requireRole(request, ["admin"]);
  const { orderId, partial } = request.data ?? {};
  if (!orderId) throw invalidArgument("orderId is required.");

  const db = admin.firestore();
  const orderRef = db.collection("orders").doc(orderId);
  const orderSnap = await orderRef.get();
  if (!orderSnap.exists) throw notFound("Order not found.");

  await orderRef.update({
    paymentStatus: partial ? "partially_refunded" : "refunded",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
