import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// Banner that asks the user to review and confirm missing profile details.
class ConfirmDetailsBanner extends ConsumerWidget {
  const ConfirmDetailsBanner({this.isFullScreen = false, super.key});
  final bool isFullScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      backgroundColor: theme.backgroundColor,
      borderSide:
          isFullScreen ? BorderSide.none : BorderSide(color: theme.grey[50]!),
      boxShadow: isFullScreen ? const [] : Shadows.mainShadows,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'asset/illustrations/error.json',
              height: isFullScreen ? 200 : 100,
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate('confirm-details-banner'),
              textAlign: TextAlign.center,
              style: TextStyles.footnote.copyWith(
                color: theme.error[800],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            verticalSpace(Spacing.points12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed(RouteNames.confirmUserDetails.name);
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                width: double.infinity,
                borderSide: BorderSide(color: theme.grey[200]!, width: 1),
                boxShadow: isFullScreen ? const [] : Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('confirm-user-details'),
                    style: TextStyles.small.copyWith(
                      color: theme.error[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
