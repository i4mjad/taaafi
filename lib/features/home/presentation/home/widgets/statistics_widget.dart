import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate("statistics"),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points8),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(20),
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                    boxShadow: Shadows.mainShadows,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: theme.primary[900]!,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.heart,
                            color: theme.primary[900],
                            size: 20,
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        Text(
                            "28" +
                                " " +
                                AppLocalizations.of(context).translate("day"),
                            style: TextStyles.h6),
                        verticalSpace(Spacing.points8),
                        Text(
                          AppLocalizations.of(context)
                              .translate("current-streak"),
                          style: TextStyles.small,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                horizontalSpace(Spacing.points8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      WidgetsContainer(
                        padding: EdgeInsets.all(12),
                        backgroundColor: theme.backgroundColor,
                        borderSide:
                            BorderSide(color: theme.grey[600]!, width: 0.5),
                        boxShadow: Shadows.mainShadows,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: theme.primary[900]!, width: 1),
                              ),
                              child: Icon(
                                LucideIcons.lineChart,
                                color: theme.primary[900],
                                size: 20,
                              ),
                            ),
                            horizontalSpace(Spacing.points8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                    "28" +
                                        " " +
                                        AppLocalizations.of(context)
                                            .translate("day"),
                                    style: TextStyles.h6),
                                verticalSpace(Spacing.points8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("highest-streak"),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.small,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      WidgetsContainer(
                        padding: EdgeInsets.all(12),
                        backgroundColor: theme.backgroundColor,
                        borderSide:
                            BorderSide(color: theme.grey[600]!, width: 0.5),
                        boxShadow: Shadows.mainShadows,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                    color: theme.primary[900]!, width: 1),
                              ),
                              child: Icon(
                                LucideIcons.calendar,
                                color: theme.primary[900],
                                size: 20,
                              ),
                            ),
                            horizontalSpace(Spacing.points8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                    "28" +
                                        " " +
                                        AppLocalizations.of(context)
                                            .translate("day"),
                                    style: TextStyles.h6),
                                verticalSpace(Spacing.points8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate("free-days-from-start"),
                                  style: TextStyles.small,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
