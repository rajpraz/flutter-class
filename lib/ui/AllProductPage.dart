import 'dart:io';

import 'package:flutter/material.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/ui/detail.dart';

class AllProductsPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> products;

  const AllProductsPage({super.key, required this.products, this.title = 'All Products'});

  Widget _buildImage(String imagePath) {
    Widget fallback() => Container(
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.temple_hindu, color: AppColors.primary),
        );
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    return fallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.muted),
                  SizedBox(height: 12),
                  Text('No products to show yet.', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final item = products[index];
                  final price = double.tryParse(item['price'].toString()) ?? 0.0;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => DetailPage(list: item))),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.06),
                              blurRadius: 10,
                              spreadRadius: 1),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                  width: double.infinity, child: _buildImage(item['image'] ?? '')),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Rs.${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: AppColors.primary)),
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