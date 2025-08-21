import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class GroupChatSettingsScreen extends ConsumerWidget {
  const GroupChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "chat-settings", false, true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: theme.grey[400],
            ),
            verticalSpace(Spacing.points16),
            Text(
              l10n.translate('coming-soon'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[600],
              ),
            ),
            verticalSpace(Spacing.points8),
            Text(
              l10n.translate('chat-settings-coming-soon-desc'),
              style: TextStyles.body.copyWith(
                color: theme.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
