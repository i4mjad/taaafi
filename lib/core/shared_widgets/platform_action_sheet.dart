import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// Platform-specific popup menu button that shows context menu on iOS
/// and PopupMenuButton on Android
class PlatformPopupMenu extends StatelessWidget {
  final List<PlatformActionItem> items;
  final Widget icon;
  final String? title;
  final String? message;
  final String? cancelLabel;

  const PlatformPopupMenu({
    super.key,
    required this.items,
    required this.icon,
    this.title,
    this.message,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    // Use PopupMenuButton for both platforms but style differently
    return PopupMenuButton<int>(
      icon: icon,
      color: Platform.isIOS ? CupertinoColors.systemBackground : null,
      shape: Platform.isIOS
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      elevation: Platform.isIOS ? 8 : 8,
      offset: Platform.isIOS ? const Offset(0, 45) : const Offset(0, 45),
      itemBuilder: (context) => items
          .asMap()
          .entries
          .map(
            (entry) => PopupMenuItem<int>(
              value: entry.key,
              padding: EdgeInsets.symmetric(
                horizontal: Platform.isIOS ? 12 : 16,
                vertical: Platform.isIOS ? 8 : 12,
              ),
              child: Row(
                children: [
                  if (entry.value.icon != null) ...[
                    Icon(
                      entry.value.icon,
                      size: Platform.isIOS ? 20 : 18,
                      color: entry.value.isDestructive
                          ? (Platform.isIOS
                              ? CupertinoColors.systemRed
                              : theme.error[600])
                          : (Platform.isIOS
                              ? CupertinoColors.label
                              : theme.grey[700]),
                    ),
                    SizedBox(width: Platform.isIOS ? 10 : 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.title,
                          style: TextStyles.body.copyWith(
                            fontSize: Platform.isIOS ? 16 : 16,
                            color: entry.value.isDestructive
                                ? (Platform.isIOS
                                    ? CupertinoColors.systemRed
                                    : theme.error[700])
                                : (Platform.isIOS
                                    ? CupertinoColors.label
                                    : theme.grey[900]),
                          ),
                        ),
                        if (entry.value.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.value.subtitle!,
                            style: TextStyles.caption.copyWith(
                              color: entry.value.isDestructive
                                  ? (Platform.isIOS
                                      ? CupertinoColors.systemRed
                                          .withOpacity(0.7)
                                      : theme.error[600])
                                  : (Platform.isIOS
                                      ? CupertinoColors.secondaryLabel
                                      : theme.grey[600]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onSelected: (index) => items[index].onTap(),
    );
  }
}

/// Platform-specific action sheet that shows CupertinoActionSheet on iOS
/// and Material bottom sheet on Android
class PlatformActionSheet {
  /// Show platform-specific action sheet
  static void show(
    BuildContext context, {
    required List<PlatformActionItem> actions,
    String? title,
    String? message,
    String? cancelLabel,
  }) {
    if (Platform.isIOS) {
      _showIOSActionSheet(
        context,
        actions: actions,
        title: title,
        message: message,
        cancelLabel: cancelLabel,
      );
    } else {
      _showAndroidBottomSheet(
        context,
        actions: actions,
        title: title,
        message: message,
      );
    }
  }

  /// iOS-style CupertinoActionSheet
  static void _showIOSActionSheet(
    BuildContext context, {
    required List<PlatformActionItem> actions,
    String? title,
    String? message,
    String? cancelLabel,
  }) {
    final theme = AppTheme.of(context);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title != null
            ? Text(
                title,
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              )
            : null,
        message: message != null
            ? Text(
                message,
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
              )
            : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              action.onTap();
            },
            isDestructiveAction: action.isDestructive,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(
                    action.icon,
                    size: 20,
                    color: action.isDestructive
                        ? CupertinoColors.systemRed
                        : theme.primary[500],
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  action.title,
                  style: TextStyles.body.copyWith(
                    color: action.isDestructive
                        ? CupertinoColors.systemRed
                        : theme.primary[500],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        cancelButton: cancelLabel != null
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                isDefaultAction: true,
                child: Text(
                  cancelLabel,
                  style: TextStyles.body.copyWith(
                    color: theme.primary[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Android-style Material bottom sheet
  static void _showAndroidBottomSheet(
    BuildContext context, {
    required List<PlatformActionItem> actions,
    String? title,
    String? message,
  }) {
    final theme = AppTheme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Optional message
            if (message != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  message,
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action items
            ...actions.map((action) => _buildAndroidActionItem(
                  context,
                  theme,
                  action,
                  isLast: action == actions.last,
                )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildAndroidActionItem(
    BuildContext context,
    dynamic theme,
    PlatformActionItem action, {
    required bool isLast,
  }) {
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
                if (action.icon != null) ...[
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
                ],
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
                          action.subtitle!,
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
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }
}

/// Data class for platform action items
class PlatformActionItem {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const PlatformActionItem({
    this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });
}
