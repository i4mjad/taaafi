import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class ActivityOverviewScreen extends ConsumerWidget {
  const ActivityOverviewScreen(this.activityId, {super.key});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, activityId, false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  WidgetsContainer(
                    backgroundColor: theme.primary[50],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    width: width,
                    child: Text(
                      'هذا توصيف للقائمة والفكرة منها وطبيعة المحتوى الموجود في هذه القائمة. مثال: قائمة كيف أبدأ تحتوي على بعض المصادر لمساعدة المتعافي للبدء في التعافي وكيف يدخل لهذا العالم. سيتم إضافة التوصيف عند إضافة القائمة.',
                      style: TextStyles.small.copyWith(
                        color: theme.grey[900],
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(LucideIcons.lineChart),
                          verticalSpace(Spacing.points4),
                          Text(
                            AppLocalizations.of(context).translate('easy'),
                            style: TextStyles.small,
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Icon(LucideIcons.users),
                          verticalSpace(Spacing.points4),
                          Text(
                            "2808 " +
                                AppLocalizations.of(context)
                                    .translate('subscriber'),
                            style: TextStyles.small,
                          )
                        ],
                      ),
                      Column(
                        //TODO: this will represent the best period to do this activity
                        children: [
                          Icon(LucideIcons.calendarRange),
                          verticalSpace(Spacing.points4),
                          Text(
                            "3 " +
                                AppLocalizations.of(context).translate('month'),
                            style: TextStyles.small,
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Icon(LucideIcons.panelLeftInactive),
                          verticalSpace(Spacing.points4),
                          Text(
                            AppLocalizations.of(context)
                                .translate('all-levels'),
                            style: TextStyles.small,
                          )
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
