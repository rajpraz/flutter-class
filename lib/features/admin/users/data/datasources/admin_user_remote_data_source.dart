import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/auth/domain/entities/app_user.dart';

class AdminUserRemoteDataSource {
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Stream<List<AppUser>> streamUsers({int limit = 200}) {
    return _users
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }
}
