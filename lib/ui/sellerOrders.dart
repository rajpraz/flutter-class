import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/order.dart';
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/services/order_service.dart';

/// Embeddable body (no own Scaffold/AppBar) showing orders that contain at
/// least one of this seller's products, with the ability to advance status.
class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

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

  String? _nextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return null;
    }
  }

  Future<void> _advanceStatus(BuildContext context, PoojaOrder order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await OrderService.updateStatus(order.id, next, requestingUid: uid);
      try {
        await NotificationService.create(
          uid: order.buyerId,
          title: 'Order ${next[0].toUpperCase()}${next.substring(1)}',
          body: 'Your order #${order.id.substring(0, order.id.length.clamp(0, 8))} is now $next.',
          type: 'order_$next',
          orderId: order.id,
        );
      } catch (_) {
        // Best-effort: a failed notification write shouldn't block the status update.
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $next')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in'));
    }
    final ordersAsync = ref.watch(sellerOrdersProvider(uid));

    return ordersAsync.when(
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
                  Text('No orders yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Orders containing your products will show up here.',
                      textAlign: TextAlign.center),
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
            final myItems = order.items.where((item) => item.sellerId == uid).toList();
            final next = _nextStatus(order.status);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final item in myItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${item.name} × ${item.qty} — Rs.${(item.price * item.qty).toStringAsFixed(0)}'),
                      ),
                    const SizedBox(height: 6),
                    Text('Ship to: ${order.shippingAddress}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    if (next != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _advanceStatus(context, order),
                          child: Text('Mark as ${next[0].toUpperCase()}${next.substring(1)}'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
