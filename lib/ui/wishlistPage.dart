import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:untitled3/ui/categories.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/Profilepage.dart';
import 'package:untitled3/ui/detail.dart';

/// Simple SharedPreferences-backed wishlist store shared by the home page,
/// product detail page, and this wishlist screen so the heart icon actually
/// persists across the app instead of just being decorative.
class WishlistService {
  static const _key = 'wishlist';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    return saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<bool> isSaved(Map<String, dynamic> item) async {
    final items = await getAll();
    return items.any((e) => e['name'] == item['name']);
  }

  /// Returns true if the item ends up saved, false if it was removed.
  static Future<bool> toggle(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    final index = items.indexWhere((e) => e['name'] == item['name']);
    if (index >= 0) {
      items.removeAt(index);
      await prefs.setStringList(_key, items.map((e) => jsonEncode(e)).toList());
      return false;
    } else {
      items.add(item);
      await prefs.setStringList(_key, items.map((e) => jsonEncode(e)).toList());
      return true;
    }
  }

  static Future<void> remove(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    items.removeWhere((e) => e['name'] == name);
    await prefs.setStringList(_key, items.map((e) => jsonEncode(e)).toList());
  }
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await WishlistService.getAll();
    setState(() {
      favorites = items;
      isLoading = false;
    });
  }

  Future<void> _remove(String name) async {
    await WishlistService.remove(name);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
  }

  Widget _buildImage(String imagePath) {
    Widget fallback() => Container(
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.temple_hindu, color: AppColors.primary),
        );
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    return fallback();
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CategoriesPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const cartPage()));
        break;
      case 4:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite, color: AppColors.accent),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 56, color: AppColors.muted),
                      SizedBox(height: 12),
                      Text('No favorites yet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap the heart icon on any item to save it here.',
                          style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Favorites',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text)),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          itemCount: favorites.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final item = favorites[index];
                            final price =
                                double.tryParse(item['price'].toString()) ?? 0.0;
                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailPage(list: item))),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color.fromRGBO(0, 0, 0, 0.06),
                                        blurRadius: 8,
                                        spreadRadius: 1),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: _buildImage(item['image'] ?? ''),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: IconButton(
                                                onPressed: () => _remove(item['name']),
                                                tooltip: 'Remove from wishlist',
                                                padding: EdgeInsets.zero,
                                                style: IconButton.styleFrom(
                                                    backgroundColor: AppColors.surface,
                                                    minimumSize: const Size(44, 44)),
                                                icon: const Icon(Icons.favorite,
                                                    size: 16, color: AppColors.accent),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(item['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Rs.${price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: _onNavTap,
      ),
    );
  }
}