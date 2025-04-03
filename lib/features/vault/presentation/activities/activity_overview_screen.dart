import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_details_provider.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_notifier.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/shared_widgets/task_widget.dart';

class ActivityOverviewScreen extends ConsumerWidget {
  const ActivityOverviewScreen(this.activityId, {super.key});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final activityState = ref.watch(activityDetailsProvider(activityId));

    return activityState.when(
      data: (activity) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: plainAppBar(context, ref, activity.name, false, true),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ActivityDescriptionWidget(activity: activity),
                  verticalSpace(Spacing.points16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('activity-tasks'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: activity.tasks.length,
                        separatorBuilder: (_, __) =>
                            verticalSpace(Spacing.points8),
                        itemBuilder: (context, index) => TaskWidget(
                          activity.tasks[index],
                        ),
                      ),
                      verticalSpace(Spacing.points16),
                    ],
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return AddTheActivitySheet(activityId);
                        },
                      );
                    },
                    child: WidgetsContainer(
                      backgroundColor: theme.primary[600],
                      borderSide:
                          BorderSide(color: theme.grey[600]!, width: 0.5),
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('add-the-activity'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[50],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}

class ActivityDescriptionWidget extends StatelessWidget {
  const ActivityDescriptionWidget({
    required this.activity,
    super.key,
  });

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsContainer(
          backgroundColor: theme.backgroundColor,
          width: MediaQuery.of(context).size.width,
          boxShadow: Shadows.mainShadows,
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
          padding: EdgeInsets.all(16),
          child: Text(
            activity.description,
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
              height: 1.5,
            ),
          ),
        ),
        verticalSpace(Spacing.points16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Icon(LucideIcons.lineChart, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate(activity.difficulty.name),
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.users, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "${activity.subscriberCount} ${AppLocalizations.of(context).translate('subscriber')}",
                  style: TextStyles.small,
                )
              ],
            ),
            Column(
              children: [
                Icon(LucideIcons.calendarRange, color: theme.primary[600]),
                verticalSpace(Spacing.points4),
                Text(
                  "3 ${AppLocalizations.of(context).translate('month')}",
                  style: TextStyles.small,
                )
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class TaskDescriptionSheet extends ConsumerWidget {
  const TaskDescriptionSheet(this.task, {super.key});

  final ActivityTask task;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.name,
                  style: TextStyles.h6.copyWith(color: theme.grey[900])),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),
          Text(task.description,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                height: 1.5,
              )),
          verticalSpace(Spacing.points16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(50, 50, 93, 0.25),
                  blurRadius: 5,
                  spreadRadius: -1,
                  offset: Offset(
                    0,
                    2,
                  ),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  blurRadius: 3,
                  spreadRadius: -1,
                  offset: Offset(
                    0,
                    1,
                  ),
                ),
              ],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate("close"),
                    style: TextStyles.body.copyWith(
                      color: theme.primary[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AddTheActivitySheet extends ConsumerStatefulWidget {
  const AddTheActivitySheet(this.activityId, {super.key});

  final String activityId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AddTheActivitySheetState();
}

class _AddTheActivitySheetState extends ConsumerState<AddTheActivitySheet> {
  final _formKey = GlobalKey<FormState>();

  final activityStartingDateController = TextEditingController();
  DateTime activityStartingDateTime = DateTime.now();
  final activityEndingDateController = TextEditingController();
  late DateTime activityEndingDateTime;

  bool nowIsStartingDate = false;

  Future<void> _selectActivityStartingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
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
          nowIsStartingDate = false;
          activityStartingDateController.text = pickedStarting.displayDateTime;
          activityStartingDateTime = pickedStarting.date;
        });
      }
    }
  }

  Future<void> _selectActivityEndingDate(
      BuildContext context, String language) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: activityStartingDateTime,
      lastDate: activityStartingDateTime.add(Duration(days: 90)),
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

  Future<void> _handleSubscribe() async {
    if (!_formKey.currentState!.validate() ||
        activityEndingDateController.text.isEmpty ||
        activityStartingDateController.text.isEmpty) {
      getErrorSnackBar(context, "please-add-all-required-data");
    } else {
      try {
        await ref.read(activityNotifierProvider.notifier).subscribeToActivity(
              widget.activityId,
              activityStartingDateTime,
              activityEndingDateTime,
            );

        if (context.mounted) {
          context.goNamed(RouteNames.activities.name);
        }
      } catch (e) {
        if (context.mounted) {
          getErrorSnackBar(context, e.toString());
        }
      }
    }
  }

  void _handlePeriodSelection(int days) {
    if (activityStartingDateTime == DateTime(1900)) {
      getErrorSnackBar(context, 'please-select-starting-date-first');
      return;
    }

    final endDate = activityStartingDateTime.add(Duration(days: days));
    final displayEndDate = DisplayDateTime(
        endDate, ref.read(localeNotifierProvider)!.languageCode);

    setState(() {
      activityEndingDateController.text = displayEndDate.displayDateTime;
      activityEndingDateTime = displayEndDate.date;
    });
  }

  @override
  void initState() {
    super.initState();
    activityStartingDateTime = DateTime.now();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).translate('activity-period'),
                    style: TextStyles.h6.copyWith(color: theme.grey[900])),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(LucideIcons.xCircle, color: theme.grey[900]),
                )
              ],
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
                      ;
                    }
                    return null;
                  },
                ),
              ),
            ),
            verticalSpace(Spacing.points8),
            WidgetsContainer(
              backgroundColor: theme.backgroundColor,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(50, 50, 93, 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: Offset(
                    0,
                    6,
                  ),
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                  blurRadius: 7,
                  spreadRadius: -3,
                  offset: Offset(
                    0,
                    3,
                  ),
                ),
              ],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.bell),
                      horizontalSpace(Spacing.points16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('start-from-today'),
                            style: TextStyles.footnote.copyWith(
                              color: theme.grey[900],
                            ),
                          ),
                          verticalSpace(Spacing.points4),
                          if (nowIsStartingDate)
                            Text(
                              getDisplayDateTime(
                                  DateTime.now(), locale!.languageCode),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: nowIsStartingDate,
                    activeColor: theme.primary[600],
                    onChanged: (bool value) {
                      setState(() {
                        nowIsStartingDate = value;
                        if (nowIsStartingDate) {
                          final selectedStartingDateDisplay = DisplayDateTime(
                              DateTime.now(), locale!.languageCode);
                          activityStartingDateController.text =
                              selectedStartingDateDisplay.displayDateTime;
                          activityStartingDateTime =
                              selectedStartingDateDisplay.date;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points16),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).translate('activity-period') +
                      ": ",
                  style: TextStyles.smallBold.copyWith(color: theme.grey[900]),
                ),
                PeriodWidget(
                  periodText: '7-days',
                  onTap: () => _handlePeriodSelection(7),
                ),
                horizontalSpace(Spacing.points8),
                PeriodWidget(
                  periodText: '28-days',
                  onTap: () => _handlePeriodSelection(28),
                ),
                horizontalSpace(Spacing.points8),
                PeriodWidget(
                  periodText: '90-days',
                  onTap: () => _handlePeriodSelection(90),
                ),
              ],
            ),
            verticalSpace(Spacing.points16),
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
              onTap: _handleSubscribe,
              child: WidgetsContainer(
                backgroundColor: theme.primary[600],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('add-the-activity'),
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

class PeriodWidget extends ConsumerWidget {
  const PeriodWidget({
    super.key,
    required this.periodText,
    required this.onTap,
  });

  final String periodText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        padding: EdgeInsets.all(8),
        backgroundColor: theme.backgroundColor,
        boxShadow: Shadows.mainShadows,
        borderSide: BorderSide(
          color: theme.grey[600]!,
          width: 0.5,
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate(periodText),
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
            ),
          ),
        ),
      ),
    );
  }
}
