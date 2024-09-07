import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/models/emotion.dart';
import 'package:reboot_app_3/features/home/presentation/screens/home/widgets/emotion_widget.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

class FollowUpSheet extends ConsumerStatefulWidget {
  const FollowUpSheet({super.key});

  @override
  _FollowUpSheetState createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends ConsumerState<FollowUpSheet> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final theme = AppTheme.of(context);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimePickerSpinnerPopUp(
                mode: CupertinoDatePickerMode.dateAndTime,
                barrierColor: theme.primary[50]!,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                locale: locale,
                cancelTextStyle: TextStyles.caption.copyWith(
                  color: theme.primary[600],
                ),
                confirmTextStyle: TextStyles.caption.copyWith(
                  color: theme.primary[600],
                ),
                timeFormat: "d - MMMM - yyyy hh:mm a",
                timeWidgetBuilder: (dateTime) {
                  return WidgetsContainer(
                    padding: EdgeInsets.all(8),
                    backgroundColor: theme.primary[50],
                    borderSide:
                        BorderSide(color: theme.primary[100]!, width: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      getDisplayDateTime(dateTime, locale!.languageCode),
                      style: TextStyles.body,
                    ),
                  );
                },
                cancelText: AppLocalizations.of(context).translate("cancel"),
                confirmText: AppLocalizations.of(context).translate("confirm"),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('what-you-want-to-add'),
            style: TextStyles.h6,
          ),
          verticalSpace(Spacing.points8),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(color: theme.primary[100]!),
                      child: Column(
                        children: [
                          Icon(LucideIcons.planeLanding),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate('slip-up'),
                            style: TextStyles.footnote,
                          ),
                        ],
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(color: theme.primary[100]!),
                      child: Column(
                        children: [
                          Icon(LucideIcons.heartCrack),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate('relapse'),
                            style: TextStyles.footnote,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points8),
              Row(
                children: [
                  Expanded(
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(color: theme.primary[100]!),
                      child: Column(
                        children: [
                          Icon(LucideIcons.play),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate('porn-only'),
                            style: TextStyles.footnote,
                          ),
                        ],
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points8),
                  Expanded(
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[50],
                      borderSide: BorderSide(color: theme.primary[100]!),
                      child: Column(
                        children: [
                          Icon(LucideIcons.hand),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate('mast-only'),
                            style: TextStyles.footnote,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('how-do-you-feel'),
                style: TextStyles.h6,
              ),
              verticalSpace(Spacing.points8),
              Text("مشاعر سلبية", style: TextStyles.footnoteSelected),
              verticalSpace(Spacing.points4),
              Container(
                height: 80,
                width: MediaQuery.of(context).size.width - 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  itemCount: badEmotions.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      horizontalSpace(Spacing.points4),
                  itemBuilder: (BuildContext context, int index) {
                    final emotion = badEmotions[index];

                    // Use Align to prevent stretching of EmotionWidget
                    return SizedBox(
                      width: 80,
                      child: EmotionWidget(
                        emotionEmoji: emotion.emotionEmoji,
                        emotionNameTranslationKey:
                            emotion.emotionNameTranslationKey,
                      ),
                    );
                  },
                ),
              ),
              verticalSpace(Spacing.points8),
              Text("مشاعر إيجابية", style: TextStyles.footnoteSelected),
              verticalSpace(Spacing.points4),
              Container(
                height: 80,
                width: MediaQuery.of(context).size.width - 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling
                  itemCount: goodEmotions.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      horizontalSpace(Spacing.points4),
                  itemBuilder: (BuildContext context, int index) {
                    final emotion = goodEmotions[index];

                    // Use Align to prevent stretching of EmotionWidget
                    return SizedBox(
                      width: 80,
                      child: EmotionWidget(
                        emotionEmoji: emotion.emotionEmoji,
                        emotionNameTranslationKey:
                            emotion.emotionNameTranslationKey,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: WidgetsContainer(
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: theme.primary[600],
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('save'),
                      style: TextStyles.h6.copyWith(color: theme.grey[50]),
                    ),
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: WidgetsContainer(
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: theme.secondary[50],
                    borderSide: BorderSide(color: theme.secondary[200]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                        style: TextStyles.h6.copyWith(
                          color: theme.secondary[900],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
