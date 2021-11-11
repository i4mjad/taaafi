import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Auth/AuthenticationService.dart';
import 'package:reboot_app_3/Screens/Auth/LoginPage.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reboot_app_3/main.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
//import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    key,
  }) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore database = FirebaseFirestore.instance;
  User user = FirebaseAuth.instance.currentUser;

  String dailyNotification = "";
  String lastResetedDate = "";

  void _changeLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String languageCode = await prefs.getString("languageCode");

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width / 3,
                      color: Colors.black12,
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Choose a Language",
                      style: kPageTitleStyle.copyWith(fontSize: 22),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "اختر اللغة المناسبة لك",
                      style: kPageTitleStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Arabic
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'ar');
                        final arLocale =
                            Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(this.context, arLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "العربية",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    //English
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'en');
                        final enLocale =
                            Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(this.context, enLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "ِEnglish",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }

  void deleteUserData() async {
    // set up the button
    Widget yesButton = TextButton(
      child: Text(
        AppLocalizations.of(context)
            .translate('delete-user-dialog-confirm-button'),
        style: kSubTitlesStyle.copyWith(
            color: Colors.deepOrangeAccent, fontSize: 18),
      ),
      onPressed: () {
        database.collection("users").doc(user.uid).update({
          "resetedDate": DateTime.now(),
          "userPreviousStreak": 0,
          "email": user.email
        });

        Navigator.pop(context);
      },
    );

    Widget noButton = TextButton(
      child: Text(
        AppLocalizations.of(context)
            .translate('delete-user-dialog-back-button'),
        style: kSubTitlesStyle.copyWith(color: Colors.grey, fontSize: 18),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('delete-user-dialog-title'),
        style: kSubTitlesStyle.copyWith(color: primaryColor, fontSize: 20),
      ),
      content: Text(
          AppLocalizations.of(context).translate('delete-user-dialog-content'),
          style: kSubTitlesStyle.copyWith(color: Colors.black, fontSize: 20)),
      actions: [
        yesButton,
        noButton,
      ],
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void scheduleDailyNotification() async {
    flutterLocalNotificationsPlugin.cancelAll();
    tz.initializeTimeZones();

    var scheduledNotificationDateTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    final Time newTime = Time(scheduledNotificationDateTime.hour,
        scheduledNotificationDateTime.minute);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_notif', 'alarm_notif', 'Channel for Alarm notification',
        icon: 'app_icon', playSound: true);

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        sound: 'a_long_cold_sting.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true);

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    // ignore: deprecated_member_use
    await flutterLocalNotificationsPlugin.showDailyAtTime(0, "المتابعة اليومية",
        "لا تنس المتابعة اليومية", newTime, platformChannelSpecifics);
  }

  DateTime parseTime(dynamic date) {
    return Platform.isIOS ? (date as Timestamp).toDate() : (date as DateTime);
  }

  void loadUserData() async {
    final userData = database.collection('users').doc('${user.uid}');

    userData.snapshots().listen((snapshot) async {
      if (snapshot.data().containsValue("resetedDate")) {
        final getDate = snapshot.get("resetedDate");
        final date = parseTime(getDate);
        final dateStr = date.toString().substring(0, 10);

        setState(() {
          this.lastResetedDate = dateStr;
        });
      }
    });
  }

  void showDeleteSheet() async {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50)),
                      child: Center(
                        child: Icon(
                          Iconsax.refresh_circle,
                          color: primaryColor,
                        ),
                      ),
                    )
                  ],
                ),
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Text(
                        AppLocalizations.of(context)
                            .translate('delete-my-data'),
                        style: kPageTitleStyle.copyWith(
                            fontSize: 24, color: primaryColor),
                      ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('delete-my-data-p'),
                          textAlign: TextAlign.center,
                          style: kSubTitlesSubsStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Text(
                        AppLocalizations.of(context)
                            .translate('delete-my-data-warning'),
                        style: kSubTitlesStyle.copyWith(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Beginning from last relapse
                    GestureDetector(
                      onTap: () async {
                        //start from last relapse
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('start-from-specific-date'),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    //New Beginning
                    GestureDetector(
                      onTap: () async {
                        //New start
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('new-begining'),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: seconderyColor,
        body: Padding(
          padding: EdgeInsets.only(top: 100.0, left: 20.0, right: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('account'),
                      style: kPageTitleStyle.copyWith(height: 1),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                    width: MediaQuery.of(context).size.width - 40,
                    height: MediaQuery.of(context).size.height * 0.175,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12)),
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.personalcard,
                            size: 75,
                            color: primaryColor,
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                this.user.displayName != null
                                    ? this.user.displayName
                                    : "",
                                style: kPageTitleStyle.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                              SizedBox(
                                height: 2,
                              ),
                              Text(
                                  this.user.email != null
                                      ? this.user.email
                                      : "",
                                  style: kSubTitlesSubsStyle.copyWith(
                                      color: Colors.grey)),
                              SizedBox(
                                height: 2,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('registered-since'),
                                    style: kSubTitlesSubsStyle.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey[500]),
                                  ),
                                  Text(
                                    this.user.metadata.creationTime != null
                                        ? this
                                            .user
                                            .metadata
                                            .creationTime
                                            .toString()
                                            .substring(0, 10)
                                        : '',
                                    style: kSubTitlesSubsStyle.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                SizedBox(
                  height: 12,
                ),
                Text(AppLocalizations.of(context).translate('app-settings'),
                    style: kSubTitlesStyle),
                SizedBox(
                  height: 12,
                ),
                Container(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          width: 0.25, color: primaryColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12.5)),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            scheduleDailyNotification();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Iconsax.notification_bing,
                                  size: 26,
                                  color: primaryColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('daily-notification-time'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17, height: 1.25)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 4),
                        child: GestureDetector(
                          onTap: () {
                            _changeLanguage();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Iconsax.global,
                                  size: 26,
                                  color: Colors.purple,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('change-lang'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17, height: 1.25)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Text(AppLocalizations.of(context).translate('account-settings'),
                    style: kSubTitlesStyle),
                SizedBox(
                  height: 8,
                ),
                Container(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          width: 0.25, color: primaryColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12.5)),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            showDeleteSheet();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Iconsax.refresh_circle,
                                  size: 26,
                                  color: primaryColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('delete-my-data'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 4),
                        child: GestureDetector(
                          onTap: () {
                            context.read<AuthenticationService>().signOut();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Iconsax.user_remove,
                                  size: 28,
                                  color: Colors.grey,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('log-out'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        width: 1, color: Colors.red.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(12.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 12, right: 12),
                        child: Icon(
                          Iconsax.trash,
                          size: 26,
                          color: Colors.red,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                              AppLocalizations.of(context)
                                  .translate('delete-my-account'),
                              style: kSubTitlesStyle.copyWith(
                                  color: Colors.red, fontSize: 17)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void saveSelectedLocale(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);

    String _languageCode = await prefs.getString("languageCode");
    print(_languageCode);
  }
}

class AccountScreenScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return user == null ? LoginScreen() : AccountScreen();
  }
}
