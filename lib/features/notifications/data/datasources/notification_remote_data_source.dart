import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/features/notifications/domain/entities/app_notification.dart';

class NotificationRemoteDataSource {
  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items');

  Stream<List<AppNotification>> streamNotifications(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  Future<void> markRead(String uid, String notificationId) async {
    await _items(uid).doc(notificationId).update({'read': true});
  }
}
