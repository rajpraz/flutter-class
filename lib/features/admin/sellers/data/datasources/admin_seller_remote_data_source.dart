import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/core/network/functions_client.dart';
import 'package:untitled3/features/admin/sellers/domain/entities/seller_application.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

class AdminSellerRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> _applications =
      FirebaseFirestore.instance.collection('sellerApplications');
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Stream<List<SellerApplication>> streamPendingApplications() {
    return _applications
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SellerApplication.fromDoc).toList());
  }

  Future<void> approveApplication(String applicantUid) async {
    await FunctionsClient.call('approveSellerApplication', {'applicantUid': applicantUid});
  }

  Future<void> rejectApplication(String applicantUid, {String? reason}) async {
    await FunctionsClient.call('rejectSellerApplication', {
      'applicantUid': applicantUid,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Stream<List<AppUser>> streamSellers() {
    return _users
        .where('role', isEqualTo: 'seller')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  Future<void> setUserRole(String uid, String role) async {
    await FunctionsClient.call('setUserRole', {'targetUid': uid, 'role': role});
  }
}
