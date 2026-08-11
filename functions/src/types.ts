/** Shared types for trusted backend logic. Mirrors (and is the source of truth
 * ahead of) the Dart models in lib/models — the client models should be kept
 * in sync with the field names here. */

export type UserRole = "buyer" | "seller" | "admin";

export type OrderStatus =
  | "pending"
  | "confirmed"
  | "processing"
  | "shipped"
  | "delivered"
  | "cancelled"
  | "returned"
  | "refunded";

export type PaymentStatus =
  | "pending"
  | "processing"
  | "paid"
  | "failed"
  | "refunded"
  | "partially_refunded";

export type PaymentMethod = "khalti" | "esewa" | "cod";

/** Valid forward transitions for orderStatus. Enforced identically here and
 * (as far as Firestore rules can express it) in firestore.rules, so a status
 * can never move backwards or skip in a way that would confuse fulfillment
 * or refunds. */
export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["processing", "cancelled"],
  processing: ["shipped", "cancelled"],
  shipped: ["delivered", "returned"],
  delivered: ["returned"],
  cancelled: [],
  returned: ["refunded"],
  refunded: [],
};

export interface OrderItem {
  productId: string;
  name: string;
  price: number;
  qty: number;
  sellerId: string;
  /** Denormalized from products.sellerName at order-creation time (same
   * reasoning as Product.sellerName — a buyer can't read another user's
   * profile doc, so this is stamped in rather than looked up later). May
   * be empty for products created before this field existed. */
  sellerName: string;
}

export interface StatusHistoryEntry {
  status: OrderStatus;
  timestamp: FirebaseFirestore.Timestamp;
  changedBy: string;
  note: string;
}

export interface OrderDoc {
  buyerId: string;
  sellerIds: string[];
  items: OrderItem[];
  subtotal: number;
  deliveryFee: number;
  discount: number;
  tax: number;
  totalAmount: number;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  paymentMethod: PaymentMethod;
  paymentRef: string | null;
  shippingAddress: string;
  statusHistory: StatusHistoryEntry[];
  createdAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
  updatedAt: FirebaseFirestore.Timestamp | FirebaseFirestore.FieldValue;
}

export interface ProductDoc {
  name: string;
  description: string;
  price: number;
  category: string;
  images: string[];
  stock: number;
  lowStockThreshold: number;
  sellerId: string;
  /** Denormalized from the seller's own profile at product create/edit
   * time — see lib/features/seller/products/presentation/pages/
   * add_product_page.dart. Present so createOrder.ts can copy it onto
   * OrderItem.sellerName without a buyer needing to read another user's
   * profile doc. May be empty on products created before this field
   * existed. */
  sellerName: string;
  isActive: boolean;
  festivalTag: string;
  ratingAverage: number;
  ratingCount: number;
}

export interface CartLineInput {
  productId: string;
  qty: number;
}
