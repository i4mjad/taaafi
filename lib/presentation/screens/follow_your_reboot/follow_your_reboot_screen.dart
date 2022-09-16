import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_up_streaks/follow_up_streak.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_widgets.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'notes/notes_screen.dart';

class FollowYourRebootScreen extends StatefulWidget {
  const FollowYourRebootScreen({
    key,
  }) : super(key: key);

  @override
  FollowYourRebootScreenState createState() => FollowYourRebootScreenState();
}

class FollowYourRebootScreenState extends State<FollowYourRebootScreen>
    with TickerProviderStateMixin {
  String lang;

  @override
  void initState() {
    super.initState();

    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);

    return Scaffold(
        appBar: appBarWithSettings(context, "follow-your-reboot"),
        body: StreamBuilder(
          stream: bloc.streamUserDoc(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              // Uncompleted State
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
                break;
              default:
                // Completed with error
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    child: Center(
                      child: Text(
                        snapshot.error.toString(),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomBlocProvider(
                                  child: NotesScreen(),
                                  bloc: FollowYourRebootBloc()),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 60,
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.only(right: 16, left: 16),
                          decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12.5)),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.archive_1,
                                size: 32,
                                color: theme.primaryColor,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                AppLocalizations.of(context)
                                    .translate('dairies'),
                                style: kSubTitlesStyle.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      FollowUpStreaks(),
                      RebootCalender(),
                      SizedBox(height: 16),
                      RelapsesByDayOfWeek(),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(right: 16, left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                AppLocalizations.of(context)
                                    .translate('streaks'),
                                style: kSubTitlesStyle.copyWith(
                                    color: theme.hintColor)),
                            SizedBox(
                              height: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GeneralStats(lang: lang),
                              ],
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            SizedBox(
                              height: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
            }
          },
        ));
  }
}
