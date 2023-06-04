import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class GeneralStatusWidget extends ConsumerWidget {
  const GeneralStatusWidget({
    Key key,
    @required this.lang,

  }) : super(key: key);

  final String lang;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpData = ref.watch(followupViewModelProvider.notifier);
    final theme = Theme.of(context);
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                width: (MediaQuery.of(context).size.width - 40) / 2 - 6,
                height: MediaQuery.of(context).size.height * 0.21,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: lang == 'ar'
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          child: CircleAvatar(
                            minRadius: 18,
                            maxRadius: 20,
                            backgroundColor: Colors.green.withOpacity(0.3),
                            child: Icon(
                              Iconsax.medal,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.0, top: 3, left: 8),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('highest-streak'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 16, color: Colors.green, height: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    FutureBuilder(
                      future: followUpData.getHighestStreak(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        if (sh.hasData) {
                          return Text(
                            sh.data,
                            style:
                                kPageTitleStyle.copyWith(color: Colors.green),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                width: (MediaQuery.of(context).size.width - 40) / 2 - 6,
                height: MediaQuery.of(context).size.height * 0.21,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            minRadius: 18,
                            maxRadius: 20,
                            backgroundColor: Colors.blue.withOpacity(0.3),
                            child: Icon(
                              Iconsax.ranking,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 8.0, top: 3, left: 8),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('relapses-count'),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 14, color: Colors.blue, height: 1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    FutureBuilder(
                      future: followUpData.getTotalDaysWithoutRelapse(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        return Text(
                          sh.data,
                          style: kPageTitleStyle.copyWith(color: Colors.blue),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Column(
            children: [
              //dublicate this
              Row(
                children: [
                  Icon(Iconsax.calendar_tick),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("total-days"),
                    style: kHeadlineStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                        color: theme.primaryColor),
                  ),
                  FutureBuilder(
                    future: followUpData.getTotalDaysFromBegining(),
                    initialData: "0",
                    builder: (BuildContext context, AsyncSnapshot<String> sh) {
                      return Text(
                        sh.data,
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Icon(Iconsax.emoji_sad),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    AppLocalizations.of(context).translate("relapses-number"),
                    style: kHeadlineStyle.copyWith(
                        fontWeight: FontWeight.w400, fontSize: 18),
                  ),
                  FutureBuilder(
                    future: followUpData.getRelapsesCount(),
                    initialData: "0",
                    builder: (BuildContext context, AsyncSnapshot<String> sh) {
                      return Text(
                        sh.requireData,
                        style: kHeadlineStyle.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

