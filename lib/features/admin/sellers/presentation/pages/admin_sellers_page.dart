import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/core/utils/error_mapper.dart';
import 'package:untitled3/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:untitled3/features/admin/sellers/presentation/providers/admin_seller_providers.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';
import 'package:untitled3/shared/widgets/empty_view.dart';
import 'package:untitled3/shared/widgets/loading_view.dart';

/// Two tabs: pending seller-application review (approve/reject via the
/// existing `approveSellerApplication`/`rejectSellerApplication` Cloud
/// Functions) and the full seller directory (tap through to
/// `AdminSellerDetailPage` for demote/restore).
class AdminSellersPage extends StatelessWidget {
  const AdminSellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Sellers'),
          bottom: const TabBar(tabs: [Tab(text: 'Applications'), Tab(text: 'All Sellers')]),
        ),
        body: const TabBarView(
          children: [_PendingApplicationsTab(), _AllSellersTab()],
        ),
      ),
    );
  }
}

class _AllSellersTab extends ConsumerWidget {
  const _AllSellersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellersAsync = ref.watch(allSellersProvider);
    return sellersAsync.when(
      loading: () => const LoadingView(),
      error: (err, st) => Center(child: Text('Could not load sellers: $err')),
      data: (sellers) {
        if (sellers.isEmpty) {
          return const EmptyView(
            icon: Icons.storefront_outlined,
            title: 'No sellers yet',
            subtitle: 'Approved sellers will show up here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final AppUser seller = sellers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                title: Text(seller.name.isEmpty ? seller.email : seller.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(seller.email, style: const TextStyle(color: AppColors.muted)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
                onTap: () => context.push(RouteNames.adminSellerDetailPath(seller.uid)),
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingApplicationsTab extends ConsumerWidget {
  const _PendingApplicationsTab();

  Future<void> _approve(BuildContext context, WidgetRef ref, SellerApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve seller?'),
        content: Text('"${app.shopName}" will be granted seller access immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminSellerControllerProvider.notifier).approve(app.uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${app.shopName} approved as seller.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, SellerApplication app) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject application?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${app.shopName}" will not be granted seller access.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(adminSellerControllerProvider.notifier)
          .reject(app.uid, reason: reasonController.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${app.shopName} rejected.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(pendingSellerApplicationsProvider);
    final isBusy = ref.watch(adminSellerControllerProvider).isLoading;

    return applicationsAsync.when(
      loading: () => const LoadingView(),
      error: (err, st) => Center(child: Text('Could not load applications: $err')),
      data: (applications) {
        if (applications.isEmpty) {
          return const EmptyView(
            icon: Icons.storefront_outlined,
            title: 'No pending applications',
            subtitle: 'New seller upgrade requests will show up here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final app = applications[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Phone: ${app.phone}', style: const TextStyle(color: AppColors.muted)),
                    if (app.reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(app.reason, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isBusy ? null : () => _reject(context, ref, app),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isBusy ? null : () => _approve(context, ref, app),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
