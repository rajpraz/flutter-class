import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/product.dart';
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cart_service.dart';
import 'package:untitled3/ui/AllProductPage.dart';
import 'package:untitled3/ui/Addressespage.dart';
import 'package:untitled3/ui/HelpSupportPage.dart';
import 'package:untitled3/ui/NotificationPage.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/categories.dart';
import 'package:untitled3/ui/detail.dart';
import 'package:untitled3/ui/Profilepage.dart';
import 'package:untitled3/ui/orderHistoryPage.dart';
import 'package:untitled3/ui/wishlistPage.dart';
import 'package:untitled3/ui/festivalCollectionPage.dart';
import 'package:untitled3/login.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String _query = '';
  final int _navIndex = 0;

  final List<Map<String, dynamic>> quickCategories = const [
    {'name': 'Pooja Kits', 'icon': Icons.card_giftcard},
    {'name': 'Flowers', 'icon': Icons.local_florist},
    {'name': 'Incense', 'icon': Icons.spa},
    {'name': 'Idols', 'icon': Icons.temple_hindu},
    {'name': 'Diyas', 'icon': Icons.local_fire_department},
    {'name': 'Prasad', 'icon': Icons.food_bank},
    {'name': 'Brass Items', 'icon': Icons.emoji_objects_outlined},
    {'name': 'More', 'icon': Icons.grid_view_outlined},
  ];

  final List<Map<String, dynamic>> festivalCollections = const [
    {'name': 'Dashain', 'color': AppColors.accent},
    {'name': 'Tihar', 'color': AppColors.primary},
    {'name': 'Shivaratri', 'color': AppColors.festivalShivaratri},
    {'name': 'Teej', 'color': AppColors.festivalTeej},
  ];

  Widget buildProductImage(String imagePath,
      {double height = 80, double width = double.infinity}) {
    Widget fallback() => Container(
          height: height,
          width: width,
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.temple_hindu, color: AppColors.primary),
        );

    if (imagePath.startsWith('http')) {
      return Image.network(imagePath,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    }
    return fallback();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> addToCart(Product product) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await CartService.addToCart(uid, product);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to cart!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to cart: ${e.toString()}')));
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const cartPage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const WishlistPage()));
        break;
      case 4:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final user = AuthService.currentUser;
    Widget tile(IconData icon, String label, VoidCallback onTap) {
      return ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.accentLight,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.email ?? 'Welcome',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            tile(Icons.person_outline, 'Profile',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()))),
            tile(Icons.grid_view_outlined, 'Categories',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CategoriesPage()))),
            tile(Icons.favorite_border, 'Wishlist',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WishlistPage()))),
            tile(Icons.receipt_long_outlined, 'Order History',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryPage()))),
            tile(Icons.location_on_outlined, 'Addresses',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddressesPage()))),
            tile(Icons.help_outline, 'Help & Support',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpSupportPage()))),
            const Spacer(),
            const Divider(height: 1),
            tile(Icons.logout, 'Log out', () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false);
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    final productsAsync = ref.watch(activeProductsProvider);
    final cartAsync = uid == null ? null : ref.watch(cartProvider(uid));
    final cartCount = cartAsync?.value?.length ?? 0;
    final notificationsAsync =
        uid == null ? null : ref.watch(notificationsProvider(uid));
    final unreadCount =
        notificationsAsync?.value?.where((n) => !n.read).length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar: menu, title, bell
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu, color: AppColors.text),
                        tooltip: 'Menu',
                      ),
                    ),
                    const Spacer(),
                    const Text('Pooja Pasal',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsPage())),
                      icon: unreadCount > 0
                          ? Badge(
                              label: Text('$unreadCount'),
                              backgroundColor: AppColors.accent,
                              child: const Icon(Icons.notifications_none,
                                  color: AppColors.text),
                            )
                          : const Icon(Icons.notifications_none,
                              color: AppColors.text),
                      tooltip: 'Notifications',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Deliver to
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddressesPage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 4),
                        const Text('Deliver to',
                            style:
                                TextStyle(fontSize: 12, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        const Text('Kathmandu, Nepal',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => _query = value.toLowerCase()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: AppColors.muted),
                      hintText: 'Search for pooja items, brands...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Offer banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dashain\nSpecial Offer',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Up to 20% OFF',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text('Shop Now',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.temple_hindu,
                          size: 64, color: Colors.white24),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Categories grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categories',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CategoriesPage())),
                      child: const Text('View All',
                          style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quickCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final cat = quickCategories[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CategoriesPage())),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.card,
                            child: Icon(cat['icon'] as IconData,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(cat['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.muted)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),

                // Festival collections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Festival Collections',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AllFestivalCollectionsPage())),
                      child: const Text('View All',
                          style: TextStyle(fontSize: 12, color: AppColors.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: festivalCollections.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final fest = festivalCollections[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FestivalCollectionPage(
                                    festival: fest['name'] as String,
                                    color: fest['color'] as Color))),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: fest['color'] as Color,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.temple_hindu,
                                      color: Colors.white24, size: 36),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  '${fest['name']}\nCollection',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // Products
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('All Products',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    if (productsAsync.hasValue && productsAsync.value!.isNotEmpty)
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AllProductsPage(
                                    title: 'All Products',
                                    products: productsAsync.value!
                                        .map((p) => p.toDisplayMap())
                                        .toList()))),
                        child: const Text('View All',
                            style: TextStyle(fontSize: 12, color: AppColors.accent)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                productsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, st) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('Could not load products: $err',
                            style: const TextStyle(color: AppColors.muted))),
                  ),
                  data: (products) {
                    final filtered = _query.isEmpty
                        ? products
                        : products
                            .where((p) => p.name.toLowerCase().contains(_query))
                            .toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text(
                                products.isEmpty
                                    ? 'No products yet. Check back soon!'
                                    : 'No products match your search',
                                style: const TextStyle(color: AppColors.muted))),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ProductCard(
                          product: product,
                          onAddToCart: () => addToCart(product),
                          imageBuilder: buildProductImage,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        cartCount: cartCount,
        onTap: _onNavTap,
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final Widget Function(String imagePath, {double height, double width})
      imageBuilder;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.imageBuilder,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await WishlistService.isSaved(widget.product.toDisplayMap());
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _toggleWishlist() async {
    final saved = await WishlistService.toggle(widget.product.toDisplayMap());
    if (mounted) setState(() => _saved = saved);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailPage(list: product.toDisplayMap())),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 10,
                spreadRadius: 1)
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
                  child: widget.imageBuilder(product.image, height: 95, width: double.infinity),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: _toggleWishlist,
                      tooltip: _saved ? 'Remove from wishlist' : 'Add to wishlist',
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          minimumSize: const Size(44, 44)),
                      icon: Icon(
                        _saved ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: AppColors.accent,
                      ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text)),
            const SizedBox(height: 2),
            Text(product.stock > 0 ? 'In stock' : 'Out of stock',
                style: TextStyle(
                    fontSize: 11,
                    color: product.stock > 0 ? AppColors.success : AppColors.error)),
            const SizedBox(height: 4),
            Text('Rs.${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product.stock > 0 ? widget.onAddToCart : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8)),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
