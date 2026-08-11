import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/widgets/stat_card.dart';
import 'package:untitled3/features/admin/dashboard/presentation/providers/admin_dashboard_providers.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardStatsProvider),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Could not load dashboard: $err')),
            ],
          ),
          data: (stats) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  StatCard(
                      icon: Icons.people_outline,
                      label: 'Total Users',
                      value: '${stats.totalUsers}'),
                  StatCard(
                      icon: Icons.storefront_outlined,
                      label: 'Total Sellers',
                      value: '${stats.totalSellers}'),
                  StatCard(
                      icon: Icons.pending_actions_outlined,
                      label: 'Pending Applications',
                      value: '${stats.pendingSellerApplications}',
                      color: stats.pendingSellerApplications > 0 ? AppColors.accent : null),
                  StatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Total Products',
                      value: '${stats.totalProducts}'),
                  StatCard(
                      icon: Icons.visibility_outlined,
                      label: 'Active Products',
                      value: '${stats.activeProducts}'),
                  StatCard(
                      icon: Icons.warning_amber_outlined,
                      label: 'Low Stock',
                      value: '${stats.lowStockProducts}',
                      color: stats.lowStockProducts > 0 ? AppColors.error : null),
                  StatCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Total Orders',
                      value: '${stats.totalOrders}'),
                  StatCard(
                      icon: Icons.hourglass_empty,
                      label: 'Pending Orders',
                      value: '${stats.pendingOrders}'),
                  StatCard(
                      icon: Icons.local_shipping_outlined,
                      label: 'Shipped',
                      value: '${stats.shippedOrders}'),
                  StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Delivered',
                      value: '${stats.deliveredOrders}'),
                  StatCard(
                      icon: Icons.cancel_outlined,
                      label: 'Cancelled',
                      value: '${stats.cancelledOrders}'),
                  StatCard(
                      icon: Icons.payments_outlined,
                      label: 'Recent Revenue',
                      value: 'Rs.${stats.recentRevenue.toStringAsFixed(0)}'),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  '"Recent Revenue" sums the last 200 paid orders, not an all-time total.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                ),
              ),
              const Text('Manage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 10),
              _menuTile(
                context,
                icon: Icons.storefront_outlined,
                title: 'Sellers',
                subtitle: 'Review pending seller applications',
                badge: stats.pendingSellerApplications,
                onTap: () => context.push(RouteNames.adminSellers),
              ),
              _menuTile(
                context,
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Create, edit, activate or deactivate categories',
                onTap: () => context.push(RouteNames.adminCategories),
              ),
              _menuTile(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                subtitle: 'Moderate products, activate or deactivate',
                badge: stats.lowStockProducts,
                onTap: () => context.push(RouteNames.adminProducts),
              ),
              _menuTile(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                subtitle: 'View and manage every order',
                onTap: () => context.push(RouteNames.adminOrders),
              ),
              _menuTile(
                context,
                icon: Icons.people_outline,
                title: 'Users',
                subtitle: 'View accounts, grant admin access',
                onTap: () => context.push(RouteNames.adminUsers),
              ),
              _menuTile(
                context,
                icon: Icons.rate_review_outlined,
                title: 'Reviews',
                subtitle: 'Moderate buyer reviews',
                onTap: () => context.push(RouteNames.adminReviews),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration:
                    BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11)),
              )
            : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
