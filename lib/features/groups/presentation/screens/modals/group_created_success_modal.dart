import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class GroupCreatedSuccessModal extends ConsumerWidget {
  final String groupName;
  final String? generatedJoinCode;

  const GroupCreatedSuccessModal({
    super.key,
    required this.groupName,
    this.generatedJoinCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with success icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.success[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.checkCircle,
                  color: theme.success[600],
                  size: 32,
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points20),

          // Success title
          Text(
            l10n.translate('group-created-successfully-title'),
            style: TextStyles.h4.copyWith(
              color: theme.grey[900],
            ),
            textAlign: TextAlign.center,
          ),

          verticalSpace(Spacing.points8),

          // Group name
          Text(
            '"$groupName"',
            style: TextStyles.h5.copyWith(
              color: theme.primary[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          verticalSpace(Spacing.points20),

          // Join code section (if provided)
          if (generatedJoinCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primary[200]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.key,
                        color: theme.primary[600],
                        size: 20,
                      ),
                      horizontalSpace(Spacing.points8),
                      Text(
                        l10n.translate('your-join-code'),
                        style: TextStyles.footnoteSelected.copyWith(
                          color: theme.primary[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  verticalSpace(Spacing.points12),

                  // Join code display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.primary[300]!, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          generatedJoinCode!,
                          style: TextStyles.h3.copyWith(
                            fontFamily: 'monospace',
                            color: theme.grey[900],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  verticalSpace(Spacing.points12),

                  // Copy button
                  GestureDetector(
                    onTap: () =>
                        _copyJoinCode(generatedJoinCode!, context, l10n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary[100],
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: theme.primary[300]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.copy,
                            color: theme.primary[600],
                            size: 16,
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            l10n.translate('copy-code'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.primary[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points24),
          ],

          // Done button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              backgroundColor: theme.primary[600],
              borderRadius: BorderRadius.circular(10.5),
              borderSide: BorderSide.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.translate('got-it'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          verticalSpace(Spacing.points16),
        ],
      ),
    );
  }

  void _copyJoinCode(
      String joinCode, BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: joinCode));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('join-code-copied')),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.of(context).success[600],
      ),
    );
  }
}
