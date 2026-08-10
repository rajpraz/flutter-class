import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/app_notification.dart';

class NotificationService {
  static CollectionReference<Map<String, dynamic>> _items(String uid) =>
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items');

  static Stream<List<AppNotification>> streamNotifications(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  static Future<void> create({
    required String uid,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    await _items(uid).add(AppNotification(
      id: '',
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      createdAt: DateTime.now(),
    ).toMap());
  }

  static Future<void> markRead(String uid, String notificationId) async {
    await _items(uid).doc(notificationId).update({'read': true});
  }
}
