import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/activities/activity_notifier.dart';
import 'package:reboot_app_3/features/vault/data/activities/activity.dart';

class AddActivityScreen extends ConsumerWidget {
  const AddActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final activitiesState = ref.watch(activityNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "add-activity", false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: activitiesState.when(
            data: (activities) => ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) => verticalSpace(Spacing.points8),
              itemBuilder: (context, index) => ActivityListItem(
                activity: activities[index],
                onTap: () async {
                  try {
                    final isSubscribed = await ref
                        .read(activityNotifierProvider.notifier)
                        .checkSubscription(activities[index].id);

                    if (context.mounted) {
                      if (isSubscribed) {
                        getErrorSnackBar(
                            context, 'already-subscribed-to-activity');
                      } else {
                        context.goNamed(
                          RouteNames.activityOverview.name,
                          pathParameters: {"id": activities[index].id},
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      getErrorSnackBar(context, e.toString());
                    }
                  }
                },
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(error.toString()),
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityListItem extends StatelessWidget {
  const ActivityListItem({
    required this.activity,
    required this.onTap,
    super.key,
  });

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.barChart,
                        color: theme.primary[700],
                        size: 16,
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        AppLocalizations.of(context)
                            .translate(activity.difficulty.name),
                        style: TextStyles.smallBold.copyWith(
                          color:
                              _getDifficultyColor(activity.difficulty, theme),
                        ),
                      ),
                      horizontalSpace(Spacing.points4),
                      Text("•"),
                      horizontalSpace(Spacing.points4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            color: theme.primary[700],
                            size: 16,
                          ),
                          horizontalSpace(Spacing.points4),
                          Text(
                            activity.subscriberCount.toString(),
                            style: TextStyles.smallBold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty, CustomThemeData theme) {
    switch (difficulty) {
      case Difficulty.easy:
        return theme.success[700]!;
      case Difficulty.medium:
        return theme.warn[500]!;
      case Difficulty.intermediate:
        return theme.error[800]!;
    }
  }
}
