import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/ongoing_activity_task.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/tasks_by_date_provider.dart';

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
  late DateTime diaryDateTime;
  late Set<String> linkedTaskIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.diary.title);
    diaryDateTime = widget.diary.date;

    final locale = ref.read(localeNotifierProvider)?.languageCode ?? 'en';
    _diaryDateTimeController = TextEditingController(
      text: getDisplayDateTime(widget.diary.date, locale),
    );

    linkedTaskIds = Set.from(widget.diary.linkedTasks.map((task) => task.id));
  }

  Future<void> _saveDiarySettings() async {
    try {
      await ref
          .read(diaryNotifierProvider(widget.diary.id).notifier)
          .updateDiary(
            widget.diary.id,
            Diary(
              widget.diary.id,
              _titleController.text,
              widget.diary.plainText,
              diaryDateTime,
              formattedContent: widget.diary.formattedContent,
              linkedTaskIds: linkedTaskIds.toList(),
              updatedAt: DateTime.now(),
            ),
          );

      if (mounted) {
        getSuccessSnackBar(context, "changes-has-been-saved");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, "error-saving-changes");
      }
    }
  }

  Future<void> _selectDiaryDateTime(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: diaryDateTime,
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

        setState(() {
          diaryDateTime = pickedDateTime;
          _diaryDateTimeController.text =
              getDisplayDateTime(pickedDateTime, language);
          linkedTaskIds.clear();
        });
      }
    }
  }

  void _updateLinkedTask(String taskId, bool isLinked) {
    setState(() {
      if (isLinked) {
        linkedTaskIds.add(taskId);
      } else {
        linkedTaskIds.remove(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final tasksAsync = ref.watch(tasksByDateRangeProvider(
      DateTime(
        diaryDateTime.year,
        diaryDateTime.month,
        diaryDateTime.day,
      ),
      DateTime(
        diaryDateTime.year,
        diaryDateTime.month,
        diaryDateTime.day,
        23,
        59,
        59,
      ),
    ));

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
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
              return tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('no-tasks-for-date'),
                                style: TextStyles.footnote,
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final task = tasks[index];
                      return DayActivityWidget(
                        task,
                        index + 1,
                        isLinked: linkedTaskIds.contains(task.id),
                        onLinkedChanged: (isLinked) =>
                            _updateLinkedTask(task.id, isLinked),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        verticalSpace(Spacing.points8),
                    itemCount: tasks.length,
                  );
                },
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      color: theme.primary[600],
                    ),
                  ),
                ),
                error: (error, stack) => Text('Error: $error'),
              );
            }),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _saveDiarySettings();
                    },
                    child: WidgetsContainer(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: Shadows.mainShadows,
                      backgroundColor: theme.primary[700],
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
                      backgroundColor: theme.backgroundColor,
                      boxShadow: Shadows.mainShadows,
                      borderSide: BorderSide(color: theme.grey[500]!),
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
      ),
    );
  }
}

class DayActivityWidget extends ConsumerStatefulWidget {
  const DayActivityWidget(
    this.task,
    this.index, {
    this.isLinked = false,
    required this.onLinkedChanged,
    super.key,
  });

  final OngoingActivityTask task;
  final bool isLinked;
  final int index;
  final Function(bool) onLinkedChanged;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DayActivityWidgetState();
}

class _DayActivityWidgetState extends ConsumerState<DayActivityWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return WidgetsContainer(
      padding: EdgeInsets.all(8),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
      borderRadius: BorderRadius.circular(10.5),
      boxShadow: Shadows.mainShadows,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.index.toString(),
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.task.name,
                  style: TextStyles.body.copyWith(color: theme.grey[900]),
                ),
                // verticalSpace(Spacing.points4),
                Text(
                  widget.task.task.description,
                  // softWrap: true,
                  style: TextStyles.small.copyWith(color: theme.grey[600]),
                ),
              ],
            ),
          ),
          horizontalSpace(Spacing.points8),
          Checkbox(
            value: widget.isLinked,
            checkColor: theme.grey[50],
            activeColor: theme.success[600],
            onChanged: (value) {
              widget.onLinkedChanged(value ?? false);
            },
          ),
        ],
      ),
    );
  }
}
