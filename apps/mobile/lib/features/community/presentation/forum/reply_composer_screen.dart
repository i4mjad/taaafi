import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class ReplyComposerScreen extends ConsumerWidget {
  final String postId;
  final String parentId;

  const ReplyComposerScreen({
    super.key,
    required this.postId,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('reply')),
        backgroundColor: theme.backgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.reply,
              size: 64,
              color: theme.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Reply Composer Screen',
              style: TextStyles.h4,
            ),
            const SizedBox(height: 8),
            Text(
              'Post: $postId\nParent: $parentId',
              style: TextStyles.body.copyWith(color: theme.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
