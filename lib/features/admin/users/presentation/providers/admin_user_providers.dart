import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/admin/users/data/datasources/admin_user_remote_data_source.dart';
import 'package:untitled3/features/admin/users/data/repositories/admin_user_repository_impl.dart';
import 'package:untitled3/features/admin/users/domain/repositories/admin_user_repository.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepositoryImpl(AdminUserRemoteDataSource());
});

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(adminUserRepositoryProvider).streamUsers();
});
