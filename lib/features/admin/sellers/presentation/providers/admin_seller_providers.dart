import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/admin/sellers/data/datasources/admin_seller_remote_data_source.dart';
import 'package:untitled3/features/admin/sellers/data/repositories/admin_seller_repository_impl.dart';
import 'package:untitled3/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:untitled3/features/admin/sellers/domain/repositories/admin_seller_repository.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

final adminSellerRepositoryProvider = Provider<AdminSellerRepository>((ref) {
  return AdminSellerRepositoryImpl(AdminSellerRemoteDataSource());
});

final pendingSellerApplicationsProvider = StreamProvider<List<SellerApplication>>((ref) {
  return ref.watch(adminSellerRepositoryProvider).streamPendingApplications();
});

final allSellersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(adminSellerRepositoryProvider).streamSellers();
});

class AdminSellerController extends AsyncNotifier<void> {
  late final AdminSellerRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(adminSellerRepositoryProvider);
  }

  Future<void> approve(String applicantUid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.approveApplication(applicantUid));
  }

  Future<void> reject(String applicantUid, {String? reason}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.rejectApplication(applicantUid, reason: reason));
  }

  /// Demote/promote via the existing `setUserRole` Cloud Function. See
  /// [AdminSellerRepository.setUserRole] for why this is the only path.
  Future<void> setRole(String uid, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.setUserRole(uid, role));
  }
}

final adminSellerControllerProvider =
    AsyncNotifierProvider<AdminSellerController, void>(AdminSellerController.new);
