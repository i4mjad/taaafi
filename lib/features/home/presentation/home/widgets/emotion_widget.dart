import 'package:flutter/cupertino.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class EmotionWidget extends StatelessWidget {
  const EmotionWidget({
    super.key,
    required this.emotionEmoji,
    required this.emotionNameTranslationKey,
    required this.isSelected, // New parameter to indicate selection
  });

  final String emotionEmoji;
  final String emotionNameTranslationKey;
  final bool isSelected; // Whether the emotion is selected or not

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      cornerSmoothing: 1,
      backgroundColor: theme.tint[50],
      borderSide: BorderSide(
        color: isSelected ? theme.success[600]! : theme.tint[400]!,

        // Change border color based on selection
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            emotionEmoji,
            style: TextStyle(fontSize: 22),
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate(emotionNameTranslationKey),
            style: TextStyles.footnote.copyWith(color: theme.tint[900]),
          ),
        ],
      ),
    );
  }
}
