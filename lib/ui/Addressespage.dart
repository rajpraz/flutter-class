import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/const/style.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('addresses') ?? [];
    setState(() {
      addresses = saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      isLoading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'addresses', addresses.map((e) => jsonEncode(e)).toList());
  }

  Future<void> _remove(int index) async {
    setState(() => addresses.removeAt(index));
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Address removed')));
  }

  void _addAddress() {
    final labelController = TextEditingController();
    final detailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add new address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. Home, Office)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Full address'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (labelController.text.trim().isEmpty ||
                      detailController.text.trim().isEmpty) return;
                  setState(() {
                    addresses.add({
                      'label': labelController.text.trim(),
                      'detail': detailController.text.trim(),
                    });
                  });
                  await _save();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save Address'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: _addAddress,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : addresses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined, size: 56, color: AppColors.muted),
                      SizedBox(height: 12),
                      Text('No saved addresses yet',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Tap + to add a delivery address.',
                          style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(address['label'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(address['detail'] ?? '',
                                    style: const TextStyle(color: AppColors.muted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.primary),
                            tooltip: 'Remove address',
                            onPressed: () => _remove(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}