import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activities_notifier.dart';
import 'package:reboot_app_3/features/vault/application/activities/today_tasks_notifier.dart';

class UpdateOngoingActivitySheet extends ConsumerStatefulWidget {
  const UpdateOngoingActivitySheet(this.ongoingActivityId, {super.key});

  final String ongoingActivityId;

  @override
  ConsumerState<UpdateOngoingActivitySheet> createState() =>
      _UpdateOngoingActivitySheetState();
}

class _UpdateOngoingActivitySheetState
    extends ConsumerState<UpdateOngoingActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final activityStartingDateController = TextEditingController();
  final activityEndingDateController = TextEditingController();
  DateTime activityNewStartingDateTime = DateTime.now();
  DateTime activityNewEndingDateTime = DateTime.now().add(Duration(days: 7));
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultDates();
  }

  void _initializeDefaultDates() {
    final locale = ref.read(localeNotifierProvider)?.languageCode ?? 'en';
    final now = DateTime.now();
    final sevenDaysLater = now.add(Duration(days: 7));

    setState(() {
      activityNewStartingDateTime = now;
      activityNewEndingDateTime = sevenDaysLater;
      activityStartingDateController.text = getDisplayDateTime(now, locale);
      activityEndingDateController.text =
          getDisplayDateTime(sevenDaysLater, locale);
    });
  }

  Future<void> _selectActivityStartingDate(
      BuildContext context, String language) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: activityNewStartingDateTime.isBefore(today)
          ? today
          : activityNewStartingDateTime,
      firstDate: today,
      lastDate: today.add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(activityNewStartingDateTime),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Ensure the selected date is not before today
        if (pickedDateTime.isBefore(today)) {
          getErrorSnackBar(
              context, 'activity-start-date-cannot-be-before-today');
          return;
        }

        var pickedStarting = DisplayDateTime(pickedDateTime, language);
        setState(() {
          activityStartingDateController.text = pickedStarting.displayDateTime;
          activityNewStartingDateTime = pickedStarting.date;
        });
      }
    }
  }

  Future<void> _selectActivityEndingDate(
      BuildContext context, String language) async {
    final now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: activityNewEndingDateTime.isBefore(now)
          ? now
          : activityNewEndingDateTime,
      firstDate: activityNewStartingDateTime.isBefore(now)
          ? now
          : activityNewStartingDateTime,
      lastDate: (activityNewStartingDateTime).add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(activityNewEndingDateTime),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (activityNewStartingDateTime != null &&
            pickedDateTime.difference(activityNewStartingDateTime).inDays >
                90) {
          getErrorSnackBar(context, 'activity-period-is-not-valid');
          return;
        } else {
          var pickedEnding = DisplayDateTime(pickedDateTime, language);
          setState(() {
            activityEndingDateController.text = pickedEnding.displayDateTime;
            activityNewEndingDateTime = pickedEnding.date;
          });
        }
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      getErrorSnackBar(context, "please-add-all-required-data");
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Validate that the new start date is not before today
    if (activityNewStartingDateTime.isBefore(today)) {
      getErrorSnackBar(context, 'activity-start-date-cannot-be-before-today');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(ongoingActivityDetailsNotifierProvider(widget.ongoingActivityId)
              .notifier)
          .updateActivityDates(
              activityNewStartingDateTime, activityNewEndingDateTime);

      if (mounted) {
        // Refresh all relevant providers
        await Future.wait([
          ref.refresh(
              ongoingActivityDetailsNotifierProvider(widget.ongoingActivityId)
                  .future),
          ref.refresh(ongoingActivitiesNotifierProvider.future),
        ]);
        ref.refresh(todayTasksProvider);
        ref.refresh(todayTasksStreamProvider);

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, 'error-updating-activity');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    activityStartingDateController.dispose();
    activityEndingDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final activityState = ref.watch(
        ongoingActivityDetailsNotifierProvider(widget.ongoingActivityId));

    return activityState.when(
      data: (details) {
        return Form(
          key: _formKey,
          child: Container(
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
                    Text(
                      AppLocalizations.of(context)
                          .translate('update-activity-dates'),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(LucideIcons.xCircle, color: theme.grey[900]),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context)
                      .translate('update-activity-warning'),
                  style: TextStyles.body.copyWith(
                    color: theme.warn[700],
                    height: 1.3,
                  ),
                ),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context).translate('current-dates'),
                  style: TextStyles.footnoteSelected.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points8),
                WidgetsContainer(
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.grey[300]!, width: 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                color: theme.grey[600],
                                size: 16,
                              ),
                              horizontalSpace(Spacing.points4),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('activity-starting-date'),
                                style: TextStyles.small.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ],
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            getDisplayDateTime(
                                details.startDate, locale!.languageCode),
                            style: TextStyles.small.copyWith(
                              color: theme.grey[900],
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: theme.grey[300],
                        thickness: 0.5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                color: theme.grey[600],
                                size: 16,
                              ),
                              horizontalSpace(Spacing.points4),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('activity-ending-date'),
                                style: TextStyles.small.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ],
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            getDisplayDateTime(
                                details.endDate, locale.languageCode),
                            style: TextStyles.small.copyWith(
                              color: theme.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                verticalSpace(Spacing.points16),
                Text(
                  AppLocalizations.of(context).translate('new-dates'),
                  style: TextStyles.h6.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                verticalSpace(Spacing.points8),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _selectActivityStartingDate(
                          context, locale.languageCode),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: activityStartingDateController,
                          hint: AppLocalizations.of(context)
                              .translate('activity-starting-date'),
                          prefixIcon: LucideIcons.calendar,
                          inputType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please-enter-a-starting-date');
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    verticalSpace(Spacing.points8),
                    GestureDetector(
                      onTap: () => _selectActivityEndingDate(
                          context, locale.languageCode),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: activityEndingDateController,
                          hint: AppLocalizations.of(context)
                              .translate('activity-ending-date'),
                          prefixIcon: LucideIcons.calendar,
                          inputType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please-enter-an-ending-date');
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(Spacing.points16),
                GestureDetector(
                  onTap: _isProcessing ? null : _handleUpdate,
                  child: WidgetsContainer(
                    backgroundColor:
                        _isProcessing ? theme.grey[400] : theme.primary[600],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isProcessing) ...[
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: Spinner(
                              strokeWidth: 2,
                              valueColor: theme.grey[50],
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate('saving'),
                            style: TextStyles.body.copyWith(
                              color: theme.grey[50],
                            ),
                          ),
                        ] else
                          Text(
                            AppLocalizations.of(context).translate('update'),
                            style: TextStyles.body.copyWith(
                              color: theme.grey[50],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: Spinner()),
      error: (error, stack) => Center(
        child: Text(
          AppLocalizations.of(context).translate('error-loading-activity'),
          style: TextStyles.body.copyWith(color: theme.error[600]),
        ),
      ),
    );
  }
}
