import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/notifications/notifications_scheduler.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/ongoing_activity_details_provider.dart';

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
  late DateTime activityStartingDateTime = DateTime(1900);
  late DateTime activityEndingDateTime = DateTime(1900);

  @override
  void initState() {
    super.initState();
    _loadCurrentDates();
  }

  Future<void> _loadCurrentDates() async {
    final activityDetails = await ref.read(
        ongoingActivityDetailsNotifierProvider(widget.ongoingActivityId)
            .future);
    final locale = ref.read(localeNotifierProvider)?.languageCode ?? 'en';

    setState(() {
      activityStartingDateTime = activityDetails.startDate;
      activityEndingDateTime = activityDetails.endDate;
      activityStartingDateController.text =
          getDisplayDateTime(activityDetails.startDate, locale);
      activityEndingDateController.text =
          getDisplayDateTime(activityDetails.endDate, locale);
    });
  }

  Future<void> _selectActivityStartingDate(
      BuildContext context, String language) async {
    final now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: activityStartingDateTime.isBefore(now)
          ? now
          : activityStartingDateTime,
      firstDate: now,
      lastDate: now.add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(activityStartingDateTime),
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
          activityStartingDateController.text = pickedStarting.displayDateTime;
          activityStartingDateTime = pickedStarting.date;
        });
      }
    }
  }

  Future<void> _selectActivityEndingDate(
      BuildContext context, String language) async {
    final now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          activityEndingDateTime.isBefore(now) ? now : activityEndingDateTime,
      firstDate: activityStartingDateTime.isBefore(now)
          ? now
          : activityStartingDateTime,
      lastDate: activityStartingDateTime.add(Duration(days: 90)),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(activityEndingDateTime),
      );
      if (pickedTime != null) {
        DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (pickedDateTime.difference(activityStartingDateTime).inDays > 90) {
          getErrorSnackBar(context, 'activity-period-is-not-valid');
        } else {
          var pickedEnding = DisplayDateTime(pickedDateTime, language);
          setState(() {
            activityEndingDateController.text = pickedEnding.displayDateTime;
            activityEndingDateTime = pickedEnding.date;
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

    try {
      await ref
          .read(ongoingActivityDetailsNotifierProvider(widget.ongoingActivityId)
              .notifier)
          .updateActivityDates(
              activityStartingDateTime, activityEndingDateTime);

      // if (context.mounted) {
      //   Navigator.pop(context);
      // }

      //TODO: clear the scedhuled notifications for this activity
      await NotificationsScheduler.instance
          .cancelNotificationsForActivity(widget.ongoingActivityId);

      // Navigate using a delayed call to ensure previous operations are complete
      if (context.mounted) {
        Future.microtask(() {
          context.goNamed(
            RouteNames.activities.name,
          );
        });
      }
    } catch (e) {
      if (context.mounted) {
        getErrorSnackBar(context, e.toString());
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
              AppLocalizations.of(context).translate('update-activity-warning'),
              style: TextStyles.body.copyWith(color: theme.warn[700]),
            ),
            verticalSpace(Spacing.points16),
            GestureDetector(
              onTap: () =>
                  _selectActivityStartingDate(context, locale!.languageCode),
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
              onTap: () =>
                  _selectActivityEndingDate(context, locale!.languageCode),
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: activityEndingDateController,
                  hint: AppLocalizations.of(context)
                      .translate('activity-ending-date'),
                  prefixIcon: LucideIcons.calendarRange,
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
            verticalSpace(Spacing.points16),
            GestureDetector(
              onTap: _handleUpdate,
              child: WidgetsContainer(
                backgroundColor: theme.primary[600],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
  }
}
