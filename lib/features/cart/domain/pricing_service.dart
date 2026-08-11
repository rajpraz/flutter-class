import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/cart/domain/entities/cart_line_validation.dart';

/// Client-side preview pricing only — for what the cart screen displays
/// before checkout. The authoritative total that's actually charged is
/// always recomputed server-side in functions/src/orders/createOrder.ts
/// (functions/src/utils/pricing.ts), from freshly-read product prices, not
/// from this. Keep the delivery fee constant here in sync with that file
/// so the preview and the real total don't visibly disagree.
class PricingService {
  static const double deliveryFee = 80;

  /// No coupon/promo-code system exists yet (that needs backend work — a
  /// Cloud Function to validate/apply codes — out of scope here). Kept as
  /// an explicit line item rather than omitted so the summary isn't
  /// misleading about what the total is made of; wire this up for real
  /// once a discount backend exists.
  static const double discount = 0;

  static double subtotal(List<CartItem> items) =>
      items.fold<double>(0, (sum, item) => sum + item.subtotal);

  static double total(List<CartItem> items) => subtotal(items) + deliveryFee - discount;

  /// Same idea, but only over lines that are actually purchasable right
  /// now (see `CartLineValidation`) and priced at their *current* value —
  /// used once cart validation data is available so the preview total
  /// matches what checkout will actually attempt to charge for.
  static double subtotalFromValidated(List<CartLineValidation> lines) => lines
      .where((line) => line.isPurchasable)
      .fold<double>(0, (sum, line) => sum + line.effectiveSubtotal);

  static double totalFromValidated(List<CartLineValidation> lines) {
    final purchasable = lines.where((line) => line.isPurchasable);
    if (purchasable.isEmpty) return 0;
    return subtotalFromValidated(lines) + deliveryFee - discount;
  }
}
