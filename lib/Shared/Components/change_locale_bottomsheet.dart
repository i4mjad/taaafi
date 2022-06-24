import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/main.dart';
import 'package:reboot_app_3/shared/components/app-themes.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguageWidget {
  static void changeLanguage(BuildContext context) async {
    final theme = Theme.of(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width / 5,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('app-settings'),
                        style: kHeaderStyle.copyWith(color: theme.primaryColor),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "الوضع الليلي",
                        style:
                            kSubTitlesStyle.copyWith(color: theme.primaryColor),
                      ),
                      Divider(
                        color: theme.primaryColor,
                      ),
                      Container(
                        child: GestureDetector(
                          onTap: () async {
                            currentTheme.toggleTheme();
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Icon(
                                  Icons.nightlight_round_rounded,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("تفعيل",
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17,
                                          color: theme.primaryColor)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: theme.primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate("change-lang"),
                        style: kPageTitleStyle.copyWith(
                          fontSize: 22,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: GestureDetector(
                          onTap: () async {
                            //TODO - fix thrown error
                            HapticFeedback.lightImpact();
                            await prefs.setString('languageCode', 'ar');
                            final arLocale =
                                Locale(prefs.getString("languageCode"), '');
                            MyApp.setLocale(context, arLocale);
                            getSnackBar(context, "changed-to-ar");

                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Text(
                                  "ع",
                                  style: kSubTitlesStyle.copyWith(
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("العربية",
                                      style: kSubTitlesStyle.copyWith(
                                        fontSize: 17,
                                        color: theme.primaryColor,
                                      )),
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
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();

                            await prefs.setString('languageCode', 'en');
                            final enLocale =
                                Locale(prefs.getString("languageCode"), '');
                            await MyApp.setLocale(context, enLocale);
                            getSnackBar(context, "changed-to-en");

                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Text(
                                  "E",
                                  style: kSubTitlesStyle.copyWith(
                                      color: theme.primaryColor),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("English",
                                      style: kSubTitlesStyle.copyWith(
                                        fontSize: 17,
                                        color: theme.primaryColor,
                                      )),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        color: theme.primaryColor,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          );
        });
  }
}
