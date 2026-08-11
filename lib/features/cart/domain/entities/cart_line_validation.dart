import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/products/domain/entities/product.dart';

/// A cart line checked against the product's *current* Firestore state —
/// not what was true when it was added to the cart. Display-only; the
/// authoritative check happens again, unconditionally, inside
/// `createOrder` server-side.
class CartLineValidation {
  final CartItem item;
  final Product? product;

  const CartLineValidation({required this.item, required this.product});

  bool get exists => product != null;
  bool get isActive => product?.isActive ?? false;
  bool get inStock => (product?.stock ?? 0) >= item.qty;
  bool get priceChanged => product != null && product!.price != item.price;

  /// Whether this line can actually be checked out as-is right now.
  bool get isPurchasable => exists && isActive && inStock;

  /// The price to actually charge if purchasable — the live price, not
  /// the (possibly stale) one captured when it was added to the cart.
  double get effectivePrice => product?.price ?? item.price;

  double get effectiveSubtotal => effectivePrice * item.qty;
}
