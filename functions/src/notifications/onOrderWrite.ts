import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import { OrderStatus } from "../types";

const STATUS_MESSAGES: Partial<Record<OrderStatus, (orderShort: string) => { title: string; body: string }>> = {
  confirmed: (id) => ({ title: "Order confirmed", body: `Order #${id} has been confirmed and is being prepared.` }),
  processing: (id) => ({ title: "Order processing", body: `Order #${id} is being processed.` }),
  shipped: (id) => ({ title: "Order shipped", body: `Order #${id} is on its way.` }),
  delivered: (id) => ({ title: "Order delivered", body: `Order #${id} has been delivered. Enjoy!` }),
  cancelled: (id) => ({ title: "Order cancelled", body: `Order #${id} has been cancelled.` }),
  returned: (id) => ({ title: "Return requested", body: `A return was requested for order #${id}.` }),
  refunded: (id) => ({ title: "Order refunded", body: `Order #${id} has been refunded.` }),
};

function shortId(id: string): string {
  return id.slice(0, 8);
}

async function notify(
  db: FirebaseFirestore.Firestore,
  uid: string,
  title: string,
  body: string,
  type: string,
  orderId: string,
) {
  await db.collection("notifications").doc(uid).collection("items").add({
    title,
    body,
    type,
    orderId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * The trusted source of order-related notifications. Previously the client
 * wrote these directly (see lib/services/notification_service.dart), which
 * only worked because firestore.rules allowed any signed-in user to create
 * a notification for any other user — convenient, but it meant nothing
 * stopped a malicious client from spamming arbitrary notification docs into
 * a stranger's inbox. Once this trigger is deployed, the client no longer
 * needs (and firestore.rules should no longer grant) that broad create
 * permission; only this function, running as Admin SDK, writes
 * order-related notifications.
 */
export const onOrderWrite = onDocumentWritten("orders/{orderId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  const orderId = event.params.orderId;
  const db = admin.firestore();
  const id = shortId(orderId);

  if (!before && after) {
    // Created.
    await notify(
      db,
      after.buyerId,
      "Order placed",
      `Your order #${id} of ${after.items?.length ?? 0} item(s) has been placed and is being prepared.`,
      "order_placed",
      orderId,
    );
    const sellerIds: string[] = after.sellerIds ?? [];
    await Promise.all(
      sellerIds.map((sellerId) =>
        notify(db, sellerId, "New order received", `You have a new order #${id} to fulfil.`, "seller_new_order", orderId),
      ),
    );
    return;
  }

  if (before && after && before.status !== after.status) {
    const status = after.status as OrderStatus;
    const message = STATUS_MESSAGES[status];
    if (message) {
      const { title, body } = message(id);
      await notify(db, after.buyerId, title, body, `order_${status}`, orderId);
    }
  }

  if (before && after && before.paymentStatus !== after.paymentStatus) {
    if (after.paymentStatus === "paid") {
      await notify(db, after.buyerId, "Payment received", `Payment for order #${id} was successful.`, "payment_success", orderId);
    } else if (after.paymentStatus === "failed") {
      await notify(db, after.buyerId, "Payment failed", `Payment for order #${id} could not be completed.`, "payment_failure", orderId);
    }
  }
});
