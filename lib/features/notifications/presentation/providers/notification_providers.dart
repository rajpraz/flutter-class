import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled3/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:untitled3/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:untitled3/features/notifications/domain/entities/app_notification.dart';
import 'package:untitled3/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(NotificationRemoteDataSource());
});

final notificationsProvider = StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  return ref.watch(notificationRepositoryProvider).streamNotifications(uid);
});
