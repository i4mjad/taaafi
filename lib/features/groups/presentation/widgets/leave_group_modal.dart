import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

class LeaveGroupModal extends StatelessWidget {
  final VoidCallback onLeaveGroup;

  const LeaveGroupModal({
    super.key,
    required this.onLeaveGroup,
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

          // Header with title and close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.grey[600],
                    ),
                  ),
                ),

                const Spacer(),

                // Title
                Text(
                  l10n.translate('leave-group'),
                  style: TextStyles.h4.copyWith(
                    color: theme.error[600],
                  ),
                ),

                const Spacer(),

                // Spacer to balance the close button
                const SizedBox(width: 28),
              ],
            ),
          ),

          // Warning items list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.messageCircle,
                  text: l10n.translate('leave-group-warning-messages'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.trophy,
                  text: l10n.translate('leave-group-warning-challenges'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.layers,
                  text: l10n.translate('leave-group-warning-updates'),
                ),

                verticalSpace(Spacing.points12),

                _buildWarningItem(
                  context: context,
                  theme: theme,
                  l10n: l10n,
                  icon: LucideIcons.shield,
                  text: l10n.translate('leave-group-warning-privacy'),
                ),

                verticalSpace(Spacing.points20),

                // 24-hour restriction warning
                WidgetsContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: theme.error[50],
                  borderSide: BorderSide(
                    color: theme.error[200]!,
                    width: 1,
                  ),
                  child: Text(
                    l10n.translate('leave-group-24hour-restriction'),
                    style: TextStyles.h6.copyWith(
                      color: theme.error[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Leave Group button (destructive)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onLeaveGroup();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.error[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.translate('leave-group'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[50],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                verticalSpace(Spacing.points8),

                // Close button (cancel)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      l10n.translate('close'),
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding for safe area
          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }

  Widget _buildWarningItem({
    required BuildContext context,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        WidgetsContainer(
          padding: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.error[400]!,
            width: 1,
          ),
          backgroundColor: theme.error[100],
          child: Icon(
            icon,
            // size: 14,
            color: theme.error[600],
          ),
        ),

        horizontalSpace(Spacing.points12),

        // Text
        Expanded(
          child: Text(
            text,
            style: TextStyles.footnoteSelected
                .copyWith(color: theme.grey[900], height: 1.4),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Show the leave group modal
  static void show(
    BuildContext context, {
    required VoidCallback onLeaveGroup,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.of(context).backgroundColor,
      builder: (context) => LeaveGroupModal(
        onLeaveGroup: onLeaveGroup,
      ),
    );
  }
}
