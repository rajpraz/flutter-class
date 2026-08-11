import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled3/core/errors/app_exception.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

/// Talks directly to FirebaseAuth/GoogleSignIn/Firestore `users/{uid}`.
/// `FirebaseAuthException` is caught and translated to [AuthException]
/// here — the only place in the app that imports `package:firebase_auth`
/// for its exception type — so presentation never needs to know about it.
class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> userDocStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => doc.exists ? AppUser.fromMap(uid, doc.data()!) : null);
  }

  Future<AppUser?> getUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set(AppUser(
            uid: uid,
            name: name,
            email: email,
            phone: phone,
            role: role,
            address: address,
            createdAt: DateTime.now(),
          ).toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Could not create account.');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Login failed. Please try again.');
    }
  }

  /// Signs in with Google. If this is the user's first time, creates a
  /// `users/{uid}` doc with the given [role] (defaults to buyer).
  Future<void> signInWithGoogle({String role = 'buyer'}) async {
    try {
      await _googleSignIn.initialize();
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(user.uid).set(AppUser(
              uid: user.uid,
              name: user.displayName ?? '',
              email: user.email ?? '',
              phone: user.phoneNumber ?? '',
              role: role,
              address: '',
              createdAt: DateTime.now(),
            ).toMap());
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Google sign-in failed.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Could not send reset email.');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    await _db.collection('users').doc(uid).update(updates);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
