import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/action_modal.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';
import 'package:reboot_app_3/features/groups/application/challenges_providers.dart';
import 'package:reboot_app_3/features/groups/domain/entities/challenge_task_instance.dart';
import 'package:reboot_app_3/features/groups/providers/challenge_detail_notifier.dart';
import 'package:share_plus/share_plus.dart';

/// Model for update items in the group
class GroupUpdateItem {
  final String id;
  final String title;
  final String time;
  final IconData? icon;
  final Color iconColor;

  const GroupUpdateItem({
    required this.id,
    required this.title,
    required this.time,
    this.icon,
    required this.iconColor,
  });
}

/// Enum for member online status
enum MemberStatus { online, offline }

/// Model for group member
class GroupMember {
  final String id;
  final String name;
  final Color avatarColor;
  final MemberStatus status;
  final DateTime? lastSeen;

  const GroupMember({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.status,
    this.lastSeen,
  });
}

/// Model for coming soon features
class ComingSoonFeature {
  final IconData icon;
  final String title;

  const ComingSoonFeature({
    required this.icon,
    required this.title,
  });
}

class GroupScreen extends ConsumerWidget {
  final bool showAppBar;

  const GroupScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final membershipAsync = ref.watch(groupMembershipNotifierProvider);

    return membershipAsync.when(
      data: (membership) {
        // If membership is null, show loading instead of error
        // This happens when user just left the group and navigation is in progress
        if (membership == null) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20), // Add bottom padding
            child: Column(
              children: [
                // Descriptive section about groups feature
                _buildDescriptiveSection(context, theme, l10n, membership),

                // Group header (commented for later use)
                // _buildGroupHeader(context, theme, l10n, membership),

                // Content (commented for later use)
                // Expanded(
                //   child: _buildContent(context, theme, l10n),
                // ),

                // Today Tasks section
                _buildTodayTasksSection(context, ref, theme, l10n, membership.group.id),

                const SizedBox(height: 16),

                // Bottom sections
                _buildBottomSections(context, theme, l10n, membership.group.id),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Text('${l10n.translate('error')}: ${error.toString()}'),
        ),
      ),
    );
  }

  // Commented for later use
  // Widget _buildGroupHeader(BuildContext context, CustomThemeData theme,
  //     AppLocalizations l10n, GroupMembership membership) {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Group name
  //         Text(
  //           l10n.translate('group-name'),
  //           style: TextStyles.h5.copyWith(
  //             color: theme.grey[900],
  //           ),
  //         ),
  //
  //         const SizedBox(height: 8),
  //
  //         // Member count and avatars
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             // Member count with green dot
  //             // Member avatars
  //             _buildMemberAvatars(context, l10n),
  //             Row(
  //               children: [
  //                 Container(
  //                   width: 8,
  //                   height: 8,
  //                   decoration: const BoxDecoration(
  //                     color: Colors.green,
  //                     shape: BoxShape.circle,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   l10n.translate('members-online-now'),
  //                   style: TextStyles.body.copyWith(
  //                     color: theme.grey[700],
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Commented for later use
  // Widget _buildMemberAvatars(BuildContext context, AppLocalizations l10n) {
  //   return GestureDetector(
  //     onTap: () => _showGroupMembers(context, l10n),
  //     child: SizedBox(
  //       width: 92, // Width for 4 avatars: 32 + (3 * 20) = 92px
  //       height: 32,
  //       child: Stack(
  //         children: [
  //           _buildAvatar(Colors.orange, 0),
  //           _buildAvatar(Colors.blue, 1),
  //           _buildAvatar(Colors.purple, 2),
  //           _buildAvatar(Colors.green, 3),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Commented for later use
  // Widget _buildAvatar(Color color, int index) {
  //   return Positioned(
  //     left: index * 20.0, // Overlap by 12px (32px width - 20px spacing)
  //     child: Container(
  //       width: 32,
  //       height: 32,
  //       decoration: BoxDecoration(
  //         color: color,
  //         shape: BoxShape.circle,
  //         border: Border.all(color: Colors.white, width: 1),
  //       ),
  //     ),
  //   );
  // }

  // Commented for later use
  // Widget _buildContent(
  //     BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Recent updates title
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         child: Text(
  //           l10n.translate('recent-updates'),
  //           style: TextStyles.h6.copyWith(
  //             color: theme.grey[900],
  //           ),
  //         ),
  //       ),
  //
  //       const SizedBox(height: 16),
  //
  //       // Updates list
  //       Expanded(
  //         child: ListView.builder(
  //           padding: const EdgeInsets.symmetric(horizontal: 20),
  //           itemCount: _getDemoUpdates().length,
  //           itemBuilder: (context, index) {
  //             final update = _getDemoUpdates()[index];
  //             return _buildUpdateItem(context, theme, update, index);
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDescriptiveSection(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, GroupMembership membership) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Group name as title
          Text(
            membership.group.name,
            style: TextStyles.h4.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            l10n.translate('groups-feature-description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksSection(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
    String groupId,
  ) {
    final todayTasksAsync = ref.watch(groupTodayTasksProvider(groupId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('your-tasks-today'),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          todayTasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return WidgetsContainer(
                  backgroundColor: theme.grey[50],
                  borderSide: BorderSide(
                    color: theme.grey[200]!,
                    width: 1,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.translate('no-tasks-today'),
                        style: TextStyles.body.copyWith(
                          color: theme.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: tasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final taskInstance = entry.value;
                  return _buildTodayTaskItem(
                    context,
                    ref,
                    theme,
                    l10n,
                    taskInstance,
                    index + 1,
                    groupId,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => WidgetsContainer(
              backgroundColor: theme.error[50],
              borderSide: BorderSide(
                color: theme.error[200]!,
                width: 1,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${l10n.translate('error')}: ${error.toString()}',
                  style: TextStyles.small.copyWith(
                    color: theme.error[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTaskItem(
    BuildContext context,
    WidgetRef ref,
    CustomThemeData theme,
    AppLocalizations l10n,
    ChallengeTaskInstance taskInstance,
    int number,
    String groupId,
  ) {
    final task = taskInstance.task;
    final isCompleted = taskInstance.status == TaskInstanceStatus.completed;
    
    // Calculate time remaining until end of day
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final timeRemaining = endOfDay.difference(now);
    
    String timeRemainingText;
    Color timeRemainingColor;
    
    if (isCompleted) {
      timeRemainingText = '✓ ${l10n.translate('completed')}';
      timeRemainingColor = theme.success[600]!;
    } else if (timeRemaining.inHours > 0) {
      timeRemainingText = '${timeRemaining.inHours} ${l10n.translate('hours-left')}';
      timeRemainingColor = theme.warn[600]!;
    } else if (timeRemaining.inMinutes > 0) {
      timeRemainingText = '${timeRemaining.inMinutes} ${l10n.translate('minutes-left')}';
      timeRemainingColor = theme.error[600]!;
    } else {
      timeRemainingText = l10n.translate('task-expired');
      timeRemainingColor = theme.grey[500]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Row(
          children: [
            // Task content (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.points} ${l10n.translate('points')}',
                    style: TextStyles.small.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeRemainingText,
                    style: TextStyles.small.copyWith(
                      color: timeRemainingColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Number and checkbox (right side)
            Row(
              children: [
                // Number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.primary[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyles.small.copyWith(
                        color: theme.primary[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Checkbox
                GestureDetector(
                  onTap: isCompleted ? null : () {
                    _completeTodayTask(ref, taskInstance, groupId);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? theme.success[500]
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? theme.success[500]!
                            : theme.grey[400]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _completeTodayTask(WidgetRef ref, ChallengeTaskInstance taskInstance, String groupId) {
    // We need to find the challenge ID from the task instance
    final challengesAsync = ref.read(activeChallengesProvider(groupId));
    
    challengesAsync.whenData((challenges) {
      // Find the challenge that contains this task
      for (final challenge in challenges) {
        if (challenge.tasks.any((t) => t.id == taskInstance.task.id)) {
          // Found the challenge, complete the task
          ref.read(challengeDetailNotifierProvider(challenge.id).notifier).completeTask(
            taskInstance.task.id,
            taskInstance.task.points,
            taskInstance.task.frequency,
          );
          break;
        }
      }
    });
  }

  Widget _buildComingSoonCard({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ComingSoonFeature> features,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and "Soon" badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1),
              cornerSmoothing: 0.6,
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 24,
                color: theme.grey[700],
              ),
            ),
            const Spacer(),
            WidgetsContainer(
              backgroundColor: theme.grey[200]!,
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
              cornerSmoothing: 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                l10n.translate('coming-soon'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12), // Reduced spacing

        // Title
        Text(
          title,
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6), // Reduced spacing

        // Subtitle
        Text(
          subtitle,
          style: TextStyles.smallBold.copyWith(
            color: theme.grey[600],
            height: 1.3, // Reduced line height
          ),
        ),

        const SizedBox(height: 16), // Reduced spacing

        // What's Coming section
        WidgetsContainer(
          backgroundColor: theme.grey[50],
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1),
          cornerSmoothing: 0.8,
          padding: const EdgeInsets.all(10), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('whats-coming'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              // Features list
              ...features
                  .map((feature) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 4), // Reduced spacing
                        child: Row(
                          children: [
                            Icon(
                              feature.icon,
                              size: 16,
                              color: theme.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature.title,
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Commented for later use
  //   //     GroupUpdateItem update, int index) {
  //   // Even-numbered items (index 1, 3, 5... which are 2nd, 4th, 6th items) get background
  //   final isEvenItem = (index + 1) % 2 == 0;
  //
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 8),
  //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  //     decoration: isEvenItem
  //         ? BoxDecoration(
  //             color: theme.grey[50],
  //             borderRadius: BorderRadius.circular(8),
  //           )
  //         : null,
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       textDirection: TextDirection.rtl, // RTL layout for Arabic
  //       children: [
  //         // Time (rightmost in RTL)
  //         Text(
  //           update.time,
  //           style: TextStyles.caption.copyWith(
  //             color: theme.grey[500],
  //             fontWeight: FontWeight.w400,
  //             fontSize: 12,
  //           ),
  //         ),
  //
  //         const SizedBox(width: 12),
  //
  //         // User Avatar (middle)
  //         //TODO: Change this to the real avatar
  //         Container(
  //           width: 36,
  //           height: 36,
  //           decoration: BoxDecoration(
  //             color: update.iconColor,
  //             shape: BoxShape.circle,
  //             border: Border.all(color: Colors.white, width: 0.75),
  //           ),
  //           child: update.icon != null
  //               ? Icon(
  //                   update.icon,
  //                   size: 16,
  //                   color: Colors.white,
  //                 )
  //               : null,
  //         ),
  //
  //         const SizedBox(width: 12),
  //
  //         // Main text content (leftmost in RTL)
  //         Expanded(
  //           child: Text(
  //             update.title,
  //             style: TextStyles.smallBold.copyWith(
  //               color: theme.grey[900],
  //               fontWeight: FontWeight.w400,
  //               height: 1.4,
  //             ),
  //             textAlign: TextAlign.right,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBottomSections(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, String groupId) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row: Chat section only
          Row(
            children: [
              // Chat section
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.messageCircle,
                  label: l10n.translate('chat'),
                  backgroundColor: theme.primary[50]!,
                  borderColor: theme.primary[200]!,
                  textColor: theme.primary[900]!,
                  onTap: () => _navigateToChat(context, groupId),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second row: Challenges and Settings
          Row(
            children: [
              // Challenges section
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.trophy,
                  label: l10n.translate('challenges'),
                  backgroundColor: theme.success[50]!,
                  borderColor: theme.success[200]!,
                  textColor: theme.success[900]!,
                  onTap: () => _navigateToChallenges(context, groupId),
                ),
              ),

              const SizedBox(width: 8),

              // Settings section
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.settings,
                  label: l10n.translate('settings'),
                  backgroundColor: theme.grey[50]!,
                  borderColor: theme.grey[200]!,
                  textColor: theme.grey[900]!,
                  onTap: () => _navigateToSettings(context, groupId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        backgroundColor: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1),
        cornerSmoothing: 0.6,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon positioned at bottom-right
            Icon(
              icon,
              size: 25,
            ),
            verticalSpace(Spacing.points8),
            // Label positioned at bottom-left
            Text(
              label,
              style: TextStyles.h5.copyWith(
                color: textColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupChat.name,
      pathParameters: {'groupId': groupId},
    );
  }

  // Commented for later use
  // void _navigateToUpdates(BuildContext context, String groupId) {
  //   context.goNamed(
  //     RouteNames.groupUpdates.name,
  //     pathParameters: {'groupId': groupId},
  //   );
  // }

  void _navigateToSettings(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupSettings.name,
      pathParameters: {'groupId': groupId},
    );
  }

  void _navigateToChallenges(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupChallenges.name,
      pathParameters: {'groupId': groupId},
    );
  }

  Widget _buildShareAction(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, GroupMembership membership) {
    return GestureDetector(
      onTap: () => _showShareModal(context, l10n, membership),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, left: 16),
        child: Icon(
          LucideIcons.share2,
          color: theme.grey[900],
        ),
      ),
    );
  }

  void _showShareModal(
      BuildContext context, AppLocalizations l10n, GroupMembership membership) {
    final joinCode = membership.group.joinCode;

    if (joinCode == null) {
      // Handle case where there's no join code (shouldn't happen but good to be safe)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error-no-join-code'))),
      );
      return;
    }

    ActionModal.show(
      context,
      title: l10n.translate('share-group'),
      actions: [
        ActionItem(
          icon: LucideIcons.share2,
          title: l10n.translate('share-to-social'),
          subtitle: l10n.translate('share-to-social-subtitle'),
          onTap: () => _shareToSocial(context, l10n, joinCode),
        ),
      ],
    );
  }

  void _shareToSocial(
      BuildContext context, AppLocalizations l10n, String joinCode) {
    final shareMessage =
        l10n.translate('group-share-message').replaceAll('{code}', joinCode);

    SharePlus.instance.share(
      ShareParams(
        text: shareMessage,
        subject: l10n.translate('share-group'),
      ),
    );
  }

  // Commented for later use
  // List<GroupUpdateItem> _getDemoUpdates() {
  //   return [
  //     GroupUpdateItem(
  //       id: '1',
  //       title: 'أكمل صلاة الفجر اليوم ستين يوم بدون إجابة بالورده',
  //       time: '12:00',
  //       icon: null,
  //       iconColor: Colors.grey[400]!,
  //     ),
  //     GroupUpdateItem(
  //       id: '2',
  //       title: 'أكمل يوسف يوسف بـ 5 أيام بدون إجابة',
  //       time: '12:00',
  //       icon: null,
  //       iconColor: Colors.orange[400]!,
  //     ),
  //     GroupUpdateItem(
  //       id: '3',
  //       title: 'تقدم يوسف يوسف إلى المركز الأول في تحدي 30 يوم بدون إجابة',
  //       time: '12:00',
  //       icon: null,
  //       iconColor: Colors.red[400]!,
  //     ),
  //     GroupUpdateItem(
  //       id: '4',
  //       title: 'أنهى سيف حمد مقام اليوم',
  //       time: '12:00',
  //       icon: null,
  //       iconColor: Colors.brown[400]!,
  //     ),
  //   ];
  // }

  // Commented for later use
  // List<GroupMember> _getDemoMembers() {
  //   return [
  //     GroupMember(
  //       id: '1',
  //       name: 'أحمد محمد',
  //       avatarColor: Colors.orange,
  //       status: MemberStatus.online,
  //     ),
  //     GroupMember(
  //       id: '2',
  //       name: 'سارة أحمد',
  //       avatarColor: Colors.blue,
  //       status: MemberStatus.offline,
  //       lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
  //     ),
  //     GroupMember(
  //       id: '3',
  //       name: 'محمد علي',
  //       avatarColor: Colors.purple,
  //       status: MemberStatus.offline,
  //       lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
  //     ),
  //     GroupMember(
  //       id: '4',
  //       name: 'فاطمة حسن',
  //       avatarColor: Colors.green,
  //       status: MemberStatus.offline,
  //       lastSeen: DateTime.now().subtract(const Duration(days: 1)),
  //     ),
  //   ];
  // }

  // Commented for later use
  // void _showGroupMembers(BuildContext context, AppLocalizations l10n) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => GroupMembersModal(
  //       members: _getDemoMembers(),
  //     ),
  //   );
  // }
}

/// Modal bottom sheet for displaying group members
class GroupMembersModal extends StatelessWidget {
  final List<GroupMember> members;

  const GroupMembersModal({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('group-members'),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                ),
                Text(
                  _getMemberCountText(l10n, members.length),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Members list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: members.length,
              itemBuilder: (context, index) {
                return _buildMemberItem(context, theme, l10n, members[index]);
              },
            ),
          ),

          // Bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    GroupMember member,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: member.avatarColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),

          const SizedBox(width: 12),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: member.status == MemberStatus.online
                            ? Colors.green
                            : theme.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(l10n, member),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMemberCountText(AppLocalizations l10n, int count) {
    if (count == 1) {
      return l10n
          .translate('member-count')
          .replaceAll('{count}', count.toString());
    } else {
      return l10n
          .translate('member-count-plural')
          .replaceAll('{count}', count.toString());
    }
  }

  String _getStatusText(AppLocalizations l10n, GroupMember member) {
    if (member.status == MemberStatus.online) {
      return l10n.translate('online');
    } else {
      if (member.lastSeen == null) {
        return l10n.translate('offline');
      }

      final now = DateTime.now();
      final difference = now.difference(member.lastSeen!);

      if (difference.inMinutes < 1) {
        return l10n.translate('just-now');
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        if (minutes == 1) {
          return '${l10n.translate('last-seen')} ${l10n.translate('minutes-ago').replaceAll('{count}', minutes.toString())}';
        } else {
          return '${l10n.translate('last-seen')} ${l10n.translate('minutes-ago-plural').replaceAll('{count}', minutes.toString())}';
        }
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        if (hours == 1) {
          return '${l10n.translate('last-seen')} ${l10n.translate('hours-ago').replaceAll('{count}', hours.toString())}';
        } else {
          return '${l10n.translate('last-seen')} ${l10n.translate('hours-ago-plural').replaceAll('{count}', hours.toString())}';
        }
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        if (days == 1) {
          return '${l10n.translate('last-seen')} ${l10n.translate('days-ago').replaceAll('{count}', days.toString())}';
        } else {
          return '${l10n.translate('last-seen')} ${l10n.translate('days-ago-plural').replaceAll('{count}', days.toString())}';
        }
      } else {
        final weeks = (difference.inDays / 7).floor();
        if (weeks == 1) {
          return '${l10n.translate('last-seen')} ${l10n.translate('weeks-ago').replaceAll('{count}', weeks.toString())}';
        } else {
          return '${l10n.translate('last-seen')} ${l10n.translate('weeks-ago-plural').replaceAll('{count}', weeks.toString())}';
        }
      }
    }
  }
}
