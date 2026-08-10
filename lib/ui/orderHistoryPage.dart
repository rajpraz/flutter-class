import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/ui/trackOrder.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.khaltiPurple;
      case 'shipped':
        return AppColors.fonepayBlue;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your orders')));
    }
    final ordersAsync = ref.watch(buyerOrdersProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load orders: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 70, color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Orders you place will show up here.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text('Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        '${order.items.length} item(s) • Rs.${order.totalAmount.toStringAsFixed(2)}'),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(order.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.status.toUpperCase(),
                        style: TextStyle(
                            color: _statusColor(order.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => TrackOrderPage(orderId: order.id))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
