import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/account/delete_account.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/widgets/new_user_widgets.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';
import 'package:reboot_app_3/shared/services/notification_service.dart';

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
    final bloc = CustomBlocProvider.of<AccountBloc>(context);
    final theme = Theme.of(context);
    return Scaffold(
        appBar: plainAppBar(context, "account"),
        body: Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16),
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileCard(),
                  SizedBox(
                    height: 32,
                  ),
                  Text(AppLocalizations.of(context).translate('app-settings'),
                      style:
                          kSubTitlesStyle.copyWith(color: theme.primaryColor)),
                  SizedBox(
                    height: 16,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.5)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              NotificationService.scheduleDailyNotification(
                                  context);
                            },
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
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                        AppLocalizations.of(context).translate(
                                            'daily-notification-time'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17,
                                            height: 1.25,
                                            color: theme.hintColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
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
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                        AppLocalizations.of(context)
                                            .translate('change-lang'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17,
                                            height: 1.25,
                                            color: theme.hintColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              resetUserDialog(context, bloc);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 12, right: 12),
                                  child: Icon(
                                    Iconsax.refresh_circle,
                                    size: 26,
                                    color: theme.primaryColor,
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
                                            fontSize: 17,
                                            color: theme.hintColor)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
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
                                    color: theme.primaryColor,
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
                                            fontSize: 17,
                                            color: theme.hintColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              DeleteAccountSheet.openDeleteAccountMessage(
                                  context, bloc);
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
          ),
        ));
  }

  resetUserDialog(BuildContext context, AccountBloc bloc) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(30.0), topLeft: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter bsState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: lightPrimaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Iconsax.calendar_tick,
                    color: lightPrimaryColor,
                    size: 32,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)
                      .translate('delete-user-dialog-title'),
                  style: kHeadlineStyle.copyWith(
                      fontWeight: FontWeight.bold, color: lightPrimaryColor),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)
                      .translate("delete-user-dialog-content"),
                  style: kBodyStyle.copyWith(height: 1.2),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        var selectedDate = await getDateTime(context);
                        await bloc
                            .createNewData(selectedDate)
                            .then((value) => Navigator.pop(context));
                      },
                      child: Container(
                        height: 80,
                        width:
                            ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate("specific-day"),
                            style: kTitleSeconderyStyle,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        var today = getToday();
                        await bloc
                            .createNewData(today)
                            .then((value) => Navigator.pop(context));
                      },
                      child: Container(
                        height: 80,
                        width:
                            ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12.5)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).translate("today"),
                            style: kTitleSeconderyStyle.copyWith(
                                color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }
}

class UserProfileCard extends StatelessWidget {
  UserProfileCard({Key key, String lang}) : super(key: key);

  final User user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(500),
              ),
              child: Icon(
                Iconsax.user,
                size: 56,
                color: theme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  user.displayName ?? "",
                  style: kTitlePrimeryStyle.copyWith(
                      color: theme.hintColor, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  user.email.toUpperCase() ?? "",
                    style: kCaptionStyle.copyWith(
                        color: theme.hintColor.withOpacity(0.75),
                    ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class AccountScreenScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User>();
    return user == null
        ? LoginScreen()
        : CustomBlocProvider(bloc: AccountBloc(), child: AccountScreen());
  }
}
