import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class CommunityProfileSettingsScreen extends ConsumerWidget {
  const CommunityProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('community_profile')),
        backgroundColor: theme.backgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.user,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Community Profile Settings Screen',
              style: TextStyles.h4,
            ),
          ],
        ),
      ),
    );
  }
}
