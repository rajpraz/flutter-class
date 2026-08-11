import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/features/orders/domain/entities/order.dart';
import 'package:untitled3/features/payments/presentation/providers/payment_providers.dart';

/// True when a buyer abandoned/lost an online-payment attempt (backed out
/// of the Khalti screen, closed the app mid-eSewa-redirect, network drop
/// before `onSuccess` fired, etc.) and the order was left `paymentStatus:
/// pending` with no way to finish paying for it. COD orders are
/// intentionally excluded — "pending" is their normal, expected state
/// until delivery, not a stuck payment.
bool isStuckOnlinePayment(PoojaOrder order) {
  return (order.paymentMethod == 'khalti' || order.paymentMethod == 'esewa') &&
      order.paymentStatus == 'pending' &&
      order.status != 'cancelled';
}

/// Relaunches payment for an already-created order — never creates a new
/// order (that would defeat the idempotency key checkout already used).
/// Khalti: reopens the SDK screen with the order's existing total, then
/// verifies exactly like checkout does. eSewa: pushes the same WebView
/// payment page checkout uses, keyed to the existing orderId.
class RetryPaymentButton extends ConsumerStatefulWidget {
  final PoojaOrder order;
  const RetryPaymentButton({super.key, required this.order});

  @override
  ConsumerState<RetryPaymentButton> createState() => _RetryPaymentButtonState();
}

class _RetryPaymentButtonState extends ConsumerState<RetryPaymentButton> {
  bool _busy = false;

  Future<void> _retryKhalti() async {
    setState(() => _busy = true);
    KhaltiScope.of(context).pay(
      config: PaymentConfig(
        amount: (widget.order.totalAmount * 100).round(),
        productIdentity: widget.order.id,
        productName: 'Pooja Pasal Order',
      ),
      preferences: const [
        PaymentPreference.khalti,
        PaymentPreference.connectIPS,
        PaymentPreference.eBanking,
      ],
      onSuccess: (success) async {
        try {
          await ref
              .read(paymentControllerProvider.notifier)
              .verifyKhalti(orderId: widget.order.id, pidx: success.idx);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Payment confirmed!')));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      onFailure: (failure) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment failed: ${failure.message}')));
      },
      onCancel: () {
        if (mounted) setState(() => _busy = false);
      },
    );
  }

  Future<void> _retryEsewa() async {
    setState(() => _busy = true);
    final paid = await context.push<bool>(RouteNames.esewaPaymentPath(widget.order.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (paid == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment confirmed!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _busy
            ? null
            : (widget.order.paymentMethod == 'khalti' ? _retryKhalti : _retryEsewa),
        icon: _busy
            ? const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.payment),
        label: Text(_busy ? 'Confirming...' : 'Complete Payment'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
      ),
    );
  }
}
