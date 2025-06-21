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

/// Banner that asks the user to verify their email address.
class ConfirmEmailBanner extends ConsumerWidget {
  const ConfirmEmailBanner({this.isFullScreen = false, super.key});
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Lottie.asset(
                'asset/illustrations/warning.json',
                height: isFullScreen ? 200 : 100,
              ),
            ),
            verticalSpace(Spacing.points16),
            Text(
              AppLocalizations.of(context).translate('confirm-email-banner'),
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyles.footnote.copyWith(
                color: theme.warn[800],
                height: 1.4,
              ),
            ),
            verticalSpace(Spacing.points16),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed(RouteNames.confirmUserEmail.name);
              },
              child: WidgetsContainer(
                backgroundColor: theme.backgroundColor,
                width: double.infinity,
                borderSide: BorderSide(color: theme.grey[200]!, width: 0.25),
                boxShadow: isFullScreen ? const [] : Shadows.mainShadows,
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).translate('confirm-email'),
                    style: TextStyles.small.copyWith(
                      color: theme.warn[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
