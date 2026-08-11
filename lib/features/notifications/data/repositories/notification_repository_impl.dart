import 'package:untitled3/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:untitled3/features/notifications/domain/entities/app_notification.dart';
import 'package:untitled3/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Stream<List<AppNotification>> streamNotifications(String uid) =>
      _dataSource.streamNotifications(uid);

  @override
  Future<void> markRead(String uid, String notificationId) =>
      _dataSource.markRead(uid, notificationId);
}
