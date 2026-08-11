import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:untitled3/features/orders/data/repositories/order_repository_impl.dart';
import 'package:untitled3/features/orders/domain/entities/order.dart';
import 'package:untitled3/features/orders/domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(OrderRemoteDataSource());
});

final buyerOrdersProvider = StreamProvider.family<List<PoojaOrder>, String>((ref, buyerId) {
  return ref.watch(orderRepositoryProvider).streamBuyerOrders(buyerId);
});

final sellerOrdersProvider = StreamProvider.family<List<PoojaOrder>, String>((ref, sellerId) {
  return ref.watch(orderRepositoryProvider).streamSellerOrders(sellerId);
});

/// autoDispose: unlike buyer/seller order *lists* (one stable key per
/// session — the user's own uid), this is keyed per order *viewed*. Over a
/// session a buyer may open many different orders from history/
/// notifications; without autoDispose each one would leave its Firestore
/// listener open for the rest of the app's lifetime instead of closing
/// when the track-order page is no longer watched.
final orderProvider = StreamProvider.autoDispose.family<PoojaOrder?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).streamOrder(orderId);
});

/// Admin-only: all orders (bounded), for the admin order-oversight list.
final adminAllOrdersProvider = StreamProvider<List<PoojaOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).streamAllOrders();
});

/// Riverpod-first order actions: UI calls this controller, which delegates
/// to [OrderRepository] (the Cloud Functions data source) — no Firestore
/// writes and no order-total/stock logic live here or in any widget.
/// [state] tracks the loading/error status of the in-flight action so the
/// UI can disable buttons and show errors via [AsyncValue.when]; the
/// actual result of a call is also returned directly from the method so
/// callers that need the value (e.g. checkout needing the new orderId)
/// don't have to thread it through provider state.
class OrderController extends AsyncNotifier<void> {
  late final OrderRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(orderRepositoryProvider);
  }

  Future<CreateOrderResult> placeOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.createOrder(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        idempotencyKey: idempotencyKey,
      );
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateOrderStatus(orderId: orderId, status: status, note: note);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, {String? note}) =>
      updateStatus(orderId: orderId, status: 'cancelled', note: note);
}

final orderControllerProvider = AsyncNotifierProvider<OrderController, void>(OrderController.new);
