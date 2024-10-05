import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';

class DayTaskWidget extends ConsumerStatefulWidget {
  const DayTaskWidget(this.dailyRecord, {super.key});
  final ActivityTask dailyRecord;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DayActivityWidgetState();
}

class _DayActivityWidgetState extends ConsumerState<DayTaskWidget> {
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
      borderSide: BorderSide(
        color: theme.grey[600]!,
        width: 0.25,
      ),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.02),
          blurRadius: 3,
          spreadRadius: 0,
          offset: Offset(
            0,
            1,
          ),
        ),
        BoxShadow(
          color: Color.fromRGBO(27, 31, 35, 0.15),
          blurRadius: 0,
          spreadRadius: 1,
          offset: Offset(
            0,
            0,
          ),
        ),
      ],
      borderRadius: BorderRadius.circular(8),
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
