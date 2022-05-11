import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
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
    return Scaffold(
        backgroundColor: seconderyColor.withOpacity(0.2),
        body: Padding(
          padding: EdgeInsets.only(top: 100.0, left: 16.0, right: 16),
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
                  height: 24,
                ),
                UserProfileCard(),
                SizedBox(
                  height: 32,
                ),
                Text(AppLocalizations.of(context).translate('app-settings'),
                    style: kSubTitlesStyle),
                SizedBox(
                  height: 16,
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          NotificationService.scheduleDailyNotification(
                              context);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.0, top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 12, right: 12),
                                    child: Icon(
                                      Iconsax.message_notif,
                                      size: 24,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('daily-notification-time'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17, height: 1.25)),
                                ],
                              ),
                              Icon(
                                lang == "en" ? CupertinoIcons.chevron_forward : CupertinoIcons.chevron_back,
                                size: 24,
                                color: Colors.grey,
                              ),
                            ],
                          ),
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
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.0, top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 12, right: 12),
                                    child: Icon(
                                      Iconsax.global,
                                      size: 26,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Text(
                                      AppLocalizations.of(context)
                                          .translate('change-lang'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17, height: 1.25)),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Text(AppLocalizations.of(context).translate('account-settings'),
                    style: kSubTitlesStyle),
                SizedBox(
                  height: 16,
                ),
                Column(
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
                      padding: EdgeInsets.only(top: 8.0, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          context
                              .read<GoogleAuthenticationService>()
                              .signOut();
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
                            ),

                          ],
                        ),
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 4),
                      child: GestureDetector(
                        onTap: () {
                          DeleteAccountSheet.openDeleteAccountMessage(
                              context);
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
