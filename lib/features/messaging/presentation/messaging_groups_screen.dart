import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_cta_button.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/ta3afi_platform_icons_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/messaging/application/messaging_groups_service.dart';
import 'package:reboot_app_3/features/messaging/data/models/messaging_group.dart';
import 'package:reboot_app_3/features/messaging/providers/messaging_groups_providers.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';

class MessagingGroupsScreen extends ConsumerStatefulWidget {
  const MessagingGroupsScreen({super.key});

  @override
  ConsumerState<MessagingGroupsScreen> createState() =>
      _MessagingGroupsScreenState();
}

class _MessagingGroupsScreenState extends ConsumerState<MessagingGroupsScreen> {
  @override
  void initState() {
    super.initState();
    // Check subscription status and unsubscribe from plus groups if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionAndCleanupPlusGroups();
    });
  }

  /// Check subscription status and unsubscribe from plus-related groups if user is not subscribed
  Future<void> _checkSubscriptionAndCleanupPlusGroups() async {
    try {
      // Check if user has active subscription
      final hasActiveSubscription = ref.read(hasActiveSubscriptionProvider);

      if (!hasActiveSubscription) {
        // Get all groups with status
        final groupsWithStatus = await ref
            .read(messagingGroupsServiceProvider)
            .getGroupsWithStatus();

        // Find plus groups that user is subscribed to
        final subscribedPlusGroups = groupsWithStatus
            .where((groupStatus) =>
                groupStatus.group.isForPlusUsers && groupStatus.isSubscribed)
            .toList();

        // Unsubscribe from each plus group
        for (final groupStatus in subscribedPlusGroups) {
          try {
            await ref
                .read(messagingGroupsNotifierProvider.notifier)
                .unsubscribeFromGroup(groupStatus.group.topicId);
          } catch (e) {
            // Continue with other groups even if one fails
            continue;
          }
        }

        // Refresh the groups list to reflect changes
        if (subscribedPlusGroups.isNotEmpty) {
          ref.read(messagingGroupsNotifierProvider.notifier).refresh();
        }
      }
    } catch (e) {
      // Silently handle errors - this is a background cleanup operation
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final groupsAsync = ref.watch(messagingGroupsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'notifications-groups',
        false,
        true,
        actions: [
          PremiumCtaAppBarIcon(),
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.grey[700]),
            onPressed: () async {
              try {
                HapticFeedback.lightImpact();
                await ref
                    .read(messagingGroupsNotifierProvider.notifier)
                    .refresh();
              } catch (e) {
                // Silently handle refresh errors as they're handled by the notifier
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Text(
              localization.translate('subscription-groups-subtitle'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
                height: 1.4,
              ),
            ),
            verticalSpace(Spacing.points24),

            // Groups list
            Expanded(
              child: groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return _buildEmptyState(context, theme, localization);
                  }
                  return _buildGroupsList(
                      context, theme, localization, groups, ref);
                },
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spinner(),
                      verticalSpace(Spacing.points16),
                      Text(
                        localization.translate('loading-groups'),
                        style: TextStyles.body.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) =>
                    _buildErrorState(context, theme, localization, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, dynamic theme, AppLocalizations localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: theme.grey[400],
          ),
          verticalSpace(Spacing.points16),
          Text(
            localization.translate('no-groups-available'),
            style: TextStyles.h6.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points8),
          Text(
            localization.translate('no-groups-description'),
            style: TextStyles.body.copyWith(color: theme.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic theme,
      AppLocalizations localization, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: theme.error[500],
          ),
          verticalSpace(Spacing.points16),
          Text(
            localization.translate('error-loading-groups'),
            style: TextStyles.h6.copyWith(color: theme.grey[600]),
            textAlign: TextAlign.center,
          ),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () async {
              try {
                HapticFeedback.lightImpact();
                await ref
                    .read(messagingGroupsNotifierProvider.notifier)
                    .refresh();
              } catch (e) {
                // Silently handle refresh errors as they're handled by the notifier
              }
            },
            child: WidgetsContainer(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: theme.primary[600],
              borderSide: BorderSide.none,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.refreshCw, size: 16, color: theme.grey[50]),
                  horizontalSpace(Spacing.points8),
                  Text(
                    localization.translate('refresh-groups'),
                    style: TextStyles.body.copyWith(color: theme.grey[50]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    dynamic theme,
    AppLocalizations localization,
    List<GroupWithStatus> groups,
    WidgetRef ref,
  ) {
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final groupWithStatus = groups[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _GroupCard(
            groupWithStatus: groupWithStatus,
            localization: localization,
            onSubscribe: () =>
                _handleSubscribe(context, ref, groupWithStatus, localization),
            onUnsubscribe: () =>
                _handleUnsubscribe(context, ref, groupWithStatus, localization),
          ),
        );
      },
    );
  }

  void _handleSubscribe(
    BuildContext context,
    WidgetRef ref,
    GroupWithStatus groupWithStatus,
    AppLocalizations localization,
  ) async {
    try {
      HapticFeedback.lightImpact();

      if (groupWithStatus.requiresPlusUpgrade) {
        if (context.mounted) {
          _showPlusUpgradeModal(context);
        }
        return;
      }

      await ref
          .read(messagingGroupsNotifierProvider.notifier)
          .subscribeToGroup(groupWithStatus.group);

      if (context.mounted) {
        getSuccessSnackBar(
            context, localization.translate('subscription-successful'));
      }
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('Ta3afi Plus')) {
          _showPlusUpgradeModal(context);
        } else {
          getErrorSnackBar(
              context, localization.translate('subscription-failed'));
        }
      }
    }
  }

  void _handleUnsubscribe(
    BuildContext context,
    WidgetRef ref,
    GroupWithStatus groupWithStatus,
    AppLocalizations localization,
  ) async {
    try {
      HapticFeedback.lightImpact();

      // Disable unsubscription for "all_users" group
      if (groupWithStatus.group.topicId == 'all_users') {
        if (context.mounted) {
          getErrorSnackBar(
              context, localization.translate('cannot-unsubscribe-all-users'));
        }
        return;
      }

      await ref
          .read(messagingGroupsNotifierProvider.notifier)
          .unsubscribeFromGroup(groupWithStatus.group.topicId);

      if (context.mounted) {
        getSuccessSnackBar(
            context, localization.translate('unsubscription-successful'));
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(
            context, localization.translate('unsubscription-failed'));
      }
    }
  }

  void _showPlusUpgradeModal(BuildContext context) {
    try {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TaaafiPlusSubscriptionScreen(),
        );
      }
    } catch (e) {
      // Silently handle modal showing errors
    }
  }
}

class _GroupCard extends StatelessWidget {
  final GroupWithStatus groupWithStatus;
  final AppLocalizations localization;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;

  const _GroupCard({
    required this.groupWithStatus,
    required this.localization,
    required this.onSubscribe,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final group = groupWithStatus.group;

    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(
        color: groupWithStatus.isSubscribed
            ? theme.primary[300]!
            : theme.grey[300]!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with group name and badges
          Row(
            children: [
              Expanded(
                child: Text(
                  _getLocalizedGroupName(group),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (group.isForPlusUsers) ...[
                horizontalSpace(Spacing.points8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEBA01).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ta3afiPlatformIcons.plus_icon,
                        color: const Color(0xFFFEBA01),
                        size: 12,
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        localization.translate('plus-feature-badge'),
                        style: TextStyles.footnote.copyWith(
                          color: const Color(0xFFFEBA01),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          verticalSpace(Spacing.points8),

          // Description
          Text(
            _getLocalizedGroupDescription(group),
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
          verticalSpace(Spacing.points12),

          // Action button
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(dynamic theme) {
    if (groupWithStatus.isSubscribed) {
      // Show unsubscribe button for subscribed groups, but disable for "all_users"
      final isAllUsers = groupWithStatus.group.topicId == 'all_users';

      return GestureDetector(
        onTap: isAllUsers ? null : onUnsubscribe,
        child: WidgetsContainer(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isAllUsers ? theme.grey[300] : theme.success[600],
          borderSide: BorderSide.none,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isAllUsers ? LucideIcons.lock : LucideIcons.check,
                  size: 16,
                  color: isAllUsers ? theme.grey[600] : theme.grey[50]),
              horizontalSpace(Spacing.points8),
              Text(
                isAllUsers
                    ? localization.translate('default-group')
                    : localization.translate('subscribed-to-group'),
                style: TextStyles.body.copyWith(
                  color: isAllUsers ? theme.grey[600] : theme.grey[50],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (groupWithStatus.requiresPlusUpgrade) {
      // Plus upgrade button
      return GestureDetector(
        onTap: onSubscribe,
        child: WidgetsContainer(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFFFEBA01),
          borderSide: BorderSide.none,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ta3afiPlatformIcons.plus_icon,
                  size: 16, color: Colors.black),
              horizontalSpace(Spacing.points8),
              Text(
                localization.translate('upgrade-to-plus-messaging'),
                style: TextStyles.body.copyWith(color: Colors.black),
              ),
            ],
          ),
        ),
      );
    } else if (groupWithStatus.canSubscribe) {
      // Subscribe button
      return GestureDetector(
        onTap: onSubscribe,
        child: WidgetsContainer(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: theme.primary[600],
          borderSide: BorderSide.none,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 16, color: theme.grey[50]),
              horizontalSpace(Spacing.points8),
              Text(
                localization.translate('subscribe-to-group'),
                style: TextStyles.body.copyWith(color: theme.grey[50]),
              ),
            ],
          ),
        ),
      );
    } else {
      // Disabled state
      return WidgetsContainer(
        padding: EdgeInsets.symmetric(vertical: 12),
        backgroundColor: theme.grey[300],
        borderSide: BorderSide.none,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lock, size: 16, color: theme.grey[600]),
            horizontalSpace(Spacing.points8),
            Text(
              localization.translate('requires-plus-subscription'),
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  String _getLocalizedGroupName(MessagingGroup group) {
    return localization.locale.languageCode == 'ar' ? group.nameAr : group.name;
  }

  String _getLocalizedGroupDescription(MessagingGroup group) {
    return localization.locale.languageCode == 'ar'
        ? group.descriptionAr
        : group.description;
  }
}
