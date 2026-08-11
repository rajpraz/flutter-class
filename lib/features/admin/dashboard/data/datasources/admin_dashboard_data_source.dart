import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';

/// Every number here comes from a server-side Firestore aggregation query
/// (`.count().get()` / `.aggregate(sum(...)).get()`), never a full
/// collection download — each is billed as a single aggregation read
/// regardless of collection size, and each is authorized by the exact same
/// security rule as an equivalent list/get query on that collection (the
/// admin custom-claim role already has read access to every collection
/// queried here — see firestore.rules `isAdmin()`).
class AdminDashboardDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AdminDashboardStats> fetchStats() async {
    final users = _db.collection('users');
    final products = _db.collection('products');
    final orders = _db.collection('orders');
    final sellerApplications = _db.collection('sellerApplications');

    final counts = await Future.wait<AggregateQuerySnapshot>([
      users.count().get(), // 0: total users
      users.where('role', isEqualTo: 'seller').count().get(), // 1: total sellers
      sellerApplications.where('status', isEqualTo: 'pending').count().get(), // 2: pending applications
      products.count().get(), // 3: total products
      products.where('isActive', isEqualTo: true).count().get(), // 4: active products
      // Low-stock uses a fixed threshold (matching the default in
      // functions/src/notifications/lowStock.ts) since Firestore can't
      // compare two fields of the same document (stock vs. each product's
      // own lowStockThreshold) in a single query — this is an
      // approximation, not an exact per-product-threshold count. Needs the
      // composite index added to firestore.indexes.json
      // (products: isActive ASC, stock ASC).
      products
          .where('isActive', isEqualTo: true)
          .where('stock', isLessThanOrEqualTo: 5)
          .count()
          .get(), // 5: low stock
      orders.count().get(), // 6: total orders
      orders.where('status', isEqualTo: 'pending').count().get(), // 7
      orders.where('status', isEqualTo: 'confirmed').count().get(), // 8
      orders.where('status', isEqualTo: 'processing').count().get(), // 9
      orders.where('status', isEqualTo: 'shipped').count().get(), // 10
      orders.where('status', isEqualTo: 'delivered').count().get(), // 11
      orders.where('status', isEqualTo: 'cancelled').count().get(), // 12
    ]);

    final revenueSnap = await orders
        .where('paymentStatus', isEqualTo: 'paid')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .aggregate(sum('totalAmount'))
        .get();

    return AdminDashboardStats(
      totalUsers: counts[0].count ?? 0,
      totalSellers: counts[1].count ?? 0,
      pendingSellerApplications: counts[2].count ?? 0,
      totalProducts: counts[3].count ?? 0,
      activeProducts: counts[4].count ?? 0,
      lowStockProducts: counts[5].count ?? 0,
      totalOrders: counts[6].count ?? 0,
      pendingOrders: counts[7].count ?? 0,
      confirmedOrders: counts[8].count ?? 0,
      processingOrders: counts[9].count ?? 0,
      shippedOrders: counts[10].count ?? 0,
      deliveredOrders: counts[11].count ?? 0,
      cancelledOrders: counts[12].count ?? 0,
      recentRevenue: revenueSnap.getSum('totalAmount') ?? 0,
    );
  }
}
