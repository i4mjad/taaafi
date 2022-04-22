import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Shared/Components/ChangeLocaleBottomSheet.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';
import 'package:reboot_app_3/shared/services/notification_service.dart';


import 'Widgets/delete_account_bottomsheet.dart';
import 'Widgets/reset_account_bottomsheet.dart';
import 'Widgets/user_profile_card.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    key,
  }) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
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
                UserProfileCard(),
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
                            NotificationService.scheduleDailyNotification(context);
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
                            ChangeLanguageWidget.changeLanguage(context);
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
                            //TODO reset account data
                            ResetAccountSheet.showResetSheet(context);
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
                            context.read<GoogleAuthenticationService>().signOut();
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
                      Divider(),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 4),
                        child: GestureDetector(
                          onTap: () {
                            DeleteAccountSheet.openDeleteAccountMessage(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Iconsax.trash,
                                  size: 28,
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
                                          fontSize: 17, color: Colors.red)),
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
              ],
            ),
          ),
        ));
  }

}


class AccountScreenScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return user == null ? LoginScreen() : AccountScreen();
  }
}
