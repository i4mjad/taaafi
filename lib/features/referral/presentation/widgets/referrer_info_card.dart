import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/shared_widgets/container.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/theming/text_styles.dart';

class ReferrerInfoCard extends ConsumerWidget {
  final String referrerName;

  const ReferrerInfoCard({
    super.key,
    required this.referrerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return WidgetsContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.primary[50],
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.primary[200]!,
        width: 1,
      ),
      cornerSmoothing: 1,
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.userPlus,
              color: theme.primary[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n
                      .translate('referral.checklist.referred_by')
                      .replaceAll('{name}', referrerName),
                  style: TextStyles.body.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translate('referral.checklist.help_referrer'),
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

