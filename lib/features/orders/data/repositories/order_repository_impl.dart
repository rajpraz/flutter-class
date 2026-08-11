import 'package:untitled3/features/cart/domain/entities/cart_item.dart';
import 'package:untitled3/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:untitled3/features/orders/domain/entities/order.dart';
import 'package:untitled3/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _dataSource;

  OrderRepositoryImpl(this._dataSource);

  @override
  Stream<List<PoojaOrder>> streamBuyerOrders(String buyerId) =>
      _dataSource.streamBuyerOrders(buyerId);

  @override
  Stream<List<PoojaOrder>> streamSellerOrders(String sellerId) =>
      _dataSource.streamSellerOrders(sellerId);

  @override
  Stream<PoojaOrder?> streamOrder(String orderId) => _dataSource.streamOrder(orderId);

  @override
  Stream<List<PoojaOrder>> streamAllOrders({int limit = 200}) =>
      _dataSource.streamAllOrders(limit: limit);

  @override
  Future<CreateOrderResult> createOrder({
    required List<CartItem> items,
    required String shippingAddress,
    required String paymentMethod,
    required String idempotencyKey,
  }) {
    return _dataSource.createOrder(
      items: items,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) {
    return _dataSource.updateOrderStatus(orderId: orderId, status: status, note: note);
  }

  @override
  Future<void> cancelOrder(String orderId, {String? note}) =>
      updateOrderStatus(orderId: orderId, status: 'cancelled', note: note);
}
