import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/features/products/presentation/providers/product_providers.dart';

class FestivalCollectionPage extends ConsumerWidget {
  final String festival;

  const FestivalCollectionPage({super.key, required this.festival});

  /// Single source of truth for festival→color, so the route (which only
  /// carries the festival name) and every card that links to it agree on
  /// the color without passing a `Color` through navigation.
  static const Map<String, Color> colors = {
    'Dashain': AppColors.accent,
    'Tihar': AppColors.primary,
    'Shivaratri': AppColors.festivalShivaratri,
    'Teej': AppColors.festivalTeej,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colors[festival] ?? AppColors.primary;
    final productsAsync = ref.watch(activeProductsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('$festival Collection')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$festival Special',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Handpicked essentials for the festival',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.temple_hindu, color: Colors.white24, size: 48),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) =>
                  Center(child: Text('Could not load products: $err')),
              data: (products) {
                final items =
                    products.where((p) => p.festivalTag == festival).toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.temple_hindu, size: 56, color: AppColors.muted),
                        SizedBox(height: 12),
                        Text('More items coming soon for this collection.',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return GestureDetector(
                      onTap: () => context.push(RouteNames.productDetailPath(product.id)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.06),
                                blurRadius: 8,
                                spreadRadius: 1),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: product.image.isEmpty
                                  ? Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.card,
                                      child: const Icon(Icons.temple_hindu,
                                          color: AppColors.primary))
                                  : Image.network(product.image,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 70,
                                          height: 70,
                                          color: AppColors.card,
                                          child: const Icon(Icons.temple_hindu,
                                              color: AppColors.primary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(product.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.muted)),
                                  const SizedBox(height: 4),
                                  Text('Rs.${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AllFestivalCollectionsPage extends StatelessWidget {
  const AllFestivalCollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final festivals = FestivalCollectionPage.colors.entries.toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Festival Collections')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: festivals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final fest = festivals[index];
            return GestureDetector(
              onTap: () => context.push(RouteNames.festivalCollectionPath(fest.key)),
              child: Container(
                decoration: BoxDecoration(
                  color: fest.value,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Icon(Icons.temple_hindu, color: Colors.white24, size: 50),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text('${fest.key} Collection',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
