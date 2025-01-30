import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calender_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final streaksState = ref.watch(streakNotifierProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, false),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Activities(),
            StatisticsWidget(),
            verticalSpace(Spacing.points16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalenderWidget(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primary[700],
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return FollowUpSheet(DateTime.now());
            },
          );
        },
        label: Text(
          AppLocalizations.of(context).translate("daily-follow-up"),
          style: TextStyles.caption.copyWith(color: theme.grey[50]),
        ),
        icon: Icon(LucideIcons.pencil, color: theme.grey[50]),
      ),
    );
  }
}

class Activities extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.goNamed(RouteNames.activities.name);
        },
        child: WidgetsContainer(
          padding: EdgeInsets.zero,
          backgroundColor: theme.primary[700],
          borderSide: BorderSide(color: theme.backgroundColor),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate("activities-home-headings"),
                            style: TextStyles.h6
                                .copyWith(color: theme.grey[50], fontSize: 14),
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate(
                                "exercises-description-home-description"),
                            style: TextStyles.small
                                .copyWith(height: 1.25, color: theme.grey[50]),
                            softWrap: true,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    horizontalSpace(Spacing.points72),
                    Icon(LucideIcons.arrowLeft, color: theme.grey[50]),
                  ],
                ),
              ),
              Positioned(
                left: 40,
                bottom: -20,
                child: Transform.rotate(
                  angle: 15 * 3.141592653589793 / 180,
                  child: Image.asset(
                    'asset/illustrations/app-icon.png',
                    height: 75,
                    width: 75,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
