import 'package:untitled3/models/cart_item.dart';

/// Single source of truth for cart/order pricing so the cart screen, the
/// checkout screen, and the order-creation transaction can never disagree
/// about totals.
class PricingService {
  static const double deliveryFee = 80;

  static double subtotal(List<CartItem> items) =>
      items.fold<double>(0, (sum, item) => sum + item.subtotal);

  static double total(List<CartItem> items) => subtotal(items) + deliveryFee;
}
