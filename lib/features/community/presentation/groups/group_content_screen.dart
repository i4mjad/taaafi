import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/community/providers/group_membership_provider.dart';

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

class GroupContentScreen extends ConsumerWidget {
  const GroupContentScreen({super.key});

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
          _buildBottomSections(context, theme, l10n),
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
              _buildMemberAvatars(),
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

  Widget _buildMemberAvatars() {
    return Row(
      children: [
        _buildAvatar(Colors.orange),
        Transform.translate(
          offset: const Offset(-8, 0),
          child: _buildAvatar(Colors.blue),
        ),
        Transform.translate(
          offset: const Offset(-16, 0),
          child: _buildAvatar(Colors.purple),
        ),
        Transform.translate(
          offset: const Offset(-24, 0),
          child: _buildAvatar(Colors.green),
        ),
      ],
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: update.iconColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
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

  Widget _buildBottomSections(
      BuildContext context, CustomThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Chat section
          Expanded(
            child: _buildBottomSection(
              context: context,
              theme: theme,
              l10n: l10n,
              icon: LucideIcons.messageCircle,
              label: 'المحادثة',
              badgeCount: 3,
              onTap: () => _showComingSoon(context, l10n),
            ),
          ),

          const SizedBox(width: 16),

          // Challenges section
          Expanded(
            child: _buildBottomSection(
              context: context,
              theme: theme,
              l10n: l10n,
              icon: LucideIcons.trophy,
              label: 'التحديات',
              badgeCount: 10,
              onTap: () => _showComingSoon(context, l10n),
            ),
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
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: theme.grey[700],
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Label
            Text(
              label,
              style: TextStyles.caption.copyWith(
                color: theme.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
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
}
