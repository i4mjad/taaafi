import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';

class AccountActionBanner extends ConsumerWidget {
  const AccountActionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountStatus = ref.watch(accountStatusProvider);
    final theme = AppTheme.of(context);

    if (accountStatus == AccountStatus.ok ||
        accountStatus == AccountStatus.loading) {
      return const SizedBox.shrink();
    }

    String messageKey;
    String routeName;

    switch (accountStatus) {
      case AccountStatus.loading:
      case AccountStatus.ok:
        return const SizedBox.shrink();
      case AccountStatus.needCompleteRegistration:
        messageKey = 'complete-registration-banner';
        routeName = '/completeAccountRegisteration';
        break;
      case AccountStatus.needConfirmDetails:
        messageKey = 'confirm-details-banner';
        routeName = '/confirmProfileDetails';
        break;
      case AccountStatus.needEmailVerification:
        messageKey = 'confirm-email-banner';
        routeName = '/confirmUserEmail';
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.error[50],
        border: Border.all(color: theme.error[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: theme.error[600],
            size: 24,
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate(messageKey),
                  style: TextStyles.footnote.copyWith(
                    color: theme.error[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          horizontalSpace(Spacing.points12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go(routeName);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.error[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).translate('take-action'),
                style: TextStyles.small.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
