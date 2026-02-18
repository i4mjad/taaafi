import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// A reusable confirmation bottom sheet that follows the app's design system
/// 
/// Example usage:
/// ```dart
/// final confirmed = await showConfirmationSheet(
///   context: context,
///   title: 'Delete Item',
///   message: 'Are you sure you want to delete this item?',
///   confirmText: 'Delete',
///   cancelText: 'Cancel',
///   isDestructive: true,
/// );
/// 
/// if (confirmed == true) {
///   // User confirmed
/// }
/// ```
class ConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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

            verticalSpace(Spacing.points24),

            // Icon (if provided)
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDestructive ? theme.error[50] : theme.primary[50],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? theme.error[600] : theme.primary[600],
                  size: 28,
                ),
              ),
              verticalSpace(Spacing.points16),
            ],

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            verticalSpace(Spacing.points12),

            // Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            verticalSpace(Spacing.points32),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Confirm Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: WidgetsContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDestructive 
                          ? theme.error[600]
                          : theme.primary[600],
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: TextStyles.footnote.copyWith(
                            color: theme.backgroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  verticalSpace(Spacing.points12),

                  // Cancel Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: WidgetsContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.backgroundColor,
                      borderSide: BorderSide(color: theme.grey[300]!, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          cancelText,
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show confirmation sheet
/// 
/// Returns `true` if user confirmed, `false` if cancelled, `null` if dismissed
Future<bool?> showConfirmationSheet({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
  IconData? icon,
}) {
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ConfirmationSheet(
      title: title,
      message: message,
      confirmText: confirmText ?? l10n.translate('confirm'),
      cancelText: cancelText ?? l10n.translate('cancel'),
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

