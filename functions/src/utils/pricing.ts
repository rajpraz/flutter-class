import { OrderItem } from "../types";

/** Single source of truth for order pricing on the backend — mirrors
 * lib/services/pricing_service.dart so the client's displayed totals and
 * the server's authoritative totals never disagree. The client's number is
 * only ever a preview; `createOrder` recomputes this from freshly-read
 * product documents and that recomputed value is what gets charged. */
export const DELIVERY_FEE = 80;

export function subtotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.qty, 0);
}

export function computeTotals(items: OrderItem[]): {
  subtotal: number;
  deliveryFee: number;
  discount: number;
  tax: number;
  totalAmount: number;
} {
  const sub = subtotal(items);
  const deliveryFee = items.length > 0 ? DELIVERY_FEE : 0;
  const discount = 0; // Coupon support is not implemented yet; kept explicit
  // rather than omitted so the order document always documents every
  // component of the total.
  const tax = 0; // No VAT/tax is currently charged.
  return {
    subtotal: sub,
    deliveryFee,
    discount,
    tax,
    totalAmount: sub + deliveryFee + tax - discount,
  };
}
