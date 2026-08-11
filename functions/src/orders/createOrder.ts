import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { CartLineInput, OrderItem, PaymentMethod } from "../types";
import { requireAuth } from "../utils/auth";
import { computeTotals } from "../utils/pricing";
import { failedPrecondition, invalidArgument } from "../utils/errors";

interface CreateOrderInput {
  items: CartLineInput[];
  shippingAddress: string;
  paymentMethod: PaymentMethod;
  /** Optional client-generated token so a double-tap or retried network
   * request can't create two orders for the same checkout attempt. */
  idempotencyKey?: string;
}

const VALID_PAYMENT_METHODS: PaymentMethod[] = ["khalti", "esewa", "cod"];

/**
 * The one and only trusted way an order gets created. Mirrors (and
 * supersedes, once deployed) the logic in
 * lib/services/order_service.dart#createOrder: every product is re-read
 * from Firestore inside a transaction, price/stock/active/seller are taken
 * only from that read (never from the client's cart line), stock is
 * decremented atomically with the order write, and the whole thing either
 * fully succeeds or fully rolls back.
 *
 * paymentStatus starts "pending" for every method — createOrder never marks
 * anything paid. For khalti/esewa, the client must follow up with
 * `verifyKhaltiPayment` / `verifyEsewaPayment` after the gateway redirect;
 * for COD, paymentStatus stays "pending" until the seller/admin marks it
 * paid on delivery.
 */
export const createOrder = onCall<CreateOrderInput>(async (request) => {
  const buyerId = requireAuth(request);
  const { items, shippingAddress, paymentMethod, idempotencyKey } = request.data ?? {};

  if (!Array.isArray(items) || items.length === 0) {
    throw invalidArgument("Your cart is empty.");
  }
  if (!shippingAddress?.trim()) {
    throw invalidArgument("A shipping address is required.");
  }
  if (!VALID_PAYMENT_METHODS.includes(paymentMethod)) {
    throw invalidArgument("Invalid payment method.");
  }
  for (const line of items) {
    if (!line.productId || !Number.isInteger(line.qty) || line.qty < 1) {
      throw invalidArgument("Each cart line needs a valid productId and a positive integer qty.");
    }
  }

  const db = admin.firestore();

  if (idempotencyKey) {
    const idemRef = db.collection("orderIdempotency").doc(`${buyerId}_${idempotencyKey}`);
    const idemSnap = await idemRef.get();
    if (idemSnap.exists) {
      return {
        orderId: idemSnap.data()?.orderId as string,
        totalAmount: idemSnap.data()?.totalAmount as number,
        deduplicated: true,
      };
    }
  }

  const orderRef = db.collection("orders").doc();
  const productIds = [...new Set(items.map((line) => line.productId))];
  const productRefs = productIds.map((id) => db.collection("products").doc(id));

  const created = await db.runTransaction(async (tx) => {
    const productDocs = await Promise.all(productRefs.map((ref) => tx.get(ref)));
    const productById = new Map(productDocs.map((doc) => [doc.id, doc]));

    const verifiedItems: OrderItem[] = [];
    for (const line of items) {
      const doc = productById.get(line.productId);
      if (!doc || !doc.exists) {
        throw failedPrecondition(`One of the items in your cart is no longer available.`);
      }
      const data = doc.data()!;
      const isActive = data.isActive ?? true;
      const stock = Number(data.stock ?? 0);
      const price = Number(data.price ?? 0);
      const name = String(data.name ?? "");
      const sellerId = String(data.sellerId ?? "");
      const sellerName = String(data.sellerName ?? "");

      if (!isActive) {
        throw failedPrecondition(`${name || "An item"} in your cart is no longer available.`);
      }
      if (stock < line.qty) {
        throw failedPrecondition(
          stock === 0 ? `${name} is out of stock.` : `Only ${stock} left of ${name}.`,
        );
      }

      verifiedItems.push({ productId: line.productId, name, price, qty: line.qty, sellerId, sellerName });
    }

    const totals = computeTotals(verifiedItems);
    const sellerIds = [...new Set(verifiedItems.map((item) => item.sellerId))];
    const now = admin.firestore.FieldValue.serverTimestamp();

    tx.set(orderRef, {
      buyerId,
      sellerIds,
      items: verifiedItems,
      subtotal: totals.subtotal,
      deliveryFee: totals.deliveryFee,
      discount: totals.discount,
      tax: totals.tax,
      totalAmount: totals.totalAmount,
      status: "pending",
      paymentStatus: "pending",
      paymentMethod,
      paymentRef: null,
      shippingAddress: shippingAddress.trim(),
      statusHistory: [{ status: "pending", timestamp: admin.firestore.Timestamp.now(), changedBy: buyerId, note: "Order placed" }],
      createdAt: now,
      updatedAt: now,
    });

    for (const productId of productIds) {
      const qtyOrdered = items
        .filter((line) => line.productId === productId)
        .reduce((sum, line) => sum + line.qty, 0);
      const currentStock = Number(productById.get(productId)!.data()!.stock ?? 0);
      tx.update(productRefs.find((ref) => ref.id === productId)!, {
        stock: currentStock - qtyOrdered,
        lastOrderId: orderRef.id,
      });
    }

    if (idempotencyKey) {
      tx.set(db.collection("orderIdempotency").doc(`${buyerId}_${idempotencyKey}`), {
        orderId: orderRef.id,
        totalAmount: totals.totalAmount,
        createdAt: now,
      });
    }

    return { orderId: orderRef.id, totalAmount: totals.totalAmount };
  });

  return { orderId: created.orderId, totalAmount: created.totalAmount, deduplicated: false };
});
