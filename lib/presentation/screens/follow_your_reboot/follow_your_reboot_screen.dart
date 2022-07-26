import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/user_bloc.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/auth/new_user_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_up_streaks/follow_up_streak.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_widgets.dart';
import 'package:reboot_app_3/shared/Components/snackbar.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:provider/provider.dart';
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
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);

    return Scaffold(
        appBar: appBarWithSettings(context, "follow-your-reboot"),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomBlocProvider(
                          child: NotesScreen(), bloc: FollowYourRebootBloc()),
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
                        AppLocalizations.of(context).translate('dairies'),
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
              CustomBlocProvider(
                  bloc: FollowYourRebootBloc(), child: FollowUpStreaks()),
              RebootCalender(),
              Padding(
                padding: EdgeInsets.only(right: 16, left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).translate('streaks'),
                        style:
                            kSubTitlesStyle.copyWith(color: theme.hintColor)),
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
                              AppLocalizations.of(context)
                                  .translate("total-days"),
                              style: kHeadlineStyle.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: theme.primaryColor),
                            ),
                            FutureBuilder(
                              future: bloc.getTotalDaysFromBegining(),
                              initialData: "0",
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> sh) {
                                return Text(
                                  sh.data,
                                  style: kHeadlineStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
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
                              AppLocalizations.of(context)
                                  .translate("relapses-number"),
                              style: kHeadlineStyle.copyWith(
                                  fontWeight: FontWeight.w400, fontSize: 18),
                            ),
                            FutureBuilder(
                              future: bloc.getRelapsesCount(),
                              initialData: "0",
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> sh) {
                                return Text(
                                  sh.requireData,
                                  style: kHeadlineStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class GeneralStats extends StatelessWidget {
  const GeneralStats({
    Key key,
    @required this.lang,
  }) : super(key: key);

  final String lang;

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    return Container(
      child: Row(
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
                      alignment:
                          lang == 'ar' ? Alignment.topRight : Alignment.topLeft,
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
                  future: bloc.getHighestStreak(),
                  initialData: "0",
                  builder: (BuildContext context, AsyncSnapshot<String> sh) {
                    if (sh.hasData) {
                      return Text(
                        sh.data,
                        style: kPageTitleStyle.copyWith(color: Colors.green),
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
                  future: bloc.getTotalDaysWithoutRelapse(),
                  initialData: "0",
                  builder: (BuildContext context, AsyncSnapshot<String> sh) {
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
    );
  }
}

class FollowYourRebootScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User firebaseUser = context.watch<User>();

    if (firebaseUser != null) {
      return CustomBlocProvider(
        bloc: UserBloc(),
        child: UserDocWrapper(),
      );
    }
    return LoginScreen();
  }
}

class UserDocWrapper extends StatelessWidget {
  const UserDocWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<UserBloc>(context);
    return StreamBuilder(
        stream: bloc.UserDoc(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          switch (snapshot.connectionState) {
            // Uncompleted State
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());

            default:
              // Completed with error
              var data = snapshot.data.data();

              if (data == null) {
                return CustomBlocProvider(
                  bloc: AccountBloc(),
                  child: NewUserSection(),
                );
              }
              return CustomBlocProvider(
                bloc: FollowYourRebootBloc(),
                child: FollowYourRebootScreen(),
              );
          }
        });
  }
}
