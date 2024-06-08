import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class RelapsesByDayOfWeek extends ConsumerWidget {
  RelapsesByDayOfWeek({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final followUpData = ref.watch(followupViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('relapses-by-day-of-week'),
          style: kSubTitlesStyle.copyWith(color: theme.hintColor),
        ),
        SizedBox(
          height: 8,
        ),
        Container(
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width - 40,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: FutureBuilder(
            future: followUpData.getRelapsesByDayOfWeek(),
            initialData: new DayOfWeekRelapses(
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                new DayOfWeekRelapsesDetails(0, 0),
                "0"),
            builder: (context, AsyncSnapshot<DayOfWeekRelapses> snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('relapses-number'),
                        style: kSubTitlesStyle.copyWith(
                          color: theme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        snapshot.data?.totalRelapses ?? "0",
                        style: kSubTitlesStyle.copyWith(
                          color: theme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  DayOfWeekWidget(
                    day: "sun",
                    percentage: snapshot.data?.sunRelapses.relapsesPercentage,
                    count: snapshot.data?.sunRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "mon",
                    percentage: snapshot.data?.monRelapses.relapsesPercentage,
                    count: snapshot.data?.monRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "tue",
                    percentage: snapshot.data?.tueRelapses.relapsesPercentage,
                    count: snapshot.data?.tueRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "wed",
                    percentage: snapshot.data?.wedRelapses.relapsesPercentage,
                    count: snapshot.data?.wedRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "thu",
                    percentage: snapshot.data?.thuRelapses.relapsesPercentage,
                    count: snapshot.data?.thuRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "fri",
                    percentage: snapshot.data?.friRelapses.relapsesPercentage,
                    count: snapshot.data?.friRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "sat",
                    percentage: snapshot.data?.satRelapses.relapsesPercentage,
                    count: snapshot.data?.satRelapses.relapsesCount,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class DayOfWeekWidget extends StatelessWidget {
  DayOfWeekWidget({Key? key, this.day, this.percentage, this.count})
      : super(key: key);

  final percentage;
  final count;
  final day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width - 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              AppLocalizations.of(context).translate(day),
              style: kSubTitlesStyle.copyWith(
                color: theme.primaryColor,
                fontSize: 10,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(right: 4, left: 4),
            width: MediaQuery.of(context).size.width - 150,
            child: Builder(builder: (BuildContext context) {
              if (percentage.isNaN || percentage.isInfinite) {
                return Container();
              } else {
                return LinearProgressIndicator(
                  backgroundColor: Colors.grey[400],
                  value: percentage,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                );
              }
            }),
          ),
          CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              "${count}",
              style: kSubTitlesStyle.copyWith(
                  color: theme.hintColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
