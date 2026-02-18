import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            // Simple email icon instead of complex animation
            Icon(
              Icons.mark_email_unread_outlined,
              size: isFullScreen ? 64 : 48,
              color: theme.warn[600],
            ),
            verticalSpace(Spacing.points12),
            Text(
              AppLocalizations.of(context).translate('confirm-email-banner'),
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            verticalSpace(Spacing.points16),
            // Simplified button design
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.goNamed(RouteNames.confirmUserEmail.name);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.warn[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).translate('confirm-email'),
                  textAlign: TextAlign.center,
                  style: TextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
