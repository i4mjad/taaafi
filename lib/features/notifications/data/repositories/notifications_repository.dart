import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/notifications/data/database/notifications_database.dart';
import 'package:reboot_app_3/features/notifications/data/models/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_repository.g.dart';

@riverpod
class NotificationsRepository extends _$NotificationsRepository {
  late final NotificationsDatabase _database;

  @override
  Future<List<AppNotification>> build() async {
    _database = NotificationsDatabase.instance;

    // Load all notifications on initialization
    return await _database.readAllNotifications();
  }

  Future<void> addNotification(AppNotification notification) async {
    await _database.create(notification);
    state = AsyncValue.data(await _database.readAllNotifications());
  }

  Future<void> markAsRead(String id) async {
    await _database.markAsRead(id);
    state = AsyncValue.data(await _database.readAllNotifications());
  }

  Future<void> deleteNotification(String id) async {
    await _database.delete(id);
    state = AsyncValue.data(await _database.readAllNotifications());
  }

  Future<void> deleteAllNotifications() async {
    await _database.deleteAll();
    state = AsyncValue.data([]);
  }

  Future<int> getUnreadCount() async {
    return await _database.getUnreadCount();
  }
}

@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final repository = await ref.watch(notificationsRepositoryProvider.future);
  return ref.watch(notificationsRepositoryProvider.notifier).getUnreadCount();
}

// Helper provider for grouped notifications by date
@riverpod
Map<DateTime, List<AppNotification>> groupedNotifications(Ref ref) {
  final notifications =
      ref.watch(notificationsRepositoryProvider).valueOrNull ?? [];

  final Map<DateTime, List<AppNotification>> grouped = {};

  for (final notification in notifications) {
    final dateKey = _getDateOnly(notification.timestamp);
    grouped.putIfAbsent(dateKey, () => []).add(notification);
  }

  return grouped;
}

DateTime _getDateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
