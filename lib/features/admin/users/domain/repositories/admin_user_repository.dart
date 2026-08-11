import 'package:untitled3/features/auth/domain/entities/app_user.dart';

abstract class AdminUserRepository {
  /// All users, most recent first, bounded (not the whole collection) —
  /// authorized by firestore.rules' `isAdmin()` branch on the `users` read
  /// rule. No pagination cursor yet (v1: a single bounded page); note this
  /// as a known limitation for large user bases.
  Stream<List<AppUser>> streamUsers({int limit});
}
