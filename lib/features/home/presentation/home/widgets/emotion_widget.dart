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
    required this.isSelected,
  });

  final String emotionEmoji;
  final String emotionNameTranslationKey;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      cornerSmoothing: 1,
      backgroundColor: theme.backgroundColor,
      padding: EdgeInsets.all(8),
      borderSide: BorderSide(
        color: isSelected ? theme.success[600]! : theme.grey[600]!,
        width: isSelected ? 1 : 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(60, 64, 67, 0.3),
          blurRadius: 2,
          spreadRadius: 0,
          offset: Offset(
            0,
            1,
          ),
        ),
        BoxShadow(
          color: Color.fromRGBO(60, 64, 67, 0.15),
          blurRadius: 6,
          spreadRadius: 2,
          offset: Offset(
            0,
            2,
          ),
        ),
      ],
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
