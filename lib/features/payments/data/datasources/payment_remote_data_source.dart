import 'package:untitled3/core/network/functions_client.dart';
import 'package:untitled3/features/payments/domain/entities/esewa_initiation.dart';

/// Talks to the trusted payment Cloud Functions
/// (functions/src/payments/*.ts) via [FunctionsClient] — the only data
/// source in this feature, and the only place that knows the callable
/// function names.
class PaymentRemoteDataSource {
  Future<void> verifyKhalti({required String orderId, required String pidx}) async {
    await FunctionsClient.call('verifyKhaltiPayment', {'orderId': orderId, 'pidx': pidx});
  }

  Future<EsewaInitiation> initiateEsewa(String orderId) async {
    final data = await FunctionsClient.call('initiateEsewaPayment', {'orderId': orderId});
    return EsewaInitiation.fromMap(data);
  }

  Future<void> verifyEsewa(String orderId) async {
    await FunctionsClient.call('verifyEsewaPayment', {'orderId': orderId});
  }

  Future<void> confirmCodPayment(String orderId) async {
    await FunctionsClient.call('confirmCodPayment', {'orderId': orderId});
  }
}
