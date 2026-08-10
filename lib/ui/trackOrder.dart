import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/models/order.dart';
import 'package:untitled3/providers/providers.dart';

class TrackOrderStep {
  final String title;
  final bool done;
  final bool isCurrent;

  const TrackOrderStep({required this.title, this.done = false, this.isCurrent = false});
}

List<TrackOrderStep> _stepsForStatus(String status) {
  const order = ['pending', 'confirmed', 'shipped', 'delivered'];
  const titles = {
    'pending': 'Order Placed',
    'confirmed': 'Order Confirmed',
    'shipped': 'Order Shipped',
    'delivered': 'Delivered',
  };

  if (status == 'cancelled') {
    return const [
      TrackOrderStep(title: 'Order Placed', done: true),
      TrackOrderStep(title: 'Cancelled', done: true, isCurrent: true),
    ];
  }

  final currentIndex = order.indexOf(status).clamp(0, order.length - 1);
  return [
    for (int i = 0; i < order.length; i++)
      TrackOrderStep(
        title: titles[order[i]]!,
        done: i <= currentIndex,
        isCurrent: i == currentIndex,
      ),
  ];
}

class TrackOrderPage extends ConsumerWidget {
  final String orderId;

  const TrackOrderPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Tracking')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Could not load order: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderTrackBody(order: order);
        },
      ),
    );
  }
}

class _OrderTrackBody extends StatelessWidget {
  final PoojaOrder order;
  const _OrderTrackBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForStatus(order.status);
    final placedOn = order.createdAt == null
        ? ''
        : 'Placed on ${order.createdAt!.toString().substring(0, 16)}';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Text('Order ID: #${order.id.substring(0, order.id.length.clamp(0, 8))}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(placedOn, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Rs.${order.totalAmount.toStringAsFixed(2)} • ${order.items.length} item(s)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Shipping to: ${order.shippingAddress}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 26),
          for (int i = 0; i < steps.length; i++)
            _buildStep(steps[i], i == steps.length - 1),
          const SizedBox(height: 20),
          const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item.name} × ${item.qty}')),
                  Text('Rs.${(item.price * item.qty).toStringAsFixed(2)}'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(TrackOrderStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? (step.title == 'Cancelled' ? AppColors.error : AppColors.success)
                      : AppColors.border,
                ),
                child: step.done
                    ? Icon(step.title == 'Cancelled' ? Icons.close : Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: step.done ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 26.0),
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: step.done ? AppColors.text : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
