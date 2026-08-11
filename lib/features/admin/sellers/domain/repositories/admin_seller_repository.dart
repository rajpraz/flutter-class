import 'package:untitled3/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

abstract class AdminSellerRepository {
  /// `sellerApplications` where `status == 'pending'` — a direct Firestore
  /// read, already authorized by firestore.rules for an admin.
  Stream<List<SellerApplication>> streamPendingApplications();

  /// Approval/rejection are NOT direct Firestore writes — the
  /// `sellerApplications` rule denies all client writes
  /// (`allow write: if false;`), by design: only the trusted
  /// `approveSellerApplication`/`rejectSellerApplication` Cloud Functions
  /// (Admin SDK) may grant the "seller" custom claim. These call those
  /// existing functions; nothing new is added to functions/ for this.
  Future<void> approveApplication(String applicantUid);

  Future<void> rejectApplication(String applicantUid, {String? reason});

  /// Every user with `role == 'seller'` — a direct Firestore read/list
  /// query, already authorized for an admin by firestore.rules' `isAdmin()`
  /// branch on the `users` read rule.
  Stream<List<AppUser>> streamSellers();

  /// Promotes/demotes any user's role via the existing `setUserRole` Cloud
  /// Function (admin-only, sets the custom claim via the Admin SDK).
  /// firestore.rules gives admins NO direct write path to `users/{uid}` —
  /// this is the only way a role ever changes after signup. Used both to
  /// demote a seller back to buyer ("deactivate" — there is no separate
  /// suspension flag, this genuinely changes their role) and, from the
  /// user-management screen, to promote a buyer to admin.
  Future<void> setUserRole(String uid, String role);
}
