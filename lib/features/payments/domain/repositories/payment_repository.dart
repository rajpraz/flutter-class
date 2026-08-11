import 'package:untitled3/features/payments/domain/entities/esewa_initiation.dart';

/// No payment is ever considered confirmed on the client — every method
/// here either calls the gateway's server-to-server verification
/// (Khalti/eSewa) or records a seller/admin-confirmed Cash on Delivery
/// collection; `paymentStatus` on the order document is only ever written
/// by the Cloud Functions behind this interface.
abstract class PaymentRepository {
  /// Verifies a Khalti payment by its `pidx` (exposed as `idx` on
  /// khalti_flutter's `PaymentSuccessModel`) against Khalti's server-side
  /// lookup API. Only after this succeeds is the order's paymentStatus
  /// "paid" — the SDK's `onSuccess` callback alone is never trusted.
  Future<void> verifyKhalti({required String orderId, required String pidx});

  /// Asks the backend to sign the eSewa checkout fields for this order
  /// (using the order's authoritative total, not a client-supplied
  /// amount), ready to build the redirect form.
  Future<EsewaInitiation> initiateEsewa(String orderId);

  /// Verifies an eSewa payment via eSewa's server-to-server status API
  /// after the buyer returns from the eSewa redirect.
  Future<void> verifyEsewa(String orderId);

  /// Seller/admin-only: marks a Cash on Delivery order's payment collected,
  /// only once it has actually been delivered.
  Future<void> confirmCodPayment(String orderId);
}
