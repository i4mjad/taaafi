import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/providers/group_membership_provider.dart';

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

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(groupMembershipNotifierProvider);

    if (membership == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: const Center(
          child: Text('خطأ: لم يتم العثور على عضوية في مجموعة'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "group", false, false),
      body: Column(
        children: [
          // Group header
          _buildGroupHeader(context, theme, l10n, membership),

          // Content
          Expanded(
            child: _buildContent(context, theme, l10n),
          ),

          // Bottom sections (Chat and Challenges)
          _buildBottomSections(context, theme, l10n, membership.group.id),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, GroupMembership membership) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name
          Text(
            'اسم الزمالة',
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
          ),

          const SizedBox(height: 8),

          // Member count and avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Member count with green dot
              // Member avatars
              _buildMemberAvatars(context, l10n),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '3 متحدين الآن',
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatars(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showGroupMembers(context, l10n),
      child: SizedBox(
        width: 92, // Width for 4 avatars: 32 + (3 * 20) = 92px
        height: 32,
        child: Stack(
          children: [
            _buildAvatar(Colors.orange, 0),
            _buildAvatar(Colors.blue, 1),
            _buildAvatar(Colors.purple, 2),
            _buildAvatar(Colors.green, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color, int index) {
    return Positioned(
      left: index * 20.0, // Overlap by 12px (32px width - 20px spacing)
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent updates title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'التحديثات الأخيرة',
            style: TextStyles.h6.copyWith(
              color: theme.grey[900],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Updates list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _getDemoUpdates().length,
            itemBuilder: (context, index) {
              final update = _getDemoUpdates()[index];
              return _buildUpdateItem(context, theme, update, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem(BuildContext context, CustomThemeData theme,
      GroupUpdateItem update, int index) {
    // Even-numbered items (index 1, 3, 5... which are 2nd, 4th, 6th items) get background
    final isEvenItem = (index + 1) % 2 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: isEvenItem
          ? BoxDecoration(
              color: theme.grey[50],
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: TextDirection.rtl, // RTL layout for Arabic
        children: [
          // Time (rightmost in RTL)
          Text(
            update.time,
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 12),

          // User Avatar (middle)
          //TODO: Change this to the real avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: update.iconColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 0.75),
            ),
            child: update.icon != null
                ? Icon(
                    update.icon,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Main text content (leftmost in RTL)
          Expanded(
            child: Text(
              update.title,
              style: TextStyles.smallBold.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSections(BuildContext context, CustomThemeData theme,
      AppLocalizations l10n, String groupId) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row: Challenges and Chat
          Row(
            children: [
              // Challenges section (top left)
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.trophy,
                  label: 'التحديات',
                  backgroundColor: theme.secondary[50]!,
                  borderColor: theme.secondary[200]!,
                  textColor: theme.secondary[900]!,
                  onTap: () => _navigateToChallenges(context, groupId),
                ),
              ),

              const SizedBox(width: 8),

              // Chat section (top right)
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.messageCircle,
                  label: 'المحادثة',
                  backgroundColor: theme.primary[50]!,
                  borderColor: theme.primary[200]!,
                  textColor: theme.primary[900]!,
                  onTap: () => _navigateToChat(context, groupId),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom row: Settings and Updates
          Row(
            children: [
              // Settings section (bottom left)
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.settings,
                  label: 'الإعدادات',
                  backgroundColor: theme.grey[50]!,
                  borderColor: theme.grey[200]!,
                  textColor: theme.grey[900]!,
                  onTap: () => _navigateToSettings(context, groupId),
                ),
              ),

              const SizedBox(width: 8),

              // Updates section (bottom right)
              Expanded(
                child: _buildBottomSection(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.layers,
                  label: 'التحديثات',
                  backgroundColor: theme.tint[50]!,
                  borderColor: theme.tint[200]!,
                  textColor: theme.tint[900]!,
                  onTap: () => _navigateToUpdates(context, groupId),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
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

  void _navigateToUpdates(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupUpdates.name,
      pathParameters: {'groupId': groupId},
    );
  }

  void _navigateToSettings(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupSettings.name,
      pathParameters: {'groupId': groupId},
    );
  }

  void _navigateToChallenges(BuildContext context, String groupId) {
    context.goNamed(
      RouteNames.groupChallenge.name,
      pathParameters: {'groupId': groupId},
    );
  }

  List<GroupUpdateItem> _getDemoUpdates() {
    return [
      GroupUpdateItem(
        id: '1',
        title: 'أكمل صلاة الفجر اليوم ستين يوم بدون إجابة بالورده',
        time: '12:00',
        icon: null,
        iconColor: Colors.grey[400]!,
      ),
      GroupUpdateItem(
        id: '2',
        title: 'أكمل يوسف يوسف بـ 5 أيام بدون إجابة',
        time: '12:00',
        icon: null,
        iconColor: Colors.orange[400]!,
      ),
      GroupUpdateItem(
        id: '3',
        title: 'تقدم يوسف يوسف إلى المركز الأول في تحدي 30 يوم بدون إجابة',
        time: '12:00',
        icon: null,
        iconColor: Colors.red[400]!,
      ),
      GroupUpdateItem(
        id: '4',
        title: 'أنهى سيف حمد مقام اليوم',
        time: '12:00',
        icon: null,
        iconColor: Colors.brown[400]!,
      ),
    ];
  }

  List<GroupMember> _getDemoMembers() {
    return [
      GroupMember(
        id: '1',
        name: 'أحمد محمد',
        avatarColor: Colors.orange,
        status: MemberStatus.online,
      ),
      GroupMember(
        id: '2',
        name: 'سارة أحمد',
        avatarColor: Colors.blue,
        status: MemberStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      GroupMember(
        id: '3',
        name: 'محمد علي',
        avatarColor: Colors.purple,
        status: MemberStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      GroupMember(
        id: '4',
        name: 'فاطمة حسن',
        avatarColor: Colors.green,
        status: MemberStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  void _showGroupMembers(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupMembersModal(
        members: _getDemoMembers(),
      ),
    );
  }
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
