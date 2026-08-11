import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { APP_ENV, KHALTI_SECRET_KEY, khaltiBaseUrl } from "../config";
import { requireAuth } from "../utils/auth";
import { failedPrecondition, internal, invalidArgument, notFound, permissionDenied } from "../utils/errors";

interface VerifyKhaltiPaymentInput {
  orderId: string;
  /** Khalti's payment identifier returned to the client after checkout
   * (`pidx`), NOT anything describing success/failure — we never trust that
   * part of the client's report. */
  pidx: string;
}

interface KhaltiLookupResponse {
  pidx: string;
  status: "Completed" | "Pending" | "Expired" | "Initiated" | "Refunded" | "User canceled";
  total_amount: number; // paisa
  transaction_id: string | null;
}

/**
 * Confirms a Khalti payment actually happened, for the exact amount the
 * order requires, by calling Khalti's server-to-server Epayment Lookup API
 * with our secret key — never by trusting the client's "payment succeeded"
 * callback. This is the only function allowed to move an order's
 * paymentStatus to "paid" for a Khalti order, and it also advances
 * orderStatus pending -> confirmed once payment clears, since a Khalti
 * order isn't legitimately "confirmed" until it's actually paid for.
 */
export const verifyKhaltiPayment = onCall<VerifyKhaltiPaymentInput>(
  { secrets: [KHALTI_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const { orderId, pidx } = request.data ?? {};
    if (!orderId || !pidx) throw invalidArgument("orderId and pidx are required.");

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) throw notFound("Order not found.");
    const order = orderSnap.data()!;
    if (order.buyerId !== uid) throw permissionDenied("This isn't your order.");
    if (order.paymentMethod !== "khalti") throw failedPrecondition("This order isn't a Khalti order.");

    if (order.paymentStatus === "paid") {
      return { success: true, alreadyVerified: true };
    }

    // Concurrency note: two overlapping calls (double-tap, client retry
    // after a slow response) can both pass this check before either writes
    // below — not transactional. This is intentionally not upgraded to a
    // Firestore transaction: both calls independently ask Khalti's lookup
    // API for the same pidx (idempotent, side-effect-free on Khalti's end)
    // and, if both see "Completed" with a matching amount, both write the
    // same paymentStatus/paymentRef/status values. A duplicate write of
    // identical data is harmless; `statusHistory`'s `arrayUnion` further
    // dedupes the confirmation entry itself (arrayUnion won't add a second
    // identical object, though a differing `timestamp` field between the
    // two calls means in practice at most one extra history entry could
    // land — acceptable, since it would carry the same status/note and
    // not change the order's paymentStatus/orderStatus).
    let lookup: KhaltiLookupResponse;
    try {
      const res = await fetch(`${khaltiBaseUrl(APP_ENV.value())}/epayment/lookup/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Key ${KHALTI_SECRET_KEY.value()}`,
        },
        body: JSON.stringify({ pidx }),
      });
      if (!res.ok) {
        logger.error("Khalti lookup HTTP error", { status: res.status, orderId });
        throw internal("Could not verify payment with Khalti right now.");
      }
      lookup = (await res.json()) as KhaltiLookupResponse;
    } catch (err) {
      logger.error("Khalti lookup failed", { err, orderId });
      throw internal("Could not verify payment with Khalti right now.");
    }

    if (lookup.status !== "Completed") {
      await orderRef.update({
        paymentStatus: lookup.status === "Refunded" ? "refunded" : "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw failedPrecondition(`Payment not completed (status: ${lookup.status}).`);
    }

    const expectedPaisa = Math.round(Number(order.totalAmount) * 100);
    if (lookup.total_amount !== expectedPaisa) {
      logger.error("Khalti amount mismatch", {
        orderId,
        expectedPaisa,
        gotPaisa: lookup.total_amount,
      });
      throw failedPrecondition("Payment amount does not match the order total.");
    }

    const now = admin.firestore.Timestamp.now();
    await orderRef.update({
      paymentStatus: "paid",
      paymentRef: lookup.transaction_id ?? pidx,
      status: order.status === "pending" ? "confirmed" : order.status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      statusHistory: admin.firestore.FieldValue.arrayUnion(
        ...(order.status === "pending"
          ? [{ status: "confirmed", timestamp: now, changedBy: "system:khalti", note: "Payment verified" }]
          : []),
      ),
    });

    return { success: true, alreadyVerified: false };
  },
);
