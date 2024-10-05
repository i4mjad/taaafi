import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

class DiarySettingsSheet extends ConsumerStatefulWidget {
  const DiarySettingsSheet(this.diary, {super.key});

  final Diary diary;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DiarySettingsSheetState();
}

class _DiarySettingsSheetState extends ConsumerState<DiarySettingsSheet> {
  late TextEditingController _titleController;

  late TextEditingController _diaryDateTimeController;
  late DateTime diaryDateTime = DateTime(2010, 1, 1);

  Future<void> _selectDiaryDateTime(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        var pickedStarting = DisplayDateTime(pickedDateTime, language);
        setState(() {
          _diaryDateTimeController.text = pickedStarting.displayDateTime;
          diaryDateTime = pickedStarting.date;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.diary.title);
    _diaryDateTimeController =
        TextEditingController(text: widget.diary.date.toString());

// TODO: this is a temporarly way of formating the date, it should be formated when the actual date comes from the server
    _diaryDateTimeController = TextEditingController(
        text: DateFormat('d - MMMM - yyyy hh:mm a').format(widget.diary.date));

    diaryDateTime = widget.diary.date;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    var records = [
      ActivityTask("1", 'كتابة اليوميات', "تدوين الرحلة", "1", true,
          DateTime(2024, 5, 2), ""),
      ActivityTask("2", 'كتابة اليوميات', "تدوين الرحلة", "12", false,
          DateTime(2024, 5, 2), ""),
      ActivityTask("3", 'كتابة اليوميات', "تدوين الرحلة", "134", false,
          DateTime(2024, 5, 2), ""),
    ];
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
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate('diary-settings'),
                  style: TextStyles.h6,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          CustomTextField(
            validator: (text) {
              return null;
            },
            controller: _titleController,
            prefixIcon: LucideIcons.text,
            inputType: TextInputType.name,
            hint: AppLocalizations.of(context).translate('title'),
          ),
          verticalSpace(Spacing.points12),
          GestureDetector(
            onTap: () => _selectDiaryDateTime(context, locale!.languageCode),
            child: AbsorbPointer(
              child: CustomTextField(
                controller: _diaryDateTimeController,
                hint: AppLocalizations.of(context).translate('date'),
                prefixIcon: LucideIcons.calendar,
                inputType: TextInputType.datetime,
                validator: (value) {
                  return null;
                },
              ),
            ),
          ),
          verticalSpace(Spacing.points12),
          Text(
            AppLocalizations.of(context).translate('linked-activities'),
            style: TextStyles.footnote,
          ),
          verticalSpace(Spacing.points4),
          Text(
            getDisplayDate(diaryDateTime, locale!.languageCode),
            style: TextStyles.small.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points8),
          Builder(builder: (BuildContext context) {
            final noData = false;
            // ignore: dead_code
            if (noData) {
              return Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('no-notes'),
                          style: TextStyles.footnote,
                        )
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points12),
                  WidgetsContainer(
                    backgroundColor: theme.tint[100],
                    borderSide: BorderSide(color: theme.tint[100]!),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('add-note'),
                        style: TextStyles.h6.copyWith(color: theme.tint[900]),
                      ),
                    ),
                  ),
                ],
              );
              // ignore: dead_code
            } else {
              return ListView.separated(
                shrinkWrap:
                    true, // This makes the ListView take up only the needed space
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return DayActivityWidget(
                    records[index],
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    verticalSpace(Spacing.points8),
                itemCount: records.length,
              );
            }
          }),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    getSuccessSnackBar(context, "changes-has-been-saved");
                    Navigator.pop(context);
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

class DayActivityWidget extends ConsumerStatefulWidget {
  const DayActivityWidget(this.dailyRecord, {super.key});
  final ActivityTask dailyRecord;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DayActivityWidgetState();
}

class _DayActivityWidgetState extends ConsumerState<DayActivityWidget> {
  bool isLinkedToADiary = false;

  @override
  void initState() {
    super.initState();
    isLinkedToADiary = widget.dailyRecord.isLinkedToADiary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return WidgetsContainer(
      padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
      borderRadius: BorderRadius.circular(10.5),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.dailyRecord.id,
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dailyRecord.taskName,
                style: TextStyles.body.copyWith(color: theme.grey[900]),
              ),
              // verticalSpace(Spacing.points4),
              Text(
                widget.dailyRecord.activityName,
                style: TextStyles.small.copyWith(color: theme.grey[600]),
              ),
            ],
          ),
          Spacer(),
          Checkbox(
            value: isLinkedToADiary,
            checkColor: theme.grey[50],
            activeColor: theme.success[600],
            onChanged: (value) {
              setState(() {
                isLinkedToADiary = !isLinkedToADiary;
              });
            },
          ),
        ],
      ),
    );
  }
}
