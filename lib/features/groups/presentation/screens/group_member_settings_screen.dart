import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

/// Model for group member in settings
class GroupMemberSettings {
  final String id;
  final String name;
  final Color avatarColor;
  final DateTime joinDate;
  final bool isSupervisor;

  const GroupMemberSettings({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.joinDate,
    required this.isSupervisor,
  });
}

class GroupMemberSettingsScreen extends ConsumerWidget {
  const GroupMemberSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "member-settings", false, true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: _getDemoMembers().length,
          separatorBuilder: (context, index) => verticalSpace(Spacing.points12),
          itemBuilder: (context, index) {
            final member = _getDemoMembers()[index];
            return _buildMemberCard(context, theme, l10n, member);
          },
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    GroupMemberSettings member,
  ) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Member Info Row
          Row(
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

              horizontalSpace(Spacing.points12),

              // Member Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      member.isSupervisor
                          ? l10n.translate('supervisor')
                          : l10n.translate('member'),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      '${l10n.translate('join-date')}: ${_formatDate(member.joinDate)}',
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Action Buttons
          Row(
            children: [
              // Change Role Button
              Expanded(
                child: _buildActionButton(
                  context: context,
                  theme: theme,
                  label: member.isSupervisor
                      ? l10n.translate('change-to-member')
                      : l10n.translate('change-to-supervisor'),
                  onTap: () => _changeRole(context, l10n, member),
                  isPrimary: false,
                ),
              ),

              horizontalSpace(Spacing.points8),

              // Remove Button
              Expanded(
                child: _buildActionButton(
                  context: context,
                  theme: theme,
                  label: l10n.translate('remove-from-group'),
                  onTap: () => _removeMember(context, l10n, member),
                  isPrimary: false,
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required CustomThemeData theme,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? theme.error[50]
              : isPrimary
                  ? theme.primary[50]
                  : theme.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? theme.error[200]!
                : isPrimary
                    ? theme.primary[200]!
                    : theme.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyles.caption.copyWith(
            color: isDestructive
                ? theme.error[500]
                : isPrimary
                    ? theme.primary[700]
                    : theme.grey[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _changeRole(
      BuildContext context, AppLocalizations l10n, GroupMemberSettings member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('coming-soon'))),
    );
  }

  void _removeMember(
      BuildContext context, AppLocalizations l10n, GroupMemberSettings member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = AppTheme.of(context);

        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            l10n.translate('remove-member-confirm-title'),
            style: TextStyles.h5.copyWith(
              color: theme.grey[900],
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n
                .translate('remove-member-confirm-message')
                .replaceAll('{name}', member.name),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.translate('cancel'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('coming-soon'))),
                );
              },
              child: Text(
                l10n.translate('remove'),
                style: TextStyles.body.copyWith(
                  color: theme.error[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<GroupMemberSettings> _getDemoMembers() {
    return [
      GroupMemberSettings(
        id: '1',
        name: 'سيف حمد',
        avatarColor: Colors.orange,
        joinDate: DateTime(2023, 8, 28),
        isSupervisor: false,
      ),
      GroupMemberSettings(
        id: '2',
        name: 'يوسف يعقوب',
        avatarColor: Colors.blue,
        joinDate: DateTime(2023, 8, 28),
        isSupervisor: true,
      ),
      GroupMemberSettings(
        id: '3',
        name: 'مجهول',
        avatarColor: Colors.purple,
        joinDate: DateTime(2023, 8, 28),
        isSupervisor: false,
      ),
    ];
  }
}
