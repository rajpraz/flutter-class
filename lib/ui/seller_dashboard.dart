import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/product.dart';
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/product_service.dart';
import 'package:untitled3/login.dart' as login_page;
import 'package:untitled3/ui/createProduct.dart' show AddProductPage;
import 'package:untitled3/ui/sellerOrders.dart';

class SellerDashboard extends ConsumerStatefulWidget {
  const SellerDashboard({super.key});

  @override
  ConsumerState<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends ConsumerState<SellerDashboard> {
  int _tab = 0;

  Widget buildImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: AppColors.card,
        alignment: Alignment.center,
        child:
            const Icon(Icons.temple_hindu, color: AppColors.primary, size: 36),
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.orange.shade100,
        alignment: Alignment.center,
        child: const Icon(Icons.temple_hindu, color: Colors.deepOrange, size: 36),
      ),
    );
  }

  Future<void> deleteProduct(Product product) async {
    try {
      await ProductService.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove product: ${e.toString()}')),
      );
    }
  }

  Future<void> logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const login_page.LoginPage(role: 'seller')),
      (route) => false,
    );
  }

  Widget _statCard(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final productsAsync = ref.watch(sellerProductsProvider(uid));

    final ordersAsync = ref.watch(sellerOrdersProvider(uid));
    final pendingOrders =
        ordersAsync.value?.where((o) => o.status == 'pending').length ?? 0;
    final totalProducts = productsAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Sell Pooja Items' : 'Incoming Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddProductPage())),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'My Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        ],
      ),
      body: _tab == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                            icon: Icons.storefront_outlined,
                            label: 'Total Products',
                            value: '$totalProducts'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                            icon: Icons.pending_actions_outlined,
                            label: 'Pending Orders',
                            value: '$pendingOrders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: productsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Center(child: Text('Could not load products: $err')),
                      data: (products) {
                        if (products.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 70, color: AppColors.primary),
                              const SizedBox(height: 16),
                              const Text('No products yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                'Add your own pooja items and let buyers discover them.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const AddProductPage())),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Add your first item'),
                              )
                            ],
                          );
                        }
                        return ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: buildImage(product.image),
                                  ),
                                ),
                                title: Text(product.name),
                                subtitle: Text(
                                    'Rs.${product.price.toStringAsFixed(0)} • Stock: ${product.stock} • ${product.category}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                      tooltip: 'Edit product',
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => AddProductPage(existing: product))),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.error),
                                      tooltip: 'Delete product',
                                      onPressed: () => deleteProduct(product),
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
            )
          : const SellerOrdersPage(),
    );
  }
}
