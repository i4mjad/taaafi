// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadNotificationCountHash() =>
    r'edbe95b1d4ecc7a0dd789a9f4aacee0431fb62fe';

/// See also [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeFutureProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeFutureProviderRef<int>;
String _$groupedNotificationsHash() =>
    r'405702b7943f2fdd909d1afc0711af5b6954f991';

/// See also [groupedNotifications].
@ProviderFor(groupedNotifications)
final groupedNotificationsProvider =
    AutoDisposeProvider<Map<DateTime, List<AppNotification>>>.internal(
  groupedNotifications,
  name: r'groupedNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupedNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GroupedNotificationsRef
    = AutoDisposeProviderRef<Map<DateTime, List<AppNotification>>>;
String _$notificationsRepositoryHash() =>
    r'efb1cf2d42e4defffc5108a77406b042a351327e';

/// See also [NotificationsRepository].
@ProviderFor(NotificationsRepository)
final notificationsRepositoryProvider = AutoDisposeAsyncNotifierProvider<
    NotificationsRepository, List<AppNotification>>.internal(
  NotificationsRepository.new,
  name: r'notificationsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationsRepository
    = AutoDisposeAsyncNotifier<List<AppNotification>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
