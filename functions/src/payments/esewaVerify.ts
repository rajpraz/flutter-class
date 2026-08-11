import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { logger } from "firebase-functions/v2";
import { APP_ENV, ESEWA_MERCHANT_CODE, ESEWA_SECRET_KEY, esewaStatusCheckUrl } from "../config";
import { requireAuth } from "../utils/auth";
import { failedPrecondition, internal, invalidArgument, notFound, permissionDenied } from "../utils/errors";

function sign(message: string, secret: string): string {
  return crypto.createHmac("sha256", secret).update(message).digest("base64");
}

interface EsewaStatusResponse {
  product_code: string;
  transaction_uuid: string;
  status: "COMPLETE" | "PENDING" | "FULL_REFUND" | "PARTIAL_REFUND" | "AMBIGUOUS" | "NOT_FOUND" | "CANCELED";
  total_amount: number;
  ref_id: string | null;
}

/** Calls eSewa's server-to-server transaction-status API for a given
 * `transactionUuid`. Shared by `initiateEsewaPayment` (checking a prior
 * attempt before issuing a new one) and `verifyEsewaPayment` (confirming
 * the current one) so both ask eSewa the same way. */
async function checkEsewaStatus(params: {
  orderId: string;
  transactionUuid: string;
  totalAmount: string;
  productCode: string;
}): Promise<EsewaStatusResponse> {
  const { orderId, transactionUuid, totalAmount, productCode } = params;
  const url = new URL(esewaStatusCheckUrl(APP_ENV.value()));
  url.searchParams.set("product_code", productCode);
  url.searchParams.set("total_amount", totalAmount);
  url.searchParams.set("transaction_uuid", transactionUuid);

  try {
    const res = await fetch(url.toString());
    if (!res.ok) {
      logger.error("eSewa status check HTTP error", { status: res.status, orderId });
      throw internal("Could not verify payment with eSewa right now.");
    }
    return (await res.json()) as EsewaStatusResponse;
  } catch (err) {
    logger.error("eSewa status check failed", { err, orderId });
    throw internal("Could not verify payment with eSewa right now.");
  }
}

/** Writes the "paid" outcome once eSewa has confirmed COMPLETE + matching
 * amount for `transactionUuid`. Shared so a payment discovered already-paid
 * during `initiateEsewaPayment` (see below) and one confirmed via the
 * normal `verifyEsewaPayment` call end up in an identical Firestore state. */
async function markEsewaPaid(
  orderRef: admin.firestore.DocumentReference,
  order: admin.firestore.DocumentData,
  status: EsewaStatusResponse,
  transactionUuid: string,
): Promise<void> {
  const now = admin.firestore.Timestamp.now();
  await orderRef.update({
    paymentStatus: "paid",
    paymentRef: status.ref_id ?? transactionUuid,
    status: order.status === "pending" ? "confirmed" : order.status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    statusHistory: admin.firestore.FieldValue.arrayUnion(
      ...(order.status === "pending"
        ? [{ status: "confirmed", timestamp: now, changedBy: "system:esewa", note: "Payment verified" }]
        : []),
    ),
  });
}

interface InitiateEsewaPaymentInput {
  orderId: string;
}

/**
 * eSewa's v2 integration requires the merchant to sign the checkout form
 * fields (product_code, total_amount, transaction_uuid) with an HMAC
 * secret before redirecting the buyer to eSewa. We generate that signature
 * here — server-side, from the order's authoritative totalAmount — rather
 * than trusting a client-computed amount/signature, and hand the client
 * only what it needs to build the redirect form.
 *
 * Retry safety: if this order already has a `paymentRef` from a prior
 * attempt (e.g. the buyer paid on eSewa's page but the app died before
 * `verifyEsewaPayment` ran, and they're now retrying via the "stuck
 * payment" flow), we check that existing transaction with eSewa BEFORE
 * minting a new one. Skipping this check would let a genuinely-completed
 * payment's `paymentRef` be silently overwritten by a fresh
 * `transactionUuid` on every retry, with nothing left to reconcile against
 * — and the buyer would be walked through paying a second time. A new
 * transaction is only ever issued once we've confirmed the previous one,
 * if any, did NOT actually complete.
 */
export const initiateEsewaPayment = onCall<InitiateEsewaPaymentInput>(
  { secrets: [ESEWA_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const { orderId } = request.data ?? {};
    if (!orderId) throw invalidArgument("orderId is required.");

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) throw notFound("Order not found.");
    const order = orderSnap.data()!;
    if (order.buyerId !== uid) throw permissionDenied("This isn't your order.");
    if (order.paymentMethod !== "esewa") throw failedPrecondition("This order isn't an eSewa order.");
    if (order.paymentStatus === "paid") throw failedPrecondition("This order is already paid.");

    const productCode = ESEWA_MERCHANT_CODE.value();
    const totalAmount = Number(order.totalAmount).toFixed(2);

    const priorTransactionUuid: string | undefined = order.paymentRef || undefined;
    if (priorTransactionUuid) {
      const priorStatus = await checkEsewaStatus({
        orderId,
        transactionUuid: priorTransactionUuid,
        totalAmount,
        productCode,
      });
      if (priorStatus.status === "COMPLETE" && Number(priorStatus.total_amount) === Number(totalAmount)) {
        // The previous attempt actually went through — finalize it instead
        // of ever generating a second payable transaction.
        await markEsewaPaid(orderRef, order, priorStatus, priorTransactionUuid);
        throw failedPrecondition("This order is already paid.");
      }
      // Anything else (PENDING/NOT_FOUND/CANCELED/etc.) means the prior
      // attempt genuinely didn't complete — safe to issue a fresh one below.
    }

    const transactionUuid = `${orderId}-${Date.now()}`;
    const message = `total_amount=${totalAmount},transaction_uuid=${transactionUuid},product_code=${productCode}`;
    const signature = sign(message, ESEWA_SECRET_KEY.value());

    await orderRef.update({ paymentRef: transactionUuid, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

    return {
      productCode,
      totalAmount,
      transactionUuid,
      signature,
      signedFieldNames: "total_amount,transaction_uuid,product_code",
    };
  },
);

interface VerifyEsewaPaymentInput {
  orderId: string;
}

/**
 * Confirms an eSewa payment by calling eSewa's server-to-server
 * transaction-status API (never by trusting the client's return-URL
 * callback, which is not authenticated proof of payment). Compares both
 * status and amount before marking the order paid.
 */
export const verifyEsewaPayment = onCall<VerifyEsewaPaymentInput>(
  { secrets: [ESEWA_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const { orderId } = request.data ?? {};
    if (!orderId) throw invalidArgument("orderId is required.");

    const db = admin.firestore();
    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) throw notFound("Order not found.");
    const order = orderSnap.data()!;
    if (order.buyerId !== uid) throw permissionDenied("This isn't your order.");
    if (order.paymentMethod !== "esewa") throw failedPrecondition("This order isn't an eSewa order.");
    if (order.paymentStatus === "paid") return { success: true, alreadyVerified: true };

    const transactionUuid = order.paymentRef;
    if (!transactionUuid) throw failedPrecondition("Payment was never initiated for this order.");

    const productCode = ESEWA_MERCHANT_CODE.value();
    const totalAmount = Number(order.totalAmount).toFixed(2);
    const status = await checkEsewaStatus({ orderId, transactionUuid, totalAmount, productCode });

    if (status.status !== "COMPLETE") {
      throw failedPrecondition(`Payment not completed (status: ${status.status}).`);
    }
    if (Number(status.total_amount) !== Number(totalAmount)) {
      logger.error("eSewa amount mismatch", { orderId, expected: totalAmount, got: status.total_amount });
      throw failedPrecondition("Payment amount does not match the order total.");
    }

    await markEsewaPaid(orderRef, order, status, transactionUuid);

    return { success: true, alreadyVerified: false };
  },
);
