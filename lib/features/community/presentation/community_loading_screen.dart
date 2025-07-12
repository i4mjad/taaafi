import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CommunityLoadingScreen extends ConsumerWidget {
  const CommunityLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'asset/illustrations/community-animation.json',
              height: 150,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('community-profile-created'),
              textAlign: TextAlign.center,
              style: TextStyles.h4.copyWith(
                color: theme.primary[700],
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.translate('loading'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
