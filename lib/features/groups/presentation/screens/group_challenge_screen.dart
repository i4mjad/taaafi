import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class GroupChallengeScreen extends ConsumerWidget {
  final String groupId;

  const GroupChallengeScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('group_challenge')),
        backgroundColor: theme.backgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Group Challenge Screen',
              style: TextStyles.h4,
            ),
            const SizedBox(height: 8),
            Text(
              'Group ID: $groupId',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
