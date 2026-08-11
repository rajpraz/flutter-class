import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';

/// Bridges a plain auth-state [Stream] into a [Listenable] GoRouter can use
/// as `refreshListenable`, so it re-evaluates [routeGuard] whenever
/// sign-in state changes — without recreating the `GoRouter` instance
/// itself (which would blow away the navigation stack).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const Set<String> _publicPaths = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.signup,
  RouteNames.forgotPassword,
};

/// This is a navigation-UX guard ONLY — it decides which screen to *show*,
/// nothing more. It is emphatically not the security boundary: whether a
/// request actually succeeds is enforced by Firestore rules (role-locked
/// `users/{uid}.role`, ownership checks) and the Cloud Functions
/// custom-claims/role checks already built (see firestore.rules,
/// functions/src/utils/auth.ts `requireRole`). A buyer who somehow reaches
/// a seller screen still can't do anything a seller could there — every
/// write still goes through the same trusted backend checks. This guard
/// just avoids showing them that screen in the first place.
///
/// Loop-prevention: every branch below either returns `null` (stay put) or
/// redirects to a path that itself evaluates to `null` on the next pass —
/// login/signup/onboarding only redirect *away* once actually signed in
/// (never redirect *to* themselves), and the seller check only fires for
/// `/seller/...` paths, which `RouteNames.home` never matches.
String? routeGuard(Ref ref, GoRouterState state) {
  final path = state.matchedLocation;

  // Splash owns the very first navigation decision — it already resolves
  // onboarding-seen + auth state + role asynchronously (see
  // splash_page.dart) before choosing where to go. Never redirect away
  // from it here, or splash and this guard could fight over the
  // destination before splash's own resolution finishes.
  if (path == RouteNames.splash) return null;

  final authState = ref.read(authStateProvider);
  if (!authState.hasValue) {
    // Still resolving the persisted session — don't redirect yet, or a
    // signed-in user would flash through /login for a frame.
    return null;
  }

  final user = authState.value;
  final isPublic = _publicPaths.contains(path);

  if (user == null) {
    return isPublic ? null : RouteNames.login;
  }

  // Signed in from here on — public/auth screens don't make sense anymore.
  if (path == RouteNames.login || path == RouteNames.signup || path == RouteNames.onboarding) {
    return RouteNames.home;
  }

  if (path.startsWith('/seller')) {
    final roleAsync = ref.read(currentUserDocProvider);
    if (!roleAsync.hasValue) return null; // wait for the role doc to resolve
    if (roleAsync.value?.role != 'seller') return RouteNames.home;
  }

  // Same pattern as the seller guard above: a UX guard only. The real
  // authorization boundary is firestore.rules' isAdmin() (checked against
  // request.auth.token.role, the custom claim — never the client-editable
  // users/{uid}.role Firestore field) and the Cloud Functions' own
  // requireRole(request, ["admin"]) checks, neither of which this touches.
  if (path.startsWith('/admin')) {
    final roleAsync = ref.read(currentUserDocProvider);
    if (!roleAsync.hasValue) return null; // wait for the role doc to resolve
    if (roleAsync.value?.role != 'admin') return RouteNames.home;
  }

  return null;
}
