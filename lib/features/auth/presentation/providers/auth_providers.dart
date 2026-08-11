import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:untitled3/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';
import 'package:untitled3/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteDataSource());
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).userDocStream(user.uid);
});

/// Any user's profile doc by uid — e.g. for an admin viewing someone
/// else's profile. `firestore.rules` allows this only for the caller's own
/// doc or an admin (`isAdmin()`); a non-admin caller using this for another
/// uid gets a permission-denied stream error, not silently empty data.
final userDocProvider = StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userDocStream(uid);
});
