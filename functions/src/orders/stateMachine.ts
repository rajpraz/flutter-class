import { OrderStatus, ORDER_STATUS_TRANSITIONS, UserRole } from "../types";

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return ORDER_STATUS_TRANSITIONS[from]?.includes(to) ?? false;
}

/** Who is allowed to *request* which transition. `canTransition` above is
 * the state machine; this is the authorization layer on top of it — e.g. a
 * seller can move an order forward through fulfillment but can't unilaterally
 * mark it "delivered" the instant they ship it (only the ship step), and a
 * buyer can only cancel while nothing has shipped yet. */
export function isTransitionAllowedForRole(params: {
  role: UserRole;
  isBuyer: boolean;
  isSeller: boolean;
  from: OrderStatus;
  to: OrderStatus;
}): boolean {
  const { role, isBuyer, isSeller, from, to } = params;
  if (!canTransition(from, to)) return false;

  if (role === "admin") return true;

  if (to === "cancelled") {
    // Buyer can cancel only before a seller has started fulfilling it.
    if (isBuyer && from === "pending") return true;
    // A seller can cancel their own line items' order up through
    // "processing" (e.g. they discover they can't fulfil it) but not once
    // it has shipped.
    if (isSeller && (from === "pending" || from === "confirmed" || from === "processing")) return true;
    return false;
  }

  if (to === "returned") {
    // Only the buyer initiates a return, and only after delivery.
    return isBuyer && from === "delivered";
  }

  if (to === "refunded") {
    // Refund confirmation is an admin/finance action, not seller or buyer.
    return false;
  }

  // Forward fulfillment moves (confirmed/processing/shipped) are seller-only.
  return isSeller;
}
