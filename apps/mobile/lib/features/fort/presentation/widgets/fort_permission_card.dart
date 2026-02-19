import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/fort/data/notifiers/usage_notifier.dart';

class FortPermissionCard extends ConsumerWidget {
  const FortPermissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? theme.grey[700]! : theme.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.primary[800]!.withValues(alpha: 0.3)
                  : theme.primary[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 32,
              color: isDark ? theme.primary[300] : theme.primary[600],
            ),
          ),

          verticalSpace(Spacing.points16),

          // Title
          Text(
            t.translate('fort_permission_title'),
            style: TextStyles.body.copyWith(
              color: isDark ? theme.grey[100] : theme.grey[900],
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          verticalSpace(Spacing.points8),

          // Description
          Text(
            t.translate(Platform.isIOS
                ? 'fort_permission_description_ios'
                : 'fort_permission_description_android'),
            style: TextStyles.footnote.copyWith(
              color: isDark ? theme.grey[400] : theme.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          verticalSpace(Spacing.points24),

          // Enable button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await ref
                    .read(usagePermissionProvider.notifier)
                    .requestPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? theme.primary[600] : theme.primary[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                t.translate('fort_enable_tracking'),
                style: TextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
