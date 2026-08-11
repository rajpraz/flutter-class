import 'package:cloud_functions/cloud_functions.dart';
import 'package:untitled3/core/errors/app_exception.dart';

/// Thin data-source wrapper around Firebase Callable Functions — the only
/// place in the app that talks to `cloud_functions` directly. Feature data
/// sources call through this; UI never does.
///
/// NOTE: these calls only succeed once the corresponding function in
/// functions/src has actually been deployed (`firebase deploy --only
/// functions`). Until then, every call here fails with `not-found`/
/// `internal`, which is surfaced through [AppFunctionException] like any
/// other failure rather than crashing the app.
class FunctionsClient {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final callable =
          _functions.httpsCallable(name, options: HttpsCallableOptions(timeout: timeout));
      final result = await callable.call<dynamic>(data);
      final raw = result.data;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw AppFunctionException(e.code, _friendlyMessage(e));
    } catch (_) {
      throw const AppFunctionException(
          'unavailable', 'Could not connect. Please check your internet connection and try again.');
    }
  }

  static String _friendlyMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in and try again.';
      case 'permission-denied':
        return e.message ?? "You don't have permission to do this.";
      case 'invalid-argument':
      case 'failed-precondition':
        return e.message ?? 'This request could not be completed.';
      case 'not-found':
        return e.message ?? 'Not found.';
      case 'deadline-exceeded':
      case 'unavailable':
        return 'The request timed out. Please check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
