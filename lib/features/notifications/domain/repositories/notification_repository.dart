import 'package:untitled3/features/notifications/domain/entities/app_notification.dart';

/// Notification *creation* for order events is entirely a trusted backend
/// concern (functions/src/notifications/onOrderWrite.ts, using the Admin
/// SDK) — the client only ever reads its own notifications and marks them
/// read. There is deliberately no `create` method here: the previous
/// client-side `NotificationService.create` (which could write into any
/// other user's notification inbox under the old, looser Firestore rule)
/// was removed when checkout/seller-orders were wired to Cloud Functions.
abstract class NotificationRepository {
  Stream<List<AppNotification>> streamNotifications(String uid);

  Future<void> markRead(String uid, String notificationId);
}
