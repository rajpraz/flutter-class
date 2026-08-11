import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';
import 'package:untitled3/features/cart/presentation/providers/cart_providers.dart';
import 'package:untitled3/features/products/domain/entities/product.dart';
import 'package:untitled3/features/wishlist/presentation/providers/wishlist_providers.dart';

Widget buildProductImage(String imagePath, {double height = 95, double width = double.infinity}) {
  Widget fallback() => Container(
        height: height,
        width: width,
        color: AppColors.card,
        alignment: Alignment.center,
        child: const Icon(Icons.temple_hindu, color: AppColors.primary),
      );
  if (imagePath.isEmpty) return fallback();
  return Image.network(imagePath,
      height: height, width: width, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
}

/// Shared product grid tile — used by Home's featured section, the full
/// product browse, search results, and category listings, so the card
/// (image, wishlist toggle, rating, price, add-to-cart) only exists once.
class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(cartControllerProvider.notifier).addToCart(uid, product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to cart!')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add to cart: ${friendlyErrorMessage(e)}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final saved = uid == null
        ? false
        : ref.watch(wishlistProvider(uid)
            .select((state) => state.value?.any((e) => e.productId == product.id) ?? false));

    return GestureDetector(
      onTap: () => context.push(RouteNames.productDetailPath(product.id)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 10, spreadRadius: 1)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildProductImage(product.image, height: 95, width: double.infinity),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () {
                        if (uid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please sign in to save items.')));
                          return;
                        }
                        ref.read(wishlistControllerProvider.notifier).toggle(uid, product.id);
                      },
                      tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface, minimumSize: const Size(44, 44)),
                      icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                          size: 16, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 2),
            if (product.ratingCount > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.accent),
                  const SizedBox(width: 2),
                  Text('${product.ratingAverage.toStringAsFixed(1)} (${product.ratingCount})',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              )
            else
              Text(product.stock > 0 ? 'In stock' : 'Out of stock',
                  style: TextStyle(
                      fontSize: 11,
                      color: product.stock > 0 ? AppColors.success : AppColors.error)),
            const SizedBox(height: 4),
            Text('Rs.${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product.stock > 0 ? () => _addToCart(context, ref) : null,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
