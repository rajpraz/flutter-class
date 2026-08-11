import { describe, it, expect } from "vitest";
import { canTransition, isTransitionAllowedForRole } from "../src/orders/stateMachine";
import { OrderStatus, UserRole } from "../src/types";

const ALL_STATUSES: OrderStatus[] = [
  "pending",
  "confirmed",
  "processing",
  "shipped",
  "delivered",
  "cancelled",
  "returned",
  "refunded",
];

describe("canTransition", () => {
  it("allows every documented forward-fulfillment edge", () => {
    expect(canTransition("pending", "confirmed")).toBe(true);
    expect(canTransition("confirmed", "processing")).toBe(true);
    expect(canTransition("processing", "shipped")).toBe(true);
    expect(canTransition("shipped", "delivered")).toBe(true);
  });

  it("allows cancellation from pending/confirmed/processing", () => {
    expect(canTransition("pending", "cancelled")).toBe(true);
    expect(canTransition("confirmed", "cancelled")).toBe(true);
    expect(canTransition("processing", "cancelled")).toBe(true);
  });

  it("does not allow cancellation once shipped or delivered", () => {
    expect(canTransition("shipped", "cancelled")).toBe(false);
    expect(canTransition("delivered", "cancelled")).toBe(false);
  });

  it("allows return from shipped or delivered, and refund only from returned", () => {
    expect(canTransition("shipped", "returned")).toBe(true);
    expect(canTransition("delivered", "returned")).toBe(true);
    expect(canTransition("returned", "refunded")).toBe(true);
    expect(canTransition("delivered", "refunded")).toBe(false);
  });

  it("cancelled and refunded are terminal — no transition out of them", () => {
    for (const to of ALL_STATUSES) {
      expect(canTransition("cancelled", to)).toBe(false);
      expect(canTransition("refunded", to)).toBe(false);
    }
  });

  it("rejects skipping stages (e.g. pending straight to shipped)", () => {
    expect(canTransition("pending", "processing")).toBe(false);
    expect(canTransition("pending", "shipped")).toBe(false);
    expect(canTransition("pending", "delivered")).toBe(false);
    expect(canTransition("confirmed", "shipped")).toBe(false);
  });

  it("rejects moving backwards", () => {
    expect(canTransition("confirmed", "pending")).toBe(false);
    expect(canTransition("shipped", "processing")).toBe(false);
    expect(canTransition("delivered", "shipped")).toBe(false);
  });
});

function check(
  role: UserRole,
  from: OrderStatus,
  to: OrderStatus,
  opts: { isBuyer?: boolean; isSeller?: boolean } = {},
): boolean {
  return isTransitionAllowedForRole({
    role,
    isBuyer: opts.isBuyer ?? role === "buyer",
    isSeller: opts.isSeller ?? role === "seller",
    from,
    to,
  });
}

describe("isTransitionAllowedForRole — buyer", () => {
  it("can cancel only while pending", () => {
    expect(check("buyer", "pending", "cancelled")).toBe(true);
    expect(check("buyer", "confirmed", "cancelled")).toBe(false);
    expect(check("buyer", "processing", "cancelled")).toBe(false);
  });

  it("can request a return only after delivery", () => {
    expect(check("buyer", "delivered", "returned")).toBe(true);
    expect(check("buyer", "shipped", "returned")).toBe(false);
  });

  it("cannot advance fulfillment stages (that's seller-only)", () => {
    expect(check("buyer", "pending", "confirmed")).toBe(false);
    expect(check("buyer", "confirmed", "processing")).toBe(false);
    expect(check("buyer", "processing", "shipped")).toBe(false);
    expect(check("buyer", "shipped", "delivered")).toBe(false);
  });

  it("can never mark an order refunded", () => {
    expect(check("buyer", "returned", "refunded")).toBe(false);
  });
});

describe("isTransitionAllowedForRole — seller", () => {
  it("can advance every forward-fulfillment stage", () => {
    expect(check("seller", "pending", "confirmed")).toBe(true);
    expect(check("seller", "confirmed", "processing")).toBe(true);
    expect(check("seller", "processing", "shipped")).toBe(true);
    expect(check("seller", "shipped", "delivered")).toBe(true);
  });

  it("can cancel up through processing but never once shipped", () => {
    expect(check("seller", "pending", "cancelled")).toBe(true);
    expect(check("seller", "confirmed", "cancelled")).toBe(true);
    expect(check("seller", "processing", "cancelled")).toBe(true);
    // canTransition itself already forbids shipped->cancelled, so this is
    // doubly guaranteed — asserting it here too documents the intent.
    expect(check("seller", "shipped", "cancelled")).toBe(false);
  });

  it("cannot initiate a buyer return", () => {
    expect(check("seller", "delivered", "returned")).toBe(false);
  });

  it("can never mark an order refunded — that's admin/finance-only", () => {
    expect(check("seller", "returned", "refunded")).toBe(false);
  });
});

describe("isTransitionAllowedForRole — admin", () => {
  it("can perform any transition the state machine's edge graph allows, including refund", () => {
    expect(check("admin", "pending", "confirmed", { isBuyer: false, isSeller: false })).toBe(true);
    expect(check("admin", "shipped", "delivered", { isBuyer: false, isSeller: false })).toBe(true);
    expect(check("admin", "returned", "refunded", { isBuyer: false, isSeller: false })).toBe(true);
    expect(check("admin", "pending", "cancelled", { isBuyer: false, isSeller: false })).toBe(true);
  });

  it("still cannot bypass the underlying state machine (no invented edges)", () => {
    // canTransition("pending", "shipped") is false — admin authority doesn't
    // override the edge graph itself, only the role-specific narrowing.
    expect(check("admin", "pending", "shipped", { isBuyer: false, isSeller: false })).toBe(false);
    expect(check("admin", "cancelled", "confirmed", { isBuyer: false, isSeller: false })).toBe(false);
  });
});

describe("isTransitionAllowedForRole — an uninvolved party can never act", () => {
  it("a buyer/seller flag set to false with a non-admin role is rejected even for an otherwise-valid edge", () => {
    expect(check("buyer", "pending", "confirmed", { isBuyer: false, isSeller: false })).toBe(false);
    expect(check("seller", "pending", "cancelled", { isBuyer: false, isSeller: false })).toBe(false);
  });
});
