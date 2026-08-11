import { describe, it, expect } from "vitest";
import { subtotal, computeTotals, DELIVERY_FEE } from "../src/utils/pricing";
import { OrderItem } from "../src/types";

function item(overrides: Partial<OrderItem> = {}): OrderItem {
  return {
    productId: "p1",
    name: "Diya Set",
    price: 100,
    qty: 1,
    sellerId: "s1",
    sellerName: "Seller One",
    ...overrides,
  };
}

describe("subtotal", () => {
  it("is zero for an empty item list", () => {
    expect(subtotal([])).toBe(0);
  });

  it("is price * qty for a single item", () => {
    expect(subtotal([item({ price: 150, qty: 3 })])).toBe(450);
  });

  it("sums price * qty across multiple items, including from different sellers", () => {
    const items = [
      item({ productId: "p1", price: 100, qty: 2, sellerId: "s1" }), // 200
      item({ productId: "p2", price: 50, qty: 1, sellerId: "s2" }), // 50
      item({ productId: "p3", price: 75.5, qty: 4, sellerId: "s3" }), // 302
    ];
    expect(subtotal(items)).toBe(552);
  });
});

describe("computeTotals", () => {
  it("charges no delivery fee for an empty order", () => {
    const totals = computeTotals([]);
    expect(totals.subtotal).toBe(0);
    expect(totals.deliveryFee).toBe(0);
    expect(totals.totalAmount).toBe(0);
  });

  it("adds the flat delivery fee once any item is present", () => {
    const totals = computeTotals([item({ price: 100, qty: 1 })]);
    expect(totals.deliveryFee).toBe(DELIVERY_FEE);
    expect(totals.totalAmount).toBe(100 + DELIVERY_FEE);
  });

  it("delivery fee does not scale with item count or quantity — it's flat per order", () => {
    const totals = computeTotals([
      item({ productId: "p1", price: 100, qty: 5 }),
      item({ productId: "p2", price: 200, qty: 3 }),
    ]);
    expect(totals.deliveryFee).toBe(DELIVERY_FEE);
  });

  it("discount and tax are explicitly zero (no coupon/tax system implemented yet)", () => {
    const totals = computeTotals([item()]);
    expect(totals.discount).toBe(0);
    expect(totals.tax).toBe(0);
  });

  it("totalAmount is exactly subtotal + deliveryFee + tax - discount", () => {
    const items = [item({ price: 300, qty: 2 }), item({ productId: "p2", price: 50, qty: 1 })];
    const totals = computeTotals(items);
    expect(totals.totalAmount).toBe(totals.subtotal + totals.deliveryFee + totals.tax - totals.discount);
    expect(totals.totalAmount).toBe(650 + DELIVERY_FEE);
  });

  it("never produces a negative total for well-formed non-negative input", () => {
    const totals = computeTotals([item({ price: 0.01, qty: 1 })]);
    expect(totals.totalAmount).toBeGreaterThan(0);
  });
});
