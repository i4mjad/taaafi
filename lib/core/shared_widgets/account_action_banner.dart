import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/pending_deletion_banner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';

class AccountActionBanner extends ConsumerWidget {
  const AccountActionBanner({
    this.isFullScreen = false,
    super.key,
  });

  final bool isFullScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountStatus = ref.watch(accountStatusProvider);
    final theme = AppTheme.of(context);

    // Don't show banner if account is OK or still loading
    if (accountStatus == AccountStatus.ok ||
        accountStatus == AccountStatus.loading) {
      return const SizedBox.shrink();
    }

    // Handle pending deletion with specialized banner
    if (accountStatus == AccountStatus.pendingDeletion) {
      return PendingDeletionBanner(isFullScreen: isFullScreen);
    }

    final bannerData = _getBannerData(accountStatus);
    if (bannerData == null) return const SizedBox.shrink();

    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide: isFullScreen
          ? BorderSide.none
          : BorderSide(color: theme.error[200]!, width: 1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  bannerData.icon,
                  color: bannerData.iconColor(theme),
                  size: 24,
                ),
                horizontalSpace(Spacing.points12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate(bannerData.messageKey),
                        style: TextStyles.footnote.copyWith(
                          color: bannerData.textColor(theme),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (bannerData.subtitleKey != null) ...[
                        verticalSpace(Spacing.points4),
                        Text(
                          AppLocalizations.of(context)
                              .translate(bannerData.subtitleKey!),
                          style: TextStyles.small.copyWith(
                            color: theme.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.goNamed(bannerData.routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bannerData.buttonColor(theme),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)
                      .translate(bannerData.buttonTextKey),
                  style: TextStyles.footnote.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BannerData? _getBannerData(AccountStatus status) {
    switch (status) {
      case AccountStatus.needCompleteRegistration:
        return _BannerData(
          messageKey: 'account-setup-needed',
          subtitleKey: 'account-setup-needed-subtitle',
          buttonTextKey: 'setup-account',
          routeName: RouteNames.completeAccountRegisteration.name,
          icon: LucideIcons.userPlus,
          iconColor: (theme) => theme.warn[600]!,
          textColor: (theme) => theme.warn[800]!,
          buttonColor: (theme) => theme.warn[600]!,
        );

      case AccountStatus.needConfirmDetails:
        return _BannerData(
          messageKey: 'profile-incomplete',
          subtitleKey: 'profile-incomplete-subtitle',
          buttonTextKey: 'complete-profile',
          routeName: RouteNames.confirmUserDetails.name,
          icon: LucideIcons.alertCircle,
          iconColor: (theme) => theme.error[600]!,
          textColor: (theme) => theme.error[800]!,
          buttonColor: (theme) => theme.error[600]!,
        );

      case AccountStatus.needEmailVerification:
        return _BannerData(
          messageKey: 'email-verification-needed',
          subtitleKey: 'email-verification-needed-subtitle',
          buttonTextKey: 'verify-email',
          routeName: RouteNames.confirmUserEmail.name,
          icon: LucideIcons.mail,
          iconColor: (theme) => theme.primary[600]!,
          textColor: (theme) => theme.primary[800]!,
          buttonColor: (theme) => theme.primary[600]!,
        );

      case AccountStatus.loading:
      case AccountStatus.ok:
      case AccountStatus.pendingDeletion:
        return null;
    }
  }
}

class _BannerData {
  final String messageKey;
  final String? subtitleKey;
  final String buttonTextKey;
  final String routeName;
  final IconData icon;
  final Color Function(dynamic theme) iconColor;
  final Color Function(dynamic theme) textColor;
  final Color Function(dynamic theme) buttonColor;

  const _BannerData({
    required this.messageKey,
    this.subtitleKey,
    required this.buttonTextKey,
    required this.routeName,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.buttonColor,
  });
}
