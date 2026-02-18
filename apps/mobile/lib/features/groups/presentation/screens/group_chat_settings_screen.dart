import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/chat_text_size_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

class GroupChatSettingsScreen extends ConsumerWidget {
  const GroupChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentTextSize = ref.watch(chatTextSizeProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "chat-settings", false, true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Size Section
            Text(
              l10n.translate('chat-text-size'),
              style: TextStyles.h6.copyWith(color: theme.grey[900]),
            ),
            verticalSpace(Spacing.points4),
            Text(
              l10n.translate('chat-text-size-description'),
              style: TextStyles.caption.copyWith(color: theme.grey[600]),
            ),
            verticalSpace(Spacing.points16),

            _buildCompactMessagePreview(context, theme, l10n, currentTextSize),

            verticalSpace(Spacing.points16),
            // Compact Text Size Options
            WidgetsContainer(
              padding: const EdgeInsets.all(12),
              backgroundColor: theme.grey[50],
              borderSide: BorderSide(color: theme.grey[200]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  _buildCompactTextSizeOption(
                    context,
                    theme,
                    l10n,
                    ref,
                    ChatTextSize.small,
                    l10n.translate('text-size-small'),
                    currentTextSize,
                  ),
                  Divider(height: 1, color: theme.grey[200]),
                  _buildCompactTextSizeOption(
                    context,
                    theme,
                    l10n,
                    ref,
                    ChatTextSize.medium,
                    l10n.translate('medium'),
                    currentTextSize,
                  ),
                  Divider(height: 1, color: theme.grey[200]),
                  _buildCompactTextSizeOption(
                    context,
                    theme,
                    l10n,
                    ref,
                    ChatTextSize.large,
                    l10n.translate('text-size-large'),
                    currentTextSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextSizeOption(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    WidgetRef ref,
    ChatTextSize textSize,
    String label,
    ChatTextSize currentTextSize,
  ) {
    final isSelected = currentTextSize == textSize;

    return GestureDetector(
      onTap: () {
        ref.read(chatTextSizeProvider.notifier).setTextSize(textSize);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primary[500]! : theme.grey[300]!,
                  width: 2,
                ),
                color: isSelected ? theme.primary[500] : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              'Aa',
              style: textSize.textStyle.copyWith(color: theme.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMessagePreview(
    BuildContext context,
    CustomThemeData theme,
    AppLocalizations l10n,
    ChatTextSize currentTextSize,
  ) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: theme.grey[50],
      borderSide: BorderSide(color: theme.grey[200]!, width: 1),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.primary[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.primary[200]!, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact header
            Row(
              children: [
                Text(
                  l10n.translate('sample-sender-name'),
                  style: TextStyles.smallBold.copyWith(color: theme.grey[900]),
                ),
                const Spacer(),
                Text(
                  '10:30',
                  style: TextStyles.tiny.copyWith(color: theme.grey[300]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Sample message with dynamic text size
            Text(
              l10n.translate('sample-message'),
              style: currentTextSize.textStyle.copyWith(
                color: theme.grey[800],
                height: 1.4,
              ),
              textAlign: Directionality.of(context) == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
