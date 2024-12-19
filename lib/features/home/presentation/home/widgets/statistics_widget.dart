import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class StatisticsWidget extends StatefulWidget {
  const StatisticsWidget({
    super.key,
  });

  @override
  _StatisticsWidgetState createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  // final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width - 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate("statistics"),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? theme.primary[700]
                          : theme.grey[400],
                    ),
                  );
                }),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          _buildFirstPage(context, theme),
          // ConstrainedBox(
          //   constraints: BoxConstraints(
          //     maxHeight: MediaQuery.of(context).size.height * 0.17125,
          //   ),
          //   child: PageView(
          //     clipBehavior: Clip.none,
          //     controller: _pageController,
          //     onPageChanged: (int page) {
          //       setState(() {
          //         _currentPage = page;
          //       });
          //     },
          //     children: [
          //       _buildFirstPage(context, theme),
          //       _buildSecondPage(context, theme),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildFirstPage(BuildContext context, CustomThemeData theme) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WidgetsContainer(
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
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.heart,
                    size: 20,
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text("28" + " " + AppLocalizations.of(context).translate("day"),
                    style: TextStyles.h6),
                verticalSpace(Spacing.points8),
                Text(
                  AppLocalizations.of(context).translate("current-streak"),
                  style: TextStyles.small,
                  textAlign: TextAlign.center,
                ),
              ],
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
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  boxShadow: Shadows.mainShadows,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(width: 1),
                        ),
                        child: Icon(
                          LucideIcons.lineChart,
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
                                  AppLocalizations.of(context).translate("day"),
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
                  borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                  boxShadow: Shadows.mainShadows,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(width: 1),
                        ),
                        child: Icon(
                          LucideIcons.calendar,
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
                                  AppLocalizations.of(context).translate("day"),
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
    );
  }

  Widget _buildSecondPage(BuildContext context, CustomThemeData theme) {
    // Add your second page widget here
    return Center(
      child: Text(
        "Second Page",
        style: TextStyles.h6.copyWith(color: theme.grey[900]),
      ),
    );
  }
}
