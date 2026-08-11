import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:untitled3/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:untitled3/features/payments/domain/entities/esewa_initiation.dart';
import 'package:untitled3/features/payments/domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(PaymentRemoteDataSource());
});

/// Riverpod-first payment actions. Every method here maps to a Cloud
/// Function that independently verifies payment with the gateway (or, for
/// COD, records a trusted seller/admin confirmation) — nothing here ever
/// marks an order paid client-side.
class PaymentController extends AsyncNotifier<void> {
  late final PaymentRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(paymentRepositoryProvider);
  }

  Future<void> verifyKhalti({required String orderId, required String pidx}) async {
    state = const AsyncLoading();
    try {
      await _repository.verifyKhalti(orderId: orderId, pidx: pidx);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<EsewaInitiation> initiateEsewa(String orderId) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.initiateEsewa(orderId);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> verifyEsewa(String orderId) async {
    state = const AsyncLoading();
    try {
      await _repository.verifyEsewa(orderId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> confirmCodPayment(String orderId) async {
    state = const AsyncLoading();
    try {
      await _repository.confirmCodPayment(orderId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, void>(PaymentController.new);
