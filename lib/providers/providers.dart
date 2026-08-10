import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/models/app_notification.dart';
import 'package:untitled3/models/app_user.dart';
import 'package:untitled3/models/cart_item.dart';
import 'package:untitled3/models/order.dart';
import 'package:untitled3/models/product.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/services/cart_service.dart';
import 'package:untitled3/services/notification_service.dart';
import 'package:untitled3/services/order_service.dart';
import 'package:untitled3/services/product_service.dart';

final authStateProvider = StreamProvider<User?>((ref) => AuthService.authStateChanges());

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);
  return AuthService.userDocStream(user.uid);
});

final activeProductsProvider = StreamProvider<List<Product>>((ref) {
  return ProductService.streamActiveProducts();
});

final sellerProductsProvider = StreamProvider.family<List<Product>, String>((ref, sellerId) {
  return ProductService.streamSellerProducts(sellerId);
});

final cartProvider = StreamProvider.family<List<CartItem>, String>((ref, uid) {
  return CartService.streamCart(uid);
});

final buyerOrdersProvider = StreamProvider.family<List<PoojaOrder>, String>((ref, buyerId) {
  return OrderService.streamBuyerOrders(buyerId);
});

final sellerOrdersProvider = StreamProvider.family<List<PoojaOrder>, String>((ref, sellerId) {
  return OrderService.streamSellerOrders(sellerId);
});

final orderProvider = StreamProvider.family<PoojaOrder?, String>((ref, orderId) {
  return OrderService.streamOrder(orderId);
});

final notificationsProvider = StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  return NotificationService.streamNotifications(uid);
});
