import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  List<Widget> children = [
    WidgetsContainer(
      child: Text("data"),
    ),
    WidgetsContainer(
      child: Text("data"),
    ),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, true),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StatisticsWidget(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.primary[600],
          onPressed: () {
            // TODO: open the followup modal
          },
          label: Text(
            AppLocalizations.of(context).translate("daily-follow-up"),
            style: TextStyles.caption.copyWith(color: theme.grey[50]),
          ),
          icon: Icon(LucideIcons.pencil, color: theme.grey[50])),
    );
  }
}

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate("statistics"),
            style: TextStyles.h6.copyWith(color: theme.grey[900]),
          ),
          verticalSpace(Spacing.points8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetsContainer(
                padding: EdgeInsets.all(24),
                backgroundColor: theme.primary[50],
                borderSide: BorderSide(color: theme.primary[100]!),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border:
                            Border.all(color: theme.primary[200]!, width: 1),
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        color: theme.primary[600],
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
                      AppLocalizations.of(context).translate("current-streak"),
                      style: TextStyles.small,
                    ),
                  ],
                ),
              ),
              horizontalSpace(Spacing.points8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  WidgetsContainer(
                    padding: EdgeInsets.all(12),
                    backgroundColor: theme.primary[50],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.tint[50],
                            borderRadius: BorderRadius.circular(50),
                            border:
                                Border.all(color: theme.tint[200]!, width: 1),
                          ),
                          child: Icon(
                            LucideIcons.lineChart,
                            color: theme.tint[600],
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
                              style: TextStyles.small,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  WidgetsContainer(
                    padding: EdgeInsets.all(12),
                    backgroundColor: theme.primary[50],
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: theme.success[200]!, width: 1),
                          ),
                          child: Icon(
                            LucideIcons.calendar,
                            color: theme.success[600],
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
              )
            ],
          ),
        ],
      ),
    );
  }
}
