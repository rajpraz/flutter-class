import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/core/widgets/app_bottom_nav.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';
import 'package:untitled3/features/cart/domain/entities/cart_line_validation.dart';
import 'package:untitled3/features/cart/domain/pricing_service.dart';
import 'package:untitled3/features/cart/presentation/providers/cart_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Widget buildCartImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: AppColors.card,
        child: const Icon(Icons.temple_hindu, color: AppColors.primary),
      );
    }
    return Image.network(
      imagePath,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 56,
          height: 56,
          color: Colors.orange.shade100,
          child: const Icon(Icons.temple_hindu, color: Colors.deepOrange),
        );
      },
    );
  }

  Future<void> _updateQty(
      BuildContext context, WidgetRef ref, String uid, CartLineValidation line, int delta) async {
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .updateQty(uid, line.item.productId, line.item.qty + delta);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update cart: ${friendlyErrorMessage(e)}')));
    }
  }

  Future<void> _removeItem(BuildContext context, WidgetRef ref, String uid, String productId) async {
    try {
      await ref.read(cartControllerProvider.notifier).removeItem(uid, productId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item removed from cart')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not remove item: ${friendlyErrorMessage(e)}')));
    }
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This will remove all items from your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(cartControllerProvider.notifier).clearCart(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cart cleared')));
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context, double totalPrice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: const Text('Proceed to checkout for your puja order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(RouteNames.checkoutPath(totalPrice));
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your cart')));
    }

    final validationAsync = ref.watch(cartValidationProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (validationAsync.hasValue && validationAsync.value!.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear cart',
                onPressed: () => _confirmClearCart(context, ref, uid))
        ],
      ),
      body: validationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load cart: $err')),
        data: (lines) {
          final totalPrice = PricingService.subtotalFromValidated(lines);
          final hasBlockingIssue = lines.any((line) => !line.isPurchasable);

          return Column(
            children: [
              Expanded(
                child: lines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 60, color: AppColors.accent),
                            const SizedBox(height: 10),
                            const Text('Your cart is empty',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Add puja essentials to start your order.',
                                style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.go(RouteNames.home),
                              child: const Text('Browse Products'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          return _CartLineTile(
                            line: line,
                            onIncrease: () => _updateQty(context, ref, uid, line, 1),
                            onDecrease: () => _updateQty(context, ref, uid, line, -1),
                            onRemove: () => _removeItem(context, ref, uid, line.item.productId),
                            buildImage: buildCartImage,
                          );
                        },
                      ),
              ),
              if (lines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromRGBO(158, 158, 158, 0.4),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    children: [
                      if (hasBlockingIssue)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Some items are unavailable or low on stock. Remove or adjust them to continue.',
                                    style: TextStyle(color: AppColors.error, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.muted),
                          SizedBox(width: 6),
                          Text('Estimated delivery: 2-4 days',
                              style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Subtotal', style: TextStyle(fontSize: 16)),
                        Text('Rs.${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                      ]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Discount', style: TextStyle(fontSize: 16)),
                        Text('- Rs.${PricingService.discount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16))
                      ]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Delivery Charge', style: TextStyle(fontSize: 16)),
                        Text('Rs.${PricingService.deliveryFee.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16))
                      ]),
                      const Divider(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Rs.${PricingService.totalFromValidated(lines).toStringAsFixed(2)}',
                            style:
                                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed:
                                  hasBlockingIssue ? null : () => _checkout(context, totalPrice),
                              child: const Text('Proceed to Checkout'))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

/// Renders a single cart line against the validation already computed by
/// `cartValidationProvider` (its live-product check) rather than each tile
/// re-querying the product itself.
class _CartLineTile extends StatelessWidget {
  final CartLineValidation line;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final Widget Function(String imagePath) buildImage;

  const _CartLineTile({
    required this.line,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.buildImage,
  });

  String? get _issue {
    if (!line.exists) return 'No longer available';
    if (!line.isActive) return 'No longer available';
    final stock = line.product?.stock ?? 0;
    if (stock == 0) return 'Out of stock';
    if (stock < line.item.qty) return 'Only $stock left';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final issue = _issue;
    final stock = line.product?.stock ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: issue != null ? Border.all(color: AppColors.error.withValues(alpha: 0.4)) : null,
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: buildImage(line.item.image)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Rs.${line.effectivePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                    if (line.priceChanged) ...[
                      const SizedBox(width: 6),
                      Text('(was Rs.${line.item.price.toStringAsFixed(0)})',
                          style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                if (issue != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(issue,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove, size: 16),
                      tooltip: 'Decrease quantity',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.card,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${line.item.qty}'),
                    ),
                    IconButton(
                      onPressed: (line.exists && line.item.qty >= stock) ? null : onIncrease,
                      icon: const Icon(Icons.add, size: 16),
                      tooltip: 'Increase quantity',
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.card,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primary),
              tooltip: 'Remove item',
              onPressed: onRemove),
        ],
      ),
    );
  }
}
