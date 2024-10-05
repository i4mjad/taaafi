import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/models/emotion.dart';
import 'package:reboot_app_3/features/home/data/models/follow_up_option.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/emotion_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_widget.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

class FollowUpSheet extends ConsumerStatefulWidget {
  FollowUpSheet(this.date, {super.key});

  final DateTime date;
  @override
  _FollowUpSheetState createState() => _FollowUpSheetState();
}

class _FollowUpSheetState extends ConsumerState<FollowUpSheet> {
  Set<FollowUpOption> selectedFollowUps = {};
  Set<Emotion> selectedEmotions = {};

  final List<FollowUpOption> followUpOptions = [
    FollowUpOption(icon: LucideIcons.planeLanding, translationKey: 'slip-up'),
    FollowUpOption(icon: LucideIcons.heartCrack, translationKey: 'relapse'),
    FollowUpOption(icon: LucideIcons.play, translationKey: 'porn-only'),
    FollowUpOption(icon: LucideIcons.hand, translationKey: 'mast-only'),
  ];

  void toggleFollowUp(FollowUpOption followUpOption) {
    setState(() {
      if (selectedFollowUps.contains(followUpOption)) {
        selectedFollowUps.remove(followUpOption);
      } else {
        selectedFollowUps.add(followUpOption);
      }
    });
    HapticFeedback.selectionClick(); // Haptic feedback on selection
  }

  void toggleEmotion(Emotion emotion) {
    setState(() {
      if (selectedEmotions.contains(emotion)) {
        selectedEmotions.remove(emotion);
      } else {
        selectedEmotions.add(emotion);
      }
    });
    HapticFeedback.selectionClick(); // Haptic feedback on selection
  }

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
                initTime: widget.date,
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
          // Display follow-up options using FollowUpWidget
          Container(
            height: 80,
            width: MediaQuery.of(context).size.width - 32,
            // (4 * (followUpOptions.length - 1)),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: followUpOptions.length,
              separatorBuilder: (BuildContext context, int index) =>
                  horizontalSpace(Spacing.points4),
              itemBuilder: (BuildContext context, int index) {
                final followUp = followUpOptions[index];
                final isSelected = selectedFollowUps.contains(followUp);

                return GestureDetector(
                  onTap: () => toggleFollowUp(followUp),
                  child: Container(
                    padding: EdgeInsets.all(1),
                    width: MediaQuery.of(context).size.width / 3.5,
                    child: FollowUpWidget(
                      icon: followUp.icon,
                      translationKey: followUp.translationKey,
                      isSelected: isSelected,
                    ),
                  ),
                );
              },
            ),
          ),

          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('how-do-you-feel'),
            style: TextStyles.h6,
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('negative-feelings'),
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[700],
            ),
          ),
          verticalSpace(Spacing.points4),
          Container(
            height: 80,
            width: MediaQuery.of(context).size.width - 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badEmotions.length,
              separatorBuilder: (BuildContext context, int index) =>
                  horizontalSpace(Spacing.points4),
              itemBuilder: (BuildContext context, int index) {
                final emotion = badEmotions[index];
                final isSelected = selectedEmotions.contains(emotion);

                return GestureDetector(
                  onTap: () => toggleEmotion(emotion),
                  child: SizedBox(
                    width: 100,
                    child: Padding(
                      padding: EdgeInsets.all(1),
                      child: EmotionWidget(
                        emotionEmoji: emotion.emotionEmoji,
                        emotionNameTranslationKey:
                            emotion.emotionNameTranslationKey,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          verticalSpace(Spacing.points16),
          Text(
            AppLocalizations.of(context).translate('positive-feelings'),
            style: TextStyles.footnoteSelected.copyWith(
              color: theme.grey[700],
            ),
          ),
          verticalSpace(Spacing.points4),
          Container(
            height: 80,
            width: MediaQuery.of(context).size.width - 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: goodEmotions.length,
              separatorBuilder: (BuildContext context, int index) =>
                  horizontalSpace(Spacing.points4),
              itemBuilder: (BuildContext context, int index) {
                final emotion = goodEmotions[index];
                final isSelected = selectedEmotions.contains(emotion);

                return GestureDetector(
                  onTap: () => toggleEmotion(emotion),
                  child: SizedBox(
                    width: 100,
                    child: Padding(
                      padding: EdgeInsets.all(1),
                      child: EmotionWidget(
                        emotionEmoji: emotion.emotionEmoji,
                        emotionNameTranslationKey:
                            emotion.emotionNameTranslationKey,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    print("Selected FollowUps: $selectedFollowUps");
                    print("Selected Emotions: $selectedEmotions");
                  },
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
