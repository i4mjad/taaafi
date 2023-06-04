import 'package:reboot_app_3/presentation/screens/follow_your_reboot/widgets/general_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/day_of_week_relapses/day_of_week_relapses_widget.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/viewmodels/followup_viewmodel.dart';


class RelapsesByDayOfWeek extends ConsumerWidget {
  RelapsesByDayOfWeek({Key key}) : super(key: key);

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
                        snapshot.data.totalRelapses,
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
                    percentage: snapshot.data.sunRelapses.relapsesPercentage,
                    count: snapshot.data.sunRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "mon",
                    percentage: snapshot.data.monRelapses.relapsesPercentage,
                    count: snapshot.data.monRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "tue",
                    percentage: snapshot.data.tueRelapses.relapsesPercentage,
                    count: snapshot.data.tueRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "wed",
                    percentage: snapshot.data.wedRelapses.relapsesPercentage,
                    count: snapshot.data.wedRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "thu",
                    percentage: snapshot.data.thuRelapses.relapsesPercentage,
                    count: snapshot.data.thuRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "fri",
                    percentage: snapshot.data.friRelapses.relapsesPercentage,
                    count: snapshot.data.friRelapses.relapsesCount,
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  DayOfWeekWidget(
                    day: "sat",
                    percentage: snapshot.data.satRelapses.relapsesPercentage,
                    count: snapshot.data.satRelapses.relapsesCount,
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
  DayOfWeekWidget({Key key, this.day, this.percentage, this.count})
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

String getTodaysDateString() {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String today = formatter.format(now);
  return today;
}

changeDateEvent(String date, BuildContext context,
    FollowUpViewModel followUpViewModel) async {
  final trimedDate = date.trim();
  final theme = Theme.of(context);
  showModalBottomSheet(
      backgroundColor: theme.scaffoldBackgroundColor,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(50)),
                  )
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trimedDate,
                    style: kPageTitleStyle.copyWith(
                        fontSize: 26, color: theme.primaryColor),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addSuccess(date);
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      getSnackBar(context, "free-day-recorded");
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😍",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addRelapse(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "relapse-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😒",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addWatchOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "pornonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😥",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addMastOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "mastonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😪",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 18,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.primaryColor, width: 0.25),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate("cancel"),
                      style: kSubTitlesStyle.copyWith(
                        color: theme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      });
}

dateChecker(DateTime firstDate, DateTime date, BuildContext context,
    FollowUpViewModel followUpViewModel) {
  if (dayWithinRange(firstDate, date)) {
    final dateStr = date.toString().substring(0, 10);
    changeDateEvent(dateStr, context, followUpViewModel);
  } else {
    outOfRangeAlert(context);
  }
}

outOfRangeAlert(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 12,
              ),
              CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.2),
                child: Icon(
                  Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                AppLocalizations.of(context).translate("out-of-range"),
                style:
                    kPageTitleStyle.copyWith(color: Colors.red, fontSize: 24),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                AppLocalizations.of(context).translate('out-of-range-p'),
                style: kSubTitlesStyle.copyWith(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        );
      });
}

bool dayWithinRange(DateTime firstDate, DateTime date) {
  final today = DateTime.now();
  return date.isAfter(firstDate) && date.isBefore(today);
}
