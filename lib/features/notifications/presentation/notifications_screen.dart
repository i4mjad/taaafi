import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/notifications/data/models/app_notification.dart';
import 'package:reboot_app_3/features/notifications/data/repositories/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final groupedNotifications = ref.watch(groupedNotificationsProvider);
    final notificationsAsync = ref.watch(notificationsRepositoryProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Text(
          localization.translate('notifications'),
          style: TextStyles.h5.copyWith(color: theme.grey[900]),
        ),
        leading: IconButton(
          icon: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? LucideIcons.arrowRight
                : LucideIcons.arrowLeft,
            color: theme.grey[900],
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notificationsAsync.valueOrNull?.isNotEmpty ?? false)
            TextButton(
              onPressed: () => _showClearAllDialog(context, ref),
              child: Text(
                localization.translate('clear-all'),
                style: TextStyles.body.copyWith(color: theme.primary[600]),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bell,
                    size: 64,
                    color: theme.grey[400],
                  ),
                  verticalSpace(Spacing.points16),
                  Text(
                    localization.translate('no-notifications'),
                    style: TextStyles.h6.copyWith(color: theme.grey[600]),
                  ),
                  verticalSpace(Spacing.points8),
                  Text(
                    localization.translate('no-notifications-description'),
                    style: TextStyles.body.copyWith(color: theme.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final sortedDates = groupedNotifications.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Sort newest first

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDates[index];
              final notifications = groupedNotifications[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : 16,
                      bottom: 8,
                    ),
                    child: Text(
                      _formatDateKey(dateKey, localization),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Notifications for this date
                  ...notifications.map((notification) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: _NotificationItem(
                          notification: notification,
                          onTap: () => _handleNotificationTap(
                              context, ref, notification),
                          onDismissed: () => _handleNotificationDismissed(
                              context, ref, notification),
                        ),
                      )),
                ],
              );
            },
          );
        },
        loading: () => Center(child: Spinner()),
        error: (error, stack) {
          return Center(
            child: Text(
              localization.translate('error-loading-notifications'),
              style: TextStyles.body.copyWith(color: theme.error[600]),
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, WidgetRef ref, AppNotification notification) async {
    // Mark as read
    await ref
        .read(notificationsRepositoryProvider.notifier)
        .markAsRead(notification.id);

    // Extract screen parameter from notification data
    final screen = _extractScreenParameter(notification.additionalData);

    // Handle navigation based on notification type
    if (notification.isCommunityNotification) {
      // Handle community notifications
      final postId = notification.postId;
      if (postId != null && postId.isNotEmpty) {
        try {
          // Navigate to the post detail
          context.pushNamed(
            RouteNames.postDetail.name,
            pathParameters: {'postId': postId},
          );
        } catch (e) {
          // Fallback: if post detail navigation fails, go to community
          try {
            context.pushNamed(RouteNames.community.name);
          } catch (e2) {
            // Last fallback: stay on notifications screen
            print('Failed to navigate to post or community: $e');
          }
        }
      }
    } else if (screen != null && screen.isNotEmpty) {
      try {
        // Handle special cases with parameters
        if (screen == 'reportConversation' || screen == 'reportDetails') {
          final reportId = _extractReportId(notification);
          if (reportId.isNotEmpty) {
            context.pushNamed(
              RouteNames.reportConversation.name,
              pathParameters: {'reportId': reportId},
            );
          }
        } else if (screen == 'postDetails') {
          // Handle community post navigation from legacy notifications
          final postId =
              notification.postId ?? notification.additionalData?['postId'];
          if (postId != null) {
            try {
              context.pushNamed(
                RouteNames.postDetail.name,
                pathParameters: {'postId': postId},
              );
            } catch (e) {
              // Fallback: if post detail navigation fails, go to community
              try {
                context.pushNamed(RouteNames.community.name);
              } catch (e2) {
                // Last fallback: stay on notifications screen
                print('Failed to navigate to post or community: $e');
              }
            }
          }
        } else {
          // Direct navigation to the specified screen
          context.goNamed(screen);
        }
      } catch (e) {
        // Fallback: if navigation fails, stay on notifications screen
      }
    } else if (notification.reportId.isNotEmpty) {
      // Fallback: Navigate to report conversation if no screen but has reportId
      context.pushNamed(
        RouteNames.reportConversation.name,
        pathParameters: {'reportId': notification.reportId},
      );
    }

    // Delete after navigation
    await ref
        .read(notificationsRepositoryProvider.notifier)
        .deleteNotification(notification.id);
  }

  void _handleNotificationDismissed(
      BuildContext context, WidgetRef ref, AppNotification notification) async {
    await ref
        .read(notificationsRepositoryProvider.notifier)
        .deleteNotification(notification.id);
    getSuccessSnackBar(context, 'notification-deleted');
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = AppTheme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            localization.translate('clear-all-notifications'),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          content: Text(
            localization.translate('clear-all-notifications-description'),
            style: TextStyles.body.copyWith(color: theme.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                localization.translate('cancel'),
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(notificationsRepositoryProvider.notifier)
                    .deleteAllNotifications();
                getSuccessSnackBar(context, 'all-notifications-cleared');
              },
              child: Text(
                localization.translate('clear'),
                style: TextStyles.body.copyWith(color: theme.error[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _extractScreenParameter(Map<String, dynamic>? additionalData) {
    if (additionalData == null) return null;

    try {
      final rawValue = additionalData['raw'];

      if (rawValue is Map<String, dynamic>) {
        return rawValue['screen'] as String?;
      } else if (rawValue is String) {
        // Parse string format like "{screen: community}"
        final screenMatch = RegExp(r'screen:\s*(\w+)').firstMatch(rawValue);
        return screenMatch?.group(1);
      }

      // Fallback to direct access
      return additionalData['screen'] as String?;
    } catch (e) {
      return additionalData['screen'] as String?;
    }
  }

  String _extractReportId(AppNotification notification) {
    try {
      final rawValue = notification.additionalData?['raw'];
      if (rawValue is Map<String, dynamic>) {
        final reportId = rawValue['reportId'] as String?;
        if (reportId != null && reportId.isNotEmpty) return reportId;
      }

      final directReportId =
          notification.additionalData?['reportId'] as String?;
      if (directReportId != null && directReportId.isNotEmpty)
        return directReportId;

      return notification.reportId;
    } catch (e) {
      return notification.reportId;
    }
  }

  String _formatDateKey(DateTime date, AppLocalizations localization) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return localization.translate('today');
    } else if (difference.inDays == 1) {
      return localization.translate('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${localization.translate('days-ago')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.error[600],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          LucideIcons.trash2,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? theme.grey[100] : theme.primary[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  notification.isRead ? theme.grey[200]! : theme.primary[200]!,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? theme.grey[300]
                      : theme.primary[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(notification.reportStatus),
                  size: 20,
                  color: notification.isRead
                      ? theme.grey[600]
                      : theme.primary[600],
                ),
              ),
              horizontalSpace(Spacing.points12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points8),
                    Text(
                      notification.message,
                      style: TextStyles.small.copyWith(
                        color: theme.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    verticalSpace(Spacing.points8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: theme.grey[500],
                        ),
                        horizontalSpace(Spacing.points4),
                        Text(
                          _formatTime(notification.timestamp, localization),
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primary[600],
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return LucideIcons.clock;
      case 'in-progress':
        return LucideIcons.loader;
      case 'waiting-for-admin-response':
        return LucideIcons.messageSquare;
      case 'closed':
        return LucideIcons.xCircle;
      case 'finalized':
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.bell;
    }
  }

  String _formatTime(DateTime time, AppLocalizations localization) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return localization.translate('just-now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${localization.translate('minutes-ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${localization.translate('hours-ago')}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
