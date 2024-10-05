import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity_task.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activity_overview_screen.dart';

class TaskWidget extends ConsumerWidget {
  const TaskWidget(this.task, {super.key});
  final ActivityTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);

    return WidgetsContainer(
      padding: EdgeInsets.all(16),
      backgroundColor: theme.backgroundColor,
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
        children: [
          Text(
            task.id,
            style: TextStyles.h6.copyWith(color: theme.grey[900], fontSize: 18),
          ),
          horizontalSpace(Spacing.points12),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.taskName,
                style: TextStyles.body.copyWith(color: theme.grey[900]),
              ),
              // verticalSpace(Spacing.points4),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return TaskDescriptionSheet(task);
                  });
            },
            child: Icon(LucideIcons.info, color: theme.primary[900]),
          )
        ],
      ),
    );
  }
}
