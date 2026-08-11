import 'package:untitled3/features/admin/dashboard/domain/entities/admin_dashboard_stats.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardStats> fetchStats();
}
