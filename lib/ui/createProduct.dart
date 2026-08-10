import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/product.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cloudinary_service.dart';
import 'package:untitled3/services/product_service.dart';

class AddProductPage extends StatefulWidget {
  /// When non-null, the page edits this existing product instead of
  /// creating a new one.
  final Product? existing;

  const AddProductPage({super.key, this.existing});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Pooja Kits';
  String _festivalTag = '';
  bool _isSaving = false;

  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  static const List<String> _categories = [
    'Pooja Kits',
    'Flowers',
    'Incense',
    'Brass Items',
    'Idols',
    'Prasad',
    'Diyas',
  ];

  static const List<String> _festivals = [
    'Dashain',
    'Tihar',
    'Shivaratri',
    'Teej',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _priceController.text = existing.price.toString();
      _stockController.text = existing.stock.toString();
      _descriptionController.text = existing.description;
      _category = existing.category;
      _festivalTag = existing.festivalTag;
      _existingImageUrls = List.of(existing.images);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked.map((x) => File(x.path)));
    });
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final stock = _stockController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || price.isEmpty || stock.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill in name, price and stock');
      return;
    }
    final parsedPrice = double.tryParse(price);
    if (parsedPrice == null) {
      Fluttertoast.showToast(msg: 'Price must be a number');
      return;
    }
    final parsedStock = int.tryParse(stock);
    if (parsedStock == null) {
      Fluttertoast.showToast(msg: 'Stock must be a whole number');
      return;
    }
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      Fluttertoast.showToast(msg: 'Please add at least one product image');
      return;
    }

    final sellerId = AuthService.currentUser?.uid;
    if (sellerId == null) {
      Fluttertoast.showToast(msg: 'You must be signed in as a seller');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uploadedUrls = await CloudinaryService.uploadImages(_newImages);
      final images = [..._existingImageUrls, ...uploadedUrls];

      if (_isEditing) {
        await ProductService.updateProduct(widget.existing!.id, {
          'name': name,
          'price': parsedPrice,
          'stock': parsedStock,
          'description': description.isEmpty ? 'No description provided.' : description,
          'category': _category,
          'festivalTag': _festivalTag,
          'images': images,
        });
      } else {
        await ProductService.addProduct(Product(
          id: '',
          name: name,
          description: description.isEmpty ? 'No description provided.' : description,
          price: parsedPrice,
          category: _category,
          festivalTag: _festivalTag,
          images: images,
          stock: parsedStock,
          sellerId: sellerId,
          isActive: true,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not save product: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  const Text('Product Images', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (int i = 0; i < _existingImageUrls.length; i++)
                        _imageTile(
                          child: Image.network(_existingImageUrls[i], fit: BoxFit.cover),
                          onRemove: () => _removeExistingImage(i),
                        ),
                      for (int i = 0; i < _newImages.length; i++)
                        _imageTile(
                          child: Image.file(_newImages[i], fit: BoxFit.cover),
                          onRemove: () => _removeNewImage(i),
                        ),
                      Semantics(
                        button: true,
                        label: 'Add product image',
                        child: InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Product Name', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Brass Diya Set'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price (Rs.)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(hintText: 'e.g. 850'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Qty', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 20'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 16),
                  const Text('Festival Tag (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Feature this product on a festival collection page',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _festivalTag.isEmpty ? null : _festivalTag,
                          hint: const Text('None'),
                          items: _festivals
                              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (value) => setState(() => _festivalTag = value ?? ''),
                          isExpanded: true,
                        ),
                      ),
                      if (_festivalTag.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() => _festivalTag = ''),
                          tooltip: 'Clear festival tag',
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Tell buyers about this product'),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(_isEditing ? 'Save Changes' : 'Save Product'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _imageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 84, height: 84, child: child),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: onRemove,
              tooltip: 'Remove image',
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                  backgroundColor: Colors.black54, minimumSize: const Size(32, 32)),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
