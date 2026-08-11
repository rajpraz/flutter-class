import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/admin/dashboard/data/datasources/admin_dashboard_data_source.dart';
import 'package:untitled3/features/admin/dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:untitled3/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';
import 'package:untitled3/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepositoryImpl(AdminDashboardDataSource());
});

/// A one-shot fetch, not a live stream — dashboard stats are aggregation
/// queries (see AdminDashboardDataSource), which are cheap enough to
/// re-fetch on pull-to-refresh but don't need a permanently open listener.
final adminDashboardStatsProvider = FutureProvider.autoDispose<AdminDashboardStats>((ref) {
  return ref.watch(adminDashboardRepositoryProvider).fetchStats();
});
