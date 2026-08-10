import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/product.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cart_service.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/wishlistPage.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> list;

  const DetailPage({super.key, required this.list});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int quantity = 1;
  bool _expanded = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await WishlistService.isSaved(widget.list);
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _toggleWishlist() async {
    final saved = await WishlistService.toggle(widget.list);
    if (!mounted) return;
    setState(() => _saved = saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Added to wishlist' : 'Removed from wishlist')),
    );
  }

  void _shareProduct() {
    final name = widget.list['name'] ?? 'this item';
    final price = (widget.list['price'] ?? 0).toString();
    Clipboard.setData(
        ClipboardData(text: 'Check out $name on Pooja Pasal - Rs.$price'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product details copied to clipboard')),
    );
  }

  Widget buildItemImage(String imagePath) {
    Widget fallback() => Container(
          height: 260,
          width: double.infinity,
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.temple_hindu,
              size: 60, color: AppColors.primary),
        );

    if (imagePath.startsWith('http')) {
      return Image.network(imagePath,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    }
    return fallback();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final id = item['id'] as String?;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is a preview and is not available for purchase yet')),
      );
      return;
    }

    final product = Product(
      id: item['id'] ?? '',
      name: item['name'] ?? '',
      description: item['description'] ?? '',
      price: (item['price'] as num?)?.toDouble() ?? 0.0,
      category: item['category'] ?? '',
      images: List<String>.from(item['images'] ?? [item['image'] ?? '']),
      stock: (item['stock'] as num?)?.toInt() ?? 0,
      sellerId: item['sellerId'] ?? '',
      isActive: true,
    );

    try {
      await CartService.addToCart(uid, product, qty: quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $quantity ${item['name']} to cart')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add to cart: ${e.toString()}')),
      );
    }
  }

  Future<void> buyNow(Map<String, dynamic> item) async {
    await addToCart(item);
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const cartPage()));
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.list['price'] ?? 0).toDouble();
    final oldPrice = widget.list['oldPrice'];
    final description = widget.list['description'] ?? 'No description available';
    final shortDescription = description.length > 90 && !_expanded
        ? '${description.substring(0, 90)}...'
        : description;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
              icon: Icon(_saved ? Icons.favorite : Icons.favorite_border,
                  color: _saved ? AppColors.accent : null),
              tooltip: _saved ? 'Remove from wishlist' : 'Add to wishlist',
              onPressed: _toggleWishlist),
          IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share product',
              onPressed: _shareProduct),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.10),
                        blurRadius: 16,
                        spreadRadius: 1)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: buildItemImage(widget.list['image'] ??
                      'https://placehold.co/250x250/FFF3E0/7A1E1E/png?text=Pooja+Item'),
                ),
              ),
              const SizedBox(height: 18),
              Text(widget.list['name'] ?? 'Pooja Item',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              if ((widget.list['category'] as String?)?.isNotEmpty ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.list['category'],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Rs.${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  if (oldPrice != null) ...[
                    const SizedBox(width: 8),
                    Text('Rs.${(oldPrice as double).toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.muted,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                          '${(((oldPrice) - price) / oldPrice * 100).round()}% OFF',
                          style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  Text(
                      ((widget.list['stock'] as num?)?.toInt() ?? 0) > 0
                          ? 'In Stock'
                          : 'Out of Stock',
                      style: TextStyle(
                          color: ((widget.list['stock'] as num?)?.toInt() ?? 0) > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.remove_circle_outline,
                      color: AppColors.muted),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () => setState(
                              () => quantity = quantity > 1 ? quantity - 1 : 1),
                          icon: const Icon(Icons.remove, size: 18),
                          tooltip: 'Decrease quantity',
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$quantity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                          onPressed: () => setState(() => quantity += 1),
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: 'Increase quantity',
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Product Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text(shortDescription,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.muted, height: 1.5)),
              if (description.length > 90)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(_expanded ? 'Show less' : 'Read More',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => addToCart(widget.list),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => buyNow(widget.list),
                      child: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}