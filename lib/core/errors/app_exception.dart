/// Friendly, typed failure surfaced to Riverpod controllers and, from
/// there, to the UI. Never let a raw `FirebaseFunctionsException` (which
/// can carry internal error text) or a bare network exception reach a
/// widget directly — everything is translated to a short user-facing
/// [message] by core/network/functions_client.dart, with the original
/// [code] kept for callers that need to branch on specific failures.
class AppFunctionException implements Exception {
  final String code;
  final String message;
  const AppFunctionException(this.code, this.message);

  bool get isAuthError => code == 'unauthenticated' || code == 'permission-denied';
  bool get isTimeout => code == 'deadline-exceeded' || code == 'unavailable';

  @override
  String toString() => message;
}

/// Same idea as [AppFunctionException] but for FirebaseAuth — translated
/// from `FirebaseAuthException` inside `AuthRemoteDataSource` so presentation
/// never needs to import `package:firebase_auth` just to catch its
/// exception type.
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}
