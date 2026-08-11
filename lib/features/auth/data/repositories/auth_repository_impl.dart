import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';
import 'package:untitled3/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<User?> authStateChanges() => _dataSource.authStateChanges();

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Stream<AppUser?> userDocStream(String uid) => _dataSource.userDocStream(uid);

  @override
  Future<AppUser?> getUserDoc(String uid) => _dataSource.getUserDoc(uid);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
  }) {
    return _dataSource.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      address: address,
      role: role,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _dataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle({String role = 'buyer'}) {
    return _dataSource.signInWithGoogle(role: role);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _dataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) {
    return _dataSource.updateUserProfile(
      uid: uid,
      name: name,
      phone: phone,
      address: address,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
