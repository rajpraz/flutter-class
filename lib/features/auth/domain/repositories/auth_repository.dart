import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Stream<AppUser?> userDocStream(String uid);

  Future<AppUser?> getUserDoc(String uid);

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signInWithGoogle({String role = 'buyer'});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  });

  Future<void> signOut();
}
