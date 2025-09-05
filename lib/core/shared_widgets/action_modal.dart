import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// Reusable action modal for bottom sheet with list of actions
class ActionModal extends StatelessWidget {
  final List<ActionItem> actions;
  final String? title;

  const ActionModal({
    super.key,
    required this.actions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Optional title
          if (title != null) ...[
            Text(
              title ?? '',
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action items
          ...actions.map((action) => _buildActionItem(context, theme, action)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, dynamic theme, ActionItem action) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            action.onTap();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: action.isDestructive ? theme.error[50] : theme.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.isDestructive
                        ? theme.error[100]
                        : theme.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    action.icon,
                    size: 20,
                    color: action.isDestructive
                        ? theme.error[600]
                        : theme.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: action.isDestructive
                              ? theme.error[700]
                              : theme.grey[900],
                        ),
                      ),
                      if (action.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          action.subtitle ?? '',
                          style: TextStyles.caption.copyWith(
                            color: action.isDestructive
                                ? theme.error[600]
                                : theme.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (actions.last != action) const SizedBox(height: 8),
      ],
    );
  }

  /// Static method to show the action modal
  static void show(
    BuildContext context, {
    required List<ActionItem> actions,
    String? title,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ActionModal(
        actions: actions,
        title: title,
      ),
    );
  }
}

/// Data class for action items
class ActionItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });
}
