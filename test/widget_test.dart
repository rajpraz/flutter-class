import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/app/app.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';
import 'package:untitled3/features/auth/domain/repositories/auth_repository.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';

/// Stands in for the real Firebase-backed [AuthRepository] so this test
/// never touches actual Firebase (which isn't initialized in the test
/// environment — `FirebaseAuth.instance` throws `[core/no-app]` if a real
/// AuthRepository is constructed here). This is exactly what wrapping
/// Firebase behind a repository interface in the architecture refactor was
/// for: the app's root widget can be pumped in a test using a fake
/// implementation instead of a live backend.
class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Stream<AppUser?> userDocStream(String uid) => Stream.value(null);

  @override
  Future<AppUser?> getUserDoc(String uid) async => null;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String role,
  }) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signInWithGoogle({String role = 'buyer'}) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
  }) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('shows the pooja store branding on launch',
      (WidgetTester tester) async {
    // SplashPage reads SharedPreferences (for "seen_onboarding") as part of
    // resolving where to navigate after the splash delay.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(_FakeAuthRepository())],
      child: const App(),
    ));

    expect(find.text('Pooja Pasal'), findsOneWidget);

    // Let SplashPage's 2-second minimum splash timer (and the navigation
    // it triggers) run to completion so no timer is left pending when the
    // test tears down.
    await tester.pump(const Duration(seconds: 3));
  });
}
