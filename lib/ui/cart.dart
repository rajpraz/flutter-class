import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cart_service.dart';
import 'checkoutPage.dart';
import 'homepage.dart';
import 'categories.dart';
import 'wishlistPage.dart';
import 'Profilepage.dart';

class cartPage extends ConsumerWidget {
  const cartPage({super.key});

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

  Future<void> _updateQty(BuildContext context, String uid, CartItem item, int delta) async {
    try {
      await CartService.updateQty(uid, item.productId, item.qty + delta);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update cart: ${e.toString()}')));
    }
  }

  Future<void> _removeItem(BuildContext context, String uid, String productId) async {
    try {
      await CartService.removeItem(uid, productId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item removed from cart')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not remove item: ${e.toString()}')));
    }
  }

  void _confirmClearCart(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('This will remove all items from your cart.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await CartService.clearCart(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cart cleared')));
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CheckoutPage(price: totalPrice)));
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your cart')));
    }

    final cartAsync = ref.watch(cartProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartAsync.hasValue && cartAsync.value!.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear cart',
                onPressed: () => _confirmClearCart(context, uid))
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load cart: $err')),
        data: (cartItems) {
          final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);

          return Column(
            children: [
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 60, color: AppColors.accent),
                            const SizedBox(height: 10),
                            const Text('Your cart is empty',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Add puja essentials to start your order.',
                                style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => const HomePage())),
                              child: const Text('Browse Products'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color.fromRGBO(0, 0, 0, 0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: buildCartImage(item.image)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Rs.${item.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _updateQty(context, uid, item, -1),
                                            icon: const Icon(Icons.remove, size: 16),
                                            tooltip: 'Decrease quantity',
                                            style: IconButton.styleFrom(
                                                backgroundColor: AppColors.card,
                                                minimumSize: const Size(44, 44),
                                                padding: EdgeInsets.zero),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text('${item.qty}'),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _updateQty(context, uid, item, 1),
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
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.primary),
                                    tooltip: 'Remove item',
                                    onPressed: () =>
                                        _removeItem(context, uid, item.productId)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (cartItems.isNotEmpty)
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
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 16)),
                            Text('Rs.${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600))
                          ]),
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Charge', style: TextStyle(fontSize: 16)),
                            const Text('Rs.80', style: TextStyle(fontSize: 16))
                          ]),
                      const Divider(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Rs.${(totalPrice + 80).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold))
                          ]),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () => _checkout(context, totalPrice),
                              child: const Text('Proceed to Checkout'))),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomePage()));
              break;
            case 1:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CategoriesPage()));
              break;
            case 3:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const WishlistPage()));
              break;
            case 4:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()));
              break;
          }
        },
      ),
    );
  }
}
